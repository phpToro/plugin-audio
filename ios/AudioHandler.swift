import Foundation
import AVFoundation

final class AudioHandler: AsyncHandler {
    let namespace = "audio"

    var onAsyncCallback: ((String, Any?) -> Void)?

    /// AVPlayer for streaming (remote URLs, radio)
    private var streamPlayer: AVPlayer?
    /// AVAudioPlayer for local files
    private var audioPlayer: AVAudioPlayer?
    private var audioRecorder: AVAudioRecorder?
    private var pendingCallbackRef: String?

    func handle(method: String, args: [String: Any]) -> Any? {
        switch method {
        case "play":
            return play(args)

        case "pause":
            streamPlayer?.pause()
            audioPlayer?.pause()
            return true

        case "resume":
            if let sp = streamPlayer {
                sp.play()
            } else {
                audioPlayer?.play()
            }
            return true

        case "stop":
            streamPlayer?.pause()
            streamPlayer = nil
            audioPlayer?.stop()
            audioPlayer = nil
            return true

        case "setVolume":
            let volume = args["volume"] as? Float ?? 1.0
            streamPlayer?.volume = volume
            audioPlayer?.volume = volume
            return true

        case "isPlaying":
            if let sp = streamPlayer {
                return sp.rate > 0
            }
            return audioPlayer?.isPlaying ?? false

        case "startRecording":
            return startRecording(args)

        case "stopRecording":
            return stopRecording()

        case "configureSession":
            return configureAudioSession(args)

        default:
            return ["error": "Unknown method: \(method)"]
        }
    }

    private func play(_ args: [String: Any]) -> Any? {
        guard let path = args["path"] as? String else {
            return ["error": "Missing path"]
        }

        let ref = args["_callbackRef"] as? String

        if path.hasPrefix("http://") || path.hasPrefix("https://") {
            // Streaming via AVPlayer (supports live radio + remote files)
            guard let url = URL(string: path) else {
                return ["error": "Invalid URL"]
            }

            // Stop any existing playback
            streamPlayer?.pause()
            streamPlayer = nil
            audioPlayer?.stop()
            audioPlayer = nil

            let player = AVPlayer(url: url)
            streamPlayer = player

            dbg.log("Audio", "Streaming: \(path)")
            player.play()

            // Notify when playback starts
            if let ref = ref {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.onAsyncCallback?(ref, ["playing": true])
                }
            }

            return ["status": "streaming"]
        }

        // Local file via AVAudioPlayer
        let url = URL(fileURLWithPath: path)
        streamPlayer?.pause()
        streamPlayer = nil

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
            dbg.log("Audio", "Playing local: \(path)")
            return true
        } catch {
            dbg.error("Audio", "Play failed: \(error)")
            return ["error": error.localizedDescription]
        }
    }

    private func startRecording(_ args: [String: Any]) -> Any? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "phptoro-recording-\(UUID().uuidString).m4a"
        let fileURL = tempDir.appendingPathComponent(fileName)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)

            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.record()
            dbg.log("Audio", "Recording to: \(fileURL.path)")
            return ["recording": true, "path": fileURL.path]
        } catch {
            dbg.error("Audio", "Record failed: \(error)")
            return ["error": error.localizedDescription]
        }
    }

    private func stopRecording() -> Any? {
        guard let recorder = audioRecorder else {
            return ["error": "Not recording"]
        }
        let path = recorder.url.path
        let duration = recorder.currentTime
        recorder.stop()
        audioRecorder = nil
        dbg.log("Audio", "Stopped recording: \(path) (\(duration)s)")
        return ["path": path, "duration": duration]
    }

    private func configureAudioSession(_ args: [String: Any]) -> Any? {
        let category = args["category"] as? String ?? "playback"

        do {
            let session = AVAudioSession.sharedInstance()
            switch category {
            case "playback":
                try session.setCategory(.playback, mode: .default)
            case "record":
                try session.setCategory(.record, mode: .default)
            case "playAndRecord":
                try session.setCategory(.playAndRecord, mode: .default)
            default:
                try session.setCategory(.playback, mode: .default)
            }
            try session.setActive(true)
            return true
        } catch {
            return ["error": error.localizedDescription]
        }
    }
}
