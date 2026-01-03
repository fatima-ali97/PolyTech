//
//  VoicePlayerView.swift
//  PolyTech
//
//  Created by Assistant on 03/01/2026.
//

import UIKit
import AVFoundation

class VoicePlayerView: UIView {
    
    // MARK: - UI Components
    
    private let playButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        button.tintColor = .systemBlue
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.text = "Voice Note"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .darkGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Properties
    
    private var audioPlayer: AVAudioPlayer?
    private var audioURL: URL?
    private var cloudinaryURL: String?
    
    var onError: ((String) -> Void)?
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupAudioSession()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupAudioSession()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .systemGray6
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray4.cgColor
        
        addSubview(playButton)
        addSubview(messageLabel)
        addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            // Play button
            playButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            playButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 44),
            playButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Message label
            messageLabel.leadingAnchor.constraint(equalTo: playButton.trailingAnchor, constant: 12),
            messageLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            
            // Activity indicator (centered on play button)
            activityIndicator.centerXAnchor.constraint(equalTo: playButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: playButton.centerYAnchor),
            
            // View height
            heightAnchor.constraint(equalToConstant: 60)
        ])
        
        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ Failed to setup audio session: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Configuration
    
    func configure(with urlString: String) {
        cloudinaryURL = urlString
        messageLabel.text = "Voice Note"
        playButton.isEnabled = true
        print("✅ Voice player configured with URL: \(urlString)")
    }
    
    // MARK: - Actions
    
    @objc private func playButtonTapped() {
        // If already playing, stop it
        if audioPlayer?.isPlaying == true {
            stopPlayback()
            return
        }
        
        // If audio is loaded, play it
        if audioPlayer != nil {
            playAudio()
            return
        }
        
        // Otherwise, download and play
        downloadAndPlay()
    }
    
    private func downloadAndPlay() {
        guard let urlString = cloudinaryURL,
              let url = URL(string: urlString) else {
            onError?("Invalid audio URL")
            return
        }
        
        // Show loading
        playButton.isHidden = true
        activityIndicator.startAnimating()
        messageLabel.text = "Loading..."
        
        // Download audio
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                self?.playButton.isHidden = false
                
                if let error = error {
                    print("❌ Error downloading audio: \(error.localizedDescription)")
                    self?.messageLabel.text = "Voice Note"
                    self?.onError?("Failed to download audio: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    self?.messageLabel.text = "Voice Note"
                    self?.onError?("No audio data received")
                    return
                }
                
                self?.setupPlayer(with: data)
                self?.playAudio()
            }
        }.resume()
    }
    
    private func setupPlayer(with data: Data) {
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            print("✅ Audio player setup complete")
        } catch {
            print("❌ Error setting up player: \(error.localizedDescription)")
            onError?("Failed to setup audio player: \(error.localizedDescription)")
        }
    }
    
    private func playAudio() {
        audioPlayer?.play()
        updatePlayButton(isPlaying: true)
        messageLabel.text = "Playing..."
        print("▶️ Playing audio")
    }
    
    private func stopPlayback() {
        audioPlayer?.pause()
        audioPlayer?.currentTime = 0
        updatePlayButton(isPlaying: false)
        messageLabel.text = "Voice Note"
        print("⏹ Playback stopped")
    }
    
    // MARK: - UI Updates
    
    private func updatePlayButton(isPlaying: Bool) {
        let imageName = isPlaying ? "stop.circle.fill" : "play.circle.fill"
        playButton.setImage(UIImage(systemName: imageName), for: .normal)
    }
    
    private func resetPlayer() {
        updatePlayButton(isPlaying: false)
        messageLabel.text = "Voice Note"
    }
    
    // MARK: - Cleanup
    
    deinit {
        audioPlayer?.stop()
    }
}

// MARK: - AVAudioPlayerDelegate

extension VoicePlayerView: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.resetPlayer()
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            DispatchQueue.main.async { [weak self] in
                self?.resetPlayer()
                self?.onError?("Playback error: \(error.localizedDescription)")
            }
        }
    }
}
