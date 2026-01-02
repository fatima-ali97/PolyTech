//
//  VoiceRecorderManager.swift
//  PolyTech
//
//  Created by BP-36-213-19 on 02/01/2026.
//


import AVFoundation
import UIKit

class VoiceRecorderManager: NSObject {
    
    // MARK: - Properties
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingSession: AVAudioSession!
    private var recordingURL: URL?
    
    var isRecording: Bool {
        return audioRecorder?.isRecording ?? false
    }
    
    var isPlaying: Bool {
        return audioPlayer?.isPlaying ?? false
    }
    
    var currentTime: TimeInterval {
        if isRecording {
            return audioRecorder?.currentTime ?? 0
        } else if isPlaying {
            return audioPlayer?.currentTime ?? 0
        }
        return 0
    }
    
    var duration: TimeInterval {
        return audioPlayer?.duration ?? 0
    }
    
    // Callbacks
    var onRecordingComplete: ((URL) -> Void)?
    var onPlaybackComplete: (() -> Void)?
    var onError: ((Error) -> Void)?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    // MARK: - Setup
    
    private func setupAudioSession() {
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
        } catch {
            print("Failed to set up recording session: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Permission
    
    func requestRecordingPermission(completion: @escaping (Bool) -> Void) {
        recordingSession.requestRecordPermission{ allowed in
            DispatchQueue.main.async {
                completion(allowed)
            }
        }
    }
    
    // MARK: - Recording
    
    func startRecording() throws {
        // Create a unique filename
        let fileName = "voice_note_\(Date().timeIntervalSince1970).m4a"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        recordingURL = documentsPath.appendingPathComponent(fileName)
        
        guard let url = recordingURL else {
            throw RecordingError.invalidURL
        }
        
        // Define recording settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            print("✅ Recording started at: \(url)")
        } catch {
            throw RecordingError.recordingFailed(error)
        }
    }
    
    func stopRecording() -> URL? {
        guard let recorder = audioRecorder, recorder.isRecording else {
            return nil
        }
        
        recorder.stop()
        print("⏹ Recording stopped")
        return recordingURL
    }
    
    func cancelRecording() {
        if let recorder = audioRecorder, recorder.isRecording {
            recorder.stop()
            recorder.deleteRecording()
            recordingURL = nil
            print("❌ Recording cancelled")
        }
    }
    
    // MARK: - Playback
    
    func playAudio(from url: URL) throws {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            print("▶️ Playing audio from: \(url)")
        } catch {
            throw PlaybackError.playbackFailed(error)
        }
    }
    
    func playAudio(from data: Data) throws {
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            print("▶️ Playing audio from data")
        } catch {
            throw PlaybackError.playbackFailed(error)
        }
    }
    
    func pausePlayback() {
        audioPlayer?.pause()
        print("⏸ Playback paused")
    }
    
    func resumePlayback() {
        audioPlayer?.play()
        print("▶️ Playback resumed")
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        print("⏹ Playback stopped")
    }
    
    func seekToTime(_ time: TimeInterval) {
        audioPlayer?.currentTime = time
    }
    
    // MARK: - Utility
    
    func getRecordingData() -> Data? {
        guard let url = recordingURL else { return nil }
        return try? Data(contentsOf: url)
    }
    
    func deleteRecording() {
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
            recordingURL = nil
            print("🗑 Recording deleted")
        }
    }
    
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Errors
    
    enum RecordingError: Error {
        case invalidURL
        case recordingFailed(Error)
        case permissionDenied
        
        var localizedDescription: String {
            switch self {
            case .invalidURL:
                return "Failed to create recording URL"
            case .recordingFailed(let error):
                return "Recording failed: \(error.localizedDescription)"
            case .permissionDenied:
                return "Microphone access denied. Please enable it in Settings."
            }
        }
    }
    
    enum PlaybackError: Error {
        case playbackFailed(Error)
        
        var localizedDescription: String {
            switch self {
            case .playbackFailed(let error):
                return "Playback failed: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - AVAudioRecorderDelegate

extension VoiceRecorderManager: AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag, let url = recordingURL {
            print("✅ Recording finished successfully")
            onRecordingComplete?(url)
        } else {
            print("❌ Recording failed")
            onError?(RecordingError.recordingFailed(NSError(domain: "Recording", code: -1)))
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            print("❌ Recording error: \(error.localizedDescription)")
            onError?(error)
        }
    }
}

// MARK: - AVAudioPlayerDelegate

extension VoiceRecorderManager: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("✅ Playback finished")
        onPlaybackComplete?()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            print("❌ Playback error: \(error.localizedDescription)")
            onError?(error)
        }
    }
}
