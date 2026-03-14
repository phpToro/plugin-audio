import Foundation
import AVFoundation

final class AudioHandler: NativeHandler {
    let namespace = "audio"

    var onAsyncCallback: ((String, Any?) -> Void)?

    private var audioPlayer: AVAudioPlayer?
    private var audioRecorder: AVAudioRecorder?
    private var pendingCallbackRef: String?

    func handle(method: String, args: [String: Any]) -> Any? {
        switch method {
        case "play":
            return play(args)

        case "pause":
            audioPlayer?.pause()
            return true

        case "resume":
            audioPlayer?.play()
            return true

        case "stop":
            audioPlayer?.stop()
            audioPlayer = nil
            return true

        case "setVolume":
            let volume = args["volume"] as? Float ?? 1.0
            audioPlayer?.volume = volume
            return true

        case "isPlaying":
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

        let url: URL
        if path.hasPrefix("http://") || path.hasPrefix("https://") {
            // Remote URL — download first
            let ref = args["_callbackRef"] as? String
            guard let remoteURL = URL(string: path) else {
                return ["error": "Invalid URL"]
            }
            URLSession.shared.dataTask(with: remoteURL) { data, _, error in
                if let error = error {
                    self.onAsyncCallback?(ref ?? "", ["error": error.localizedDescription])
                    return
                }
                guard let data = data else {
                    self.onAsyncCallback?(ref ?? "", ["error": "No data received"])
                    return
                }
                DispatchQueue.main.async {
                    do {
                        self.audioPlayer = try AVAudioPlayer(data: data)
                        self.audioPlayer?.play()
                        self.onAsyncCallback?(ref ?? "", ["playing": true])
                    } catch {
                        self.onAsyncCallback?(ref ?? "", ["error": error.localizedDescription])
                    }
                }
            }.resume()
            return ["status": "loading"]
        }

        url = URL(fileURLWithPath: path)

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
            dbg.log("Audio", "Playing: \(path)")
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
