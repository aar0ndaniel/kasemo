import Foundation
@preconcurrency import AVFoundation
import MuralCore

@MainActor final class GeminiLiveTransport {
    var onEvent: (([String: Any]) -> Void)?
    var onLevels: ((Double, Double) -> Void)?
    var onFailure: ((String) -> Void)?
    private var socket: URLSessionWebSocketTask?
    private var session: URLSession?
    private var reader: Task<Void, Never>?
    private var writer: Task<Void, Never>?
    private var outbound: [Data] = []
    private var engine: AVAudioEngine?
    private var player: AVAudioPlayerNode?
    private var captureInstalled = false
    private var queuedFrames = 0
    private var playbackGeneration = UUID()
    private var attempt = UUID()
    private var ready = false
    private var connectionError: GeminiError?
    private var muted = false
    private var closing = true
    private var startedAt = Date()
    private var outputLevel = 0.0
    private var lastUsageUpdate = Date.distantPast
    private var turnID = UUID().uuidString

    func connect(instructions: String, initiallyMuted: Bool = false) async throws {
        disconnect()
        guard let key = GeminiCredentialStore.read() else { throw GeminiError.missingKey }
        guard await AVAudioApplication.requestRecordPermission() else { throw LiveTransport.TransportError.microphone }
        try Task.checkCancellation()
        let generation = UUID(); attempt = generation; closing = false; ready = false; connectionError = nil
        let config = URLSessionConfiguration.ephemeral
        config.httpCookieStorage = nil; config.urlCache = nil; config.timeoutIntervalForRequest = 30
        let session = URLSession(configuration: config, delegate: NoRedirect(), delegateQueue: nil); self.session = session
        guard let url = GeminiWire.liveURL(key: key) else { throw GeminiError.invalidKey }
        let request = URLRequest(url: url)
        let socket = session.webSocketTask(with: request); socket.maximumMessageSize = 8_000_000; self.socket = socket
        socket.resume()
        do {
            try await socket.send(.data(try JSONSerialization.data(withJSONObject: GeminiWire.setup(model: GeminiClient.liveModel, instructions: instructions))))
            reader = Task { [weak self] in
                do {
                    while !Task.isCancelled {
                        let message = try await socket.receive()
                        guard let self, self.attempt == generation, !self.closing else { return }
                        let data: Data
                        switch message { case .data(let value): data = value; case .string(let value): data = Data(value.utf8); @unknown default: continue }
                        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw GeminiError.incomplete }
                        self.receive(json)
                    }
                } catch {
                    guard let self, self.attempt == generation, !self.closing, !Task.isCancelled else { return }
                    self.fail()
                }
            }
            let deadline = Date().addingTimeInterval(25)
            while !ready {
                try await Task.sleep(for: .milliseconds(80))
                guard attempt == generation, !closing else { throw connectionError ?? GeminiError.connection }
                guard Date() < deadline else { throw GeminiError.timeout }
            }
            try Task.checkCancellation()
            startedAt = .now; muted = initiallyMuted
            try startAudio(generation: generation)
            onEvent?(["type": "session.started", "provider": "gemini"])
        } catch {
            if attempt == generation { disconnect() }
            throw error
        }
    }
    @discardableResult func send(_ event: [String: Any]) -> Bool {
        guard ready, !closing, let type = event["type"] as? String else { return false }
        guard let content = event["content"] as? String else { return false }
        let payload: [String: Any]
        if let id = event["delegation_id"] as? String { payload = GeminiWire.toolResponse(id: id, text: content) }
        else {
            let isThinking = type == "session.thinking.append"
            payload = GeminiWire.text("Application \(isThinking ? "teaching context (do not read aloud)" : "conversation guidance"): " + content, complete: !isThinking)
        }
        return enqueue(payload)
    }
    @discardableResult func sendTyped(_ text: String) -> Bool { enqueue(GeminiWire.text(text)) }
    func mute(_ value: Bool) {
        muted = value
        if value { _ = enqueue(["realtimeInput": ["audioStreamEnd": true]]) }
        onLevels?(0, outputLevel)
    }
    func close() {
        let seconds = max(0, Date().timeIntervalSince(startedAt))
        disconnect()
        onEvent?(["type": "session.closed", "reason": "Ended by you", "usage": ["seconds": seconds], "usageConfirmed": false])
    }
    func disconnect() {
        closing = true; ready = false; attempt = UUID()
        reader?.cancel(); reader = nil; writer?.cancel(); writer = nil; outbound = []
        socket?.cancel(with: .normalClosure, reason: nil); socket = nil
        session?.invalidateAndCancel(); session = nil
        if captureInstalled { engine?.inputNode.removeTap(onBus: 0); captureInstalled = false }
        player?.stop(); engine?.stop(); player = nil
        if engine != nil { try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation) }
        engine = nil; queuedFrames = 0; playbackGeneration = UUID(); outputLevel = 0
        onLevels?(0, 0)
    }
    private func fail(_ error: GeminiError = .connection) {
        let wasReady = ready
        connectionError = error
        disconnect()
        if wasReady { onFailure?(error.localizedDescription) }
    }
    @discardableResult private func enqueue(_ json: [String: Any]) -> Bool {
        guard ready, !closing, let data = try? JSONSerialization.data(withJSONObject: json) else { return false }
        guard outbound.count < 32 else { fail(); return false }
        outbound.append(data)
        guard writer == nil, let socket else { return true }
        let generation = attempt
        writer = Task { [weak self] in
            do {
                while let self, self.attempt == generation, !Task.isCancelled, !self.outbound.isEmpty {
                    let data = self.outbound.removeFirst()
                    try await socket.send(.data(data))
                }
                if self?.attempt == generation { self?.writer = nil }
            } catch {
                if let self, self.attempt == generation, !Task.isCancelled { self.fail() }
            }
        }
        return true
    }
    private func startAudio(generation: UUID) throws {
        let audio = AVAudioSession.sharedInstance()
        try audio.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetoothHFP])
        try? audio.overrideOutputAudioPort(.speaker)
        try audio.setActive(true)
        let engine = AVAudioEngine(); self.engine = engine
        try engine.inputNode.setVoiceProcessingEnabled(true)
        let inputFormat = engine.inputNode.outputFormat(forBus: 0)
        guard inputFormat.sampleRate > 0,
              let pcmFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 16000, channels: 1, interleaved: true),
              let converter = AVAudioConverter(from: inputFormat, to: pcmFormat),
              let outputFormat = AVAudioFormat(standardFormatWithSampleRate: 24000, channels: 1) else { throw GeminiError.audio }
        let player = AVAudioPlayerNode(); self.player = player
        engine.attach(player); engine.connect(player, to: engine.mainMixerNode, format: outputFormat)
        engine.inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
            let capacity = AVAudioFrameCount(Double(buffer.frameLength) * 16000 / inputFormat.sampleRate + 32)
            guard let converted = AVAudioPCMBuffer(pcmFormat: pcmFormat, frameCapacity: capacity) else { return }
            var provided = false
            var conversionError: NSError?
            converter.convert(to: converted, error: &conversionError) { _, status in
                if provided { status.pointee = .noDataNow; return nil }
                provided = true; status.pointee = .haveData; return buffer
            }
            guard conversionError == nil, converted.frameLength > 0,
                  let samples = converted.int16ChannelData?.pointee else { return }
            let data = Data(bytes: samples, count: Int(converted.frameLength) * 2)
            let level = min(1, sqrt((0..<Int(converted.frameLength)).reduce(0.0) { $0 + pow(Double(samples[$1]) / 32768, 2) } / Double(converted.frameLength)) * 4)
            Task { @MainActor [weak self] in
                guard let self, self.attempt == generation, !self.closing else { return }
                if !self.muted { _ = self.enqueue(GeminiWire.audio(data)) }
                self.onLevels?(self.muted ? 0 : level, self.outputLevel)
            }
        }
        captureInstalled = true; engine.prepare(); try engine.start(); player.play()
    }
    private func play(_ data: Data) {
        guard let player, let format = AVAudioFormat(standardFormatWithSampleRate: 24000, channels: 1) else { return }
        let count = data.count / 2
        guard count > 0, queuedFrames + count <= 24_000 * 60,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(count)),
              let destination = buffer.floatChannelData?.pointee else { fail(); return }
        buffer.frameLength = AVAudioFrameCount(count)
        // Read bytes explicitly; Data's storage need not be aligned for Int16.
        let bytes = [UInt8](data)
        for i in 0..<count { destination[i] = Float(Int16(bitPattern: UInt16(bytes[2*i]) | UInt16(bytes[2*i+1]) << 8)) / 32768 }
        queuedFrames += count; outputLevel = 0.2
        let generation = playbackGeneration
        player.scheduleBuffer(buffer, completionCallbackType: .dataPlayedBack) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.playbackGeneration == generation else { return }
                self.queuedFrames = max(0, self.queuedFrames - count)
                if self.queuedFrames == 0 { self.outputLevel = 0; self.onLevels?(0, 0) }
            }
        }
        if !player.isPlaying { player.play() }
    }
    private func receive(_ json: [String: Any]) {
        if json["setupComplete"] != nil { ready = true; return }
        if let error = json["error"] as? [String: Any] {
            let message = error["message"] as? String ?? "The voice request was rejected."
            // Provider errors can echo request details. Never display the credential.
            let safe = GeminiCredentialStore.read().map { message.replacingOccurrences(of: $0, with: "[redacted]") } ?? message
            fail(.server(String(safe.prefix(500)))); return
        }
        if let calls = (json["toolCall"] as? [String: Any])?["functionCalls"] as? [[String: Any]] {
            for call in calls where call["name"] as? String == "mural_lookup" {
                if let id = call["id"] as? String { onEvent?(["type": "session.delegation.created", "delegation": ["id": id, "target": "client"]]) }
            }
        }
        if json["goAway"] != nil { onEvent?(["type": "mural.provider.notice", "message": "Gemini’s session will expire soon. End and start a new conversation to reconnect."]) }
        guard let content = json["serverContent"] as? [String: Any] else { return }
        if content["interrupted"] as? Bool == true {
            player?.stop(); player?.play(); queuedFrames = 0; playbackGeneration = UUID(); outputLevel = 0; onLevels?(0, 0)
        }
        for (field, type) in [("inputTranscription", "session.input_transcript.delta"), ("outputTranscription", "session.output_transcript.delta")] {
            if let text = (content[field] as? [String: Any])?["text"] as? String, !text.isEmpty {
                let ms = max(0, Int(Date().timeIntervalSince(startedAt) * 1000))
                onEvent?(["type": type, "event_id": UUID().uuidString, "delta": text, "start_ms": ms, "end_ms": ms + 1, "utterance_id": turnID + field])
            }
        }
        if let parts = (content["modelTurn"] as? [String: Any])?["parts"] as? [[String: Any]] {
            for part in parts {
                if let text = part["text"] as? String, !text.isEmpty {
                    let ms = max(0, Int(Date().timeIntervalSince(startedAt) * 1000))
                    onEvent?(["type": "session.output_transcript.delta", "event_id": UUID().uuidString, "delta": text, "start_ms": ms, "end_ms": ms + 1, "utterance_id": turnID + "output"])
                }
                if let data = GeminiWire.pcm(part) { play(data) }
            }
        }
        if content["turnComplete"] as? Bool == true { turnID = UUID().uuidString }
        if Date().timeIntervalSince(lastUsageUpdate) >= 5 {
            lastUsageUpdate = .now
            onEvent?(["type": "session.usage.updated", "usage": ["seconds": max(0, Date().timeIntervalSince(startedAt))]])
        }
    }
}
