import XCTest
@testable import MuralCore

final class ProviderAvailabilityTests: XCTestCase {
    func testCooldownDoesNotClaimRecoveryAndStaleSuccessCannotOverrideFailure() {
        let now = Date(timeIntervalSince1970: 1000)
        var voice = ProviderAvailability(), text = ProviderAvailability()
        voice.fail(now: now, retryAt: now.addingTimeInterval(120))
        let old = voice.failureGeneration
        XCTAssertFalse(voice.mayAttemptOpenAI(now: now.addingTimeInterval(60)))
        XCTAssertTrue(voice.mayAttemptOpenAI(now: now.addingTimeInterval(121)))
        XCTAssertTrue(voice.usingFallback)
        text.succeeded(generation: text.failureGeneration)
        XCTAssertTrue(voice.usingFallback)
        voice.fail(now: now.addingTimeInterval(122))
        voice.succeeded(generation: old)
        XCTAssertTrue(voice.usingFallback)
        voice.succeeded(generation: voice.failureGeneration)
        XCTAssertFalse(voice.usingFallback)
    }
    func testHeaderParsingHasNoInventedQuotaAndSupportsCompoundDurations() throws {
        let now = Date(timeIntervalSince1970: 1000)
        let observation = ProviderObservation(headers: ["X-RateLimit-Remaining-Requests": "0", "x-ratelimit-reset-requests": "1m30s"], now: now)
        XCTAssertEqual(observation.remainingRequests, 0)
        XCTAssertNil(observation.remainingTokens)
        XCTAssertEqual(observation.requestsResetAt, now.addingTimeInterval(90))
        XCTAssertEqual(ProviderObservation.duration("250ms"), 0.25)
        XCTAssertNil(ProviderObservation.duration("forever"))
        XCTAssertNil(ProviderObservation.duration("-10"))
        XCTAssertNil(ProviderObservation.duration("1h garbage"))
        var state = ProviderAvailability(); state.observe(observation); state.fail(now: now)
        let restored = try JSONDecoder().decode(ProviderAvailability.self, from: JSONEncoder().encode(state))
        XCTAssertEqual(restored, state)
    }
    func testRealtimeRateLimitsEventIngestion() {
        let now = Date(timeIntervalSince1970: 2000)
        let realtimeLimits: [[String: Any]] = [
            ["name": "requests", "limit": 100, "remaining": 42, "reset_seconds": 15.5],
            ["name": "tokens", "limit": 20000, "remaining": 15000, "reset_seconds": 30.0]
        ]
        let observation = ProviderObservation(realtimeRateLimits: realtimeLimits, now: now)
        XCTAssertEqual(observation.remainingRequests, 42)
        XCTAssertEqual(observation.remainingTokens, 15000)
        XCTAssertEqual(observation.requestsResetAt, now.addingTimeInterval(15.5))
        XCTAssertEqual(observation.tokensResetAt, now.addingTimeInterval(30.0))
        XCTAssertEqual(observation.status, .available)
    }
    func testErrorDiscriminationDistinguishesTemporaryRateLimitFromQuotaExhaustion() {
        let now = Date(timeIntervalSince1970: 2000)
        // Temporary rate limit
        let tempObs = ProviderObservation(headers: ["retry-after": "45"], now: now, httpStatus: 429)
        XCTAssertEqual(tempObs.status, .temporaryRateLimit(retryAt: now.addingTimeInterval(45)))

        var tempAvail = ProviderAvailability()
        tempAvail.fail(status: tempObs.status, now: now)
        XCTAssertFalse(tempAvail.mayAttemptOpenAI(now: now.addingTimeInterval(30)))
        XCTAssertTrue(tempAvail.mayAttemptOpenAI(now: now.addingTimeInterval(46)))

        // Permanent / billing quota exhaustion (insufficient_quota)
        let quotaObs = ProviderObservation(headers: [:], now: now, httpStatus: 429, errorCode: "insufficient_quota")
        XCTAssertEqual(quotaObs.status, .quotaExhausted)

        var quotaAvail = ProviderAvailability()
        quotaAvail.fail(status: quotaObs.status, now: now)
        XCTAssertNil(quotaAvail.retryAt)
        XCTAssertFalse(quotaAvail.mayAttemptOpenAI(now: now.addingTimeInterval(3600)))
        XCTAssertFalse(quotaAvail.mayAttemptOpenAI(now: now.addingTimeInterval(86400)))
    }
}
