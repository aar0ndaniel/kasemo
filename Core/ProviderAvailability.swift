import Foundation

public enum AIProvider: String, Codable, Sendable { case openAI, gemini }
public enum ProviderCapability: String, Codable, Hashable, Sendable { case text, voice }

public enum AvailabilityStatus: Codable, Equatable, Sendable {
    case available
    case temporaryRateLimit(retryAt: Date)
    case quotaExhausted          // insufficient_quota (credits depleted / hard limit)
    case billingBlocked          // payment instrument failure
    case serviceUnavailable(retryAt: Date?)
    case networkUnavailable
}

public struct ProviderObservation: Codable, Equatable, Sendable {
    public var observedAt: Date
    public var httpStatus: Int?
    public var remainingRequests: Int?
    public var remainingTokens: Int?
    public var requestsResetAt: Date?
    public var tokensResetAt: Date?
    public var status: AvailabilityStatus

    public init(headers: [String: String], now: Date = .now, httpStatus: Int? = nil, errorCode: String? = nil) {
        let headers = Dictionary(headers.map { ($0.key.lowercased(), $0.value) }, uniquingKeysWith: { _, last in last })
        observedAt = now
        self.httpStatus = httpStatus
        remainingRequests = headers["x-ratelimit-remaining-requests"].flatMap(Int.init).flatMap { $0 >= 0 ? $0 : nil }
        remainingTokens = headers["x-ratelimit-remaining-tokens"].flatMap(Int.init).flatMap { $0 >= 0 ? $0 : nil }
        requestsResetAt = headers["x-ratelimit-reset-requests"].flatMap(Self.duration).map { now.addingTimeInterval($0) }
        tokensResetAt = headers["x-ratelimit-reset-tokens"].flatMap(Self.duration).map { now.addingTimeInterval($0) }

        if errorCode == "insufficient_quota" {
            status = .quotaExhausted
        } else if errorCode == "billing_hard_limit_reached" || errorCode == "account_deactivated" {
            status = .billingBlocked
        } else if httpStatus == 429 {
            let retry = headers["retry-after"].flatMap({ Self.retryDate($0, now: now) })
                ?? requestsResetAt ?? tokensResetAt ?? now.addingTimeInterval(60)
            status = .temporaryRateLimit(retryAt: retry)
        } else if let code = httpStatus, (500...599).contains(code) {
            let retry = headers["retry-after"].flatMap({ Self.retryDate($0, now: now) })
            status = .serviceUnavailable(retryAt: retry)
        } else {
            status = .available
        }
    }

    public init(realtimeRateLimits: [[String: Any]], now: Date = .now) {
        observedAt = now
        httpStatus = 200
        var remReq: Int?
        var remTok: Int?
        var resetReq: Date?
        var resetTok: Date?
        for item in realtimeRateLimits {
            guard let name = item["name"] as? String else { continue }
            let remaining = item["remaining"] as? Int
            let resetSeconds = (item["reset_seconds"] as? Double) ?? (item["reset_seconds"] as? Int).map(Double.init)
            if name == "requests" {
                remReq = remaining
                if let resetSeconds, resetSeconds.isFinite, resetSeconds >= 0 {
                    resetReq = now.addingTimeInterval(resetSeconds)
                }
            } else if name == "tokens" || name == "output_tokens" {
                remTok = remaining
                if let resetSeconds, resetSeconds.isFinite, resetSeconds >= 0 {
                    resetTok = now.addingTimeInterval(resetSeconds)
                }
            }
        }
        remainingRequests = remReq
        remainingTokens = remTok
        requestsResetAt = resetReq
        tokensResetAt = resetTok
        status = .available
    }

    public static func duration(_ value: String) -> TimeInterval? {
        if let seconds = Double(value), seconds.isFinite, seconds >= 0, seconds <= 604_800 { return seconds }
        guard let expression = try? NSRegularExpression(pattern: "([0-9]+(?:\\.[0-9]+)?)(ms|s|m|h|d)") else { return nil }
        let full = NSRange(value.startIndex..<value.endIndex, in: value)
        let matches = expression.matches(in: value, range: full)
        guard !matches.isEmpty, matches.map(\.range.length).reduce(0, +) == full.length else { return nil }
        var total: Double = 0
        for match in matches {
            guard let n = Range(match.range(at: 1), in: value), let u = Range(match.range(at: 2), in: value),
                  let number = Double(value[n]) else { return nil }
            total += number * (["ms": 0.001, "s": 1, "m": 60, "h": 3600, "d": 86400][String(value[u])] ?? 0)
        }
        return total.isFinite && total <= 604_800 ? total : nil
    }
    public static func retryDate(_ value: String?, now: Date = .now) -> Date? {
        guard let value else { return nil }
        if let seconds = duration(value) { return now.addingTimeInterval(seconds) }
        let formatter = DateFormatter(); formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0); formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        guard let date = formatter.date(from: value), date >= now, date.timeIntervalSince(now) <= 604_800 else { return nil }
        return date
    }
}

public struct ProviderAvailability: Codable, Equatable, Sendable {
    public private(set) var usingFallback = false
    public private(set) var status: AvailabilityStatus = .available
    public private(set) var retryAt: Date?
    public private(set) var failureAt: Date?
    public private(set) var failureGeneration = UUID()
    public private(set) var observation: ProviderObservation?

    public init() {}

    public mutating func observe(_ observation: ProviderObservation) {
        self.observation = observation
        if !usingFallback { self.status = observation.status }
    }

    public mutating func fail(status: AvailabilityStatus, now: Date = .now) {
        usingFallback = true
        failureAt = now
        failureGeneration = UUID()
        self.status = status
        switch status {
        case .temporaryRateLimit(let retry):
            self.retryAt = max(now.addingTimeInterval(30), retry)
        case .serviceUnavailable(let retry):
            self.retryAt = max(now.addingTimeInterval(30), retry ?? now.addingTimeInterval(60))
        case .quotaExhausted, .billingBlocked:
            self.retryAt = nil
        case .networkUnavailable:
            self.retryAt = now.addingTimeInterval(30)
        case .available:
            self.retryAt = now.addingTimeInterval(30)
        }
    }

    public mutating func fail(now: Date = .now, retryAt: Date? = nil) {
        if let retryAt {
            fail(status: .temporaryRateLimit(retryAt: retryAt), now: now)
        } else {
            fail(status: .serviceUnavailable(retryAt: nil), now: now)
        }
    }

    /// The cooldown permits a real capability-specific attempt; it never proves recovery.
    public func mayAttemptOpenAI(now: Date = .now) -> Bool {
        if !usingFallback { return true }
        switch status {
        case .quotaExhausted, .billingBlocked:
            return false
        case .temporaryRateLimit(let retry):
            return now >= retry
        case .serviceUnavailable(let retry):
            return retry.map { now >= $0 } ?? (now.timeIntervalSince(failureAt ?? now) >= 60)
        case .networkUnavailable:
            return now >= (failureAt?.addingTimeInterval(30) ?? now)
        case .available:
            return true
        }
    }

    public mutating func succeeded(generation: UUID) {
        guard generation == failureGeneration else { return }
        usingFallback = false
        status = .available
        retryAt = nil
        failureAt = nil
    }
}
