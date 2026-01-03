import UIKit
import AVFoundation

class VoiceRecordingViewController: UIViewController {
    
    // MARK: - Properties
    
    private let voiceRecorderManager = VoiceRecorderManager()
    private var recordedVoiceURL: URL?
    private var timer: Timer?
    private var recordingStartTime: Date?
    
    // Callback to pass recorded audio back
    var onRecordingComplete: ((URL) -> Void)?
    
    enum RecordingState {
        case idle
        case recording
        case recorded
        case playing
        case paused
    }
    
    private var state: RecordingState = .idle {
        didSet {
            updateUI()
        }
    }
    
    // MARK: - UI Components
    
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .background
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Record Voice Note"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "xmark.circle.fill")
        config.baseForegroundColor = .label
        button.configuration = config
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let microphoneIconView: UIView = {
        let view = UIView()
        view.backgroundColor = .error.withAlphaComponent(0.1)
        view.layer.cornerRadius = 80
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let microphoneIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "mic.fill")
        iv.tintColor = .onError
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let recordButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "mic.fill")
        config.baseBackgroundColor = .error
        config.baseForegroundColor = .onError
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
        button.configuration = config
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.font = .monospacedDigitSystemFont(ofSize: 48, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Tap the button to start recording"
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let VoiceWaveformView: WaveformView = {
        let view = WaveformView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    private let playButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = "Play Recording"
        config.image = UIImage(systemName: "play.fill")
        config.imagePlacement = .leading
        config.imagePadding = 8
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24)
        button.configuration = config
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()
    
    private let deleteButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.title = "Delete & Re-record"
        config.image = UIImage(systemName: "trash.fill")
        config.imagePlacement = .leading
        config.imagePadding = 8
        config.baseForegroundColor = .systemRed
        button.configuration = config
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()
    
    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = "Save Voice Note"
        config.image = UIImage(systemName: "checkmark.circle.fill")
        config.imagePlacement = .leading
        config.imagePadding = 8
        config.baseBackgroundColor = .systemGreen
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24)
        button.configuration = config
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()
    
    private let instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "Voice notes help technicians understand the issue better. "
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        setupUI()
        setupActions()
        setupVoiceRecorder()
        requestMicrophonePermission()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Stop any ongoing recording or playback
        if voiceRecorderManager.isRecording {
            voiceRecorderManager.stopRecording()
        }
        if voiceRecorderManager.isPlaying {
            voiceRecorderManager.stopPlayback()
        }
        stopTimer()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.addSubview(headerView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(closeButton)
        view.addSubview(microphoneIconView)
        microphoneIconView.addSubview(microphoneIcon)
        view.addSubview(recordButton)
        view.addSubview(timeLabel)
        view.addSubview(statusLabel)
        view.addSubview(VoiceWaveformView)
        view.addSubview(playButton)
        view.addSubview(deleteButton)
        view.addSubview(saveButton)
        view.addSubview(instructionLabel)
        
        NSLayoutConstraint.activate([
            // Header
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 60),
            
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Microphone icon background
            microphoneIconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            microphoneIconView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 40),
            microphoneIconView.widthAnchor.constraint(equalToConstant: 160),
            microphoneIconView.heightAnchor.constraint(equalToConstant: 160),
            
            microphoneIcon.centerXAnchor.constraint(equalTo: microphoneIconView.centerXAnchor),
            microphoneIcon.centerYAnchor.constraint(equalTo: microphoneIconView.centerYAnchor),
            microphoneIcon.widthAnchor.constraint(equalToConstant: 80),
            microphoneIcon.heightAnchor.constraint(equalToConstant: 80),
            
            // Time label
            timeLabel.topAnchor.constraint(equalTo: microphoneIconView.bottomAnchor, constant: 40),
            timeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Status label
            statusLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 12),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            // Waveform
            VoiceWaveformView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20),
            VoiceWaveformView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            VoiceWaveformView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            VoiceWaveformView.heightAnchor.constraint(equalToConstant: 60),
            
            // Record button
            recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordButton.bottomAnchor.constraint(equalTo: playButton.topAnchor, constant: -20),
            recordButton.widthAnchor.constraint(equalToConstant: 80),
            recordButton.heightAnchor.constraint(equalToConstant: 80),
            
            // Play button
            playButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playButton.bottomAnchor.constraint(equalTo: deleteButton.topAnchor, constant: -16),
            
            // Delete button
            deleteButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            deleteButton.bottomAnchor.constraint(equalTo: saveButton.topAnchor, constant: -12),
            
            // Save button
            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            saveButton.bottomAnchor.constraint(equalTo: instructionLabel.topAnchor, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: 54),
            
            // Instruction
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            instructionLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        recordButton.addTarget(self, action: #selector(recordButtonTapped), for: .touchUpInside)
        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
    }
    
    private func setupVoiceRecorder() {
        voiceRecorderManager.onRecordingComplete = { [weak self] url in
            self?.recordedVoiceURL = url
            print("✅ Recording saved at: \(url)")
        }
        
        voiceRecorderManager.onPlaybackComplete = { [weak self] in
            DispatchQueue.main.async {
                self?.state = .recorded
            }
        }
        
        voiceRecorderManager.onError = { [weak self] error in
            self?.showAlert("Error", message: error.localizedDescription)
        }
    }
    
    private func requestMicrophonePermission() {
        voiceRecorderManager.requestRecordingPermission { [weak self] granted in
            if !granted {
                self?.showPermissionDeniedAlert()
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func closeButtonTapped() {
        if state == .recording {
            let alert = UIAlertController(
                title: "Recording in Progress",
                message: "Are you sure you want to cancel? Your recording will be lost.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Keep Recording", style: .cancel))
            alert.addAction(UIAlertAction(title: "Discard", style: .destructive) { [weak self] _ in
                self?.voiceRecorderManager.cancelRecording()
                self?.dismiss(animated: true)
            })
            present(alert, animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    
    @objc private func recordButtonTapped() {
        switch state {
        case .idle:
            startRecording()
        case .recording:
            stopRecording()
        case .recorded, .paused:
            // Do nothing - use play button
            break
        case .playing:
            pausePlayback()
        }
    }
    
    @objc private func playButtonTapped() {
        switch state {
        case .recorded, .paused:
            startPlayback()
        case .playing:
            pausePlayback()
        default:
            break
        }
    }
    
    @objc private func deleteButtonTapped() {
        let alert = UIAlertController(
            title: "Delete Recording",
            message: "Are you sure you want to delete this recording?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deleteRecording()
        })
        present(alert, animated: true)
    }
    
    @objc private func saveButtonTapped() {
        guard let url = recordedVoiceURL else {
            showAlert("Error", message: "No recording found")
            return
        }
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Pass the recording back
        onRecordingComplete?(url)
        dismiss(animated: true)
    }
    
    // MARK: - Recording Methods
    
    private func startRecording() {
        do {
            try voiceRecorderManager.startRecording()
            state = .recording
            recordingStartTime = Date()
            startTimer()
            VoiceWaveformView.startAnimating()
            
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            print("🎤 Recording started")
        } catch {
            showAlert("Recording Failed", message: error.localizedDescription)
        }
    }
    
    private func stopRecording() {
        if let url = voiceRecorderManager.stopRecording() {
            recordedVoiceURL = url
            state = .recorded
            stopTimer()
            VoiceWaveformView.stopAnimating()
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            print("⏹ Recording stopped")
        }
    }
    
    private func startPlayback() {
        guard let url = recordedVoiceURL else { return }
        
        do {
            try voiceRecorderManager.playAudio(from: url)
            state = .playing
            startTimer()
            
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            print("▶️ Playback started")
        } catch {
            showAlert("Playback Failed", message: error.localizedDescription)
        }
    }
    
    private func pausePlayback() {
        voiceRecorderManager.pausePlayback()
        state = .paused
        stopTimer()
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        print("⏸ Playback paused")
    }
    
    private func deleteRecording() {
        voiceRecorderManager.deleteRecording()
        recordedVoiceURL = nil
        state = .idle
        timeLabel.text = "00:00"
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        
        print("🗑 Recording deleted")
    }
    
    // MARK: - Timer
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateTime()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateTime() {
        let currentTime: TimeInterval
        
        if state == .recording {
            currentTime = voiceRecorderManager.currentTime
        } else if state == .playing {
            currentTime = voiceRecorderManager.currentTime
        } else {
            return
        }
        
        timeLabel.text = formatTime(currentTime)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - UI Updates
    
    private func updateUI() {
        UIView.animate(withDuration: 0.3) {
            switch self.state {
            case .idle:
                self.recordButton.configuration?.image = UIImage(systemName: "mic.fill")
                self.recordButton.configuration?.baseBackgroundColor = .systemRed
                self.statusLabel.text = "Tap the button to start recording"
                self.VoiceWaveformView.isHidden = true
                self.playButton.isHidden = true
                self.deleteButton.isHidden = true
                self.saveButton.isHidden = true
                self.microphoneIcon.tintColor = .systemRed
                self.microphoneIconView.backgroundColor = .error.withAlphaComponent(0.1)
                
                // Stop any animations
                self.recordButton.layer.removeAllAnimations()
                self.recordButton.transform = .identity
                
            case .recording:
                self.recordButton.configuration?.image = UIImage(systemName: "stop.fill")
                self.recordButton.configuration?.baseBackgroundColor = .systemRed
                self.statusLabel.text = "Recording... Tap to stop"
                self.VoiceWaveformView.isHidden = false
                self.playButton.isHidden = true
                self.deleteButton.isHidden = true
                self.saveButton.isHidden = true
                self.microphoneIcon.tintColor = .systemRed
                self.microphoneIconView.backgroundColor = .error.withAlphaComponent(0.2)
                
                // Pulse animation
                UIView.animate(withDuration: 1.0, delay: 0, options: [.repeat, .autoreverse]) {
                    self.microphoneIconView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                    self.microphoneIconView.alpha = 0.8
                }
                
            case .recorded:
                self.recordButton.layer.removeAllAnimations()
                self.microphoneIconView.layer.removeAllAnimations()
                self.microphoneIconView.transform = .identity
                self.microphoneIconView.alpha = 1.0
                
                self.recordButton.configuration?.image = UIImage(systemName: "waveform")
                self.recordButton.configuration?.baseBackgroundColor = .systemGreen
                self.statusLabel.text = "Recording complete! Listen or save"
                self.VoiceWaveformView.isHidden = true
                self.playButton.isHidden = false
                self.playButton.configuration?.image = UIImage(systemName: "play.fill")
                self.playButton.configuration?.title = "Play Recording"
                self.deleteButton.isHidden = false
                self.saveButton.isHidden = false
                self.microphoneIcon.tintColor = .systemGreen
                self.microphoneIconView.backgroundColor = .tertiary.withAlphaComponent(0.1)
                
            case .playing:
                self.playButton.configuration?.image = UIImage(systemName: "pause.fill")
                self.playButton.configuration?.title = "Pause"
                self.statusLabel.text = "Playing recording..."
                self.microphoneIcon.tintColor = .systemBlue
                self.microphoneIconView.backgroundColor = .accent.withAlphaComponent(0.1)
                
            case .paused:
                self.playButton.configuration?.image = UIImage(systemName: "play.fill")
                self.playButton.configuration?.title = "Resume"
                self.statusLabel.text = "Paused"
                self.microphoneIcon.tintColor = .systemOrange
                self.microphoneIconView.backgroundColor = .systemOrange.withAlphaComponent(0.1)
            }
        }
    }
    
    // MARK: - Alerts
    
    private func showAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: "Microphone Access Required",
            message: "Please enable microphone access in Settings to record voice notes.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        present(alert, animated: true)
    }
}

// MARK: - Waveform View (Reuse from previous implementation)

class WaveformView: UIView {
    
    private var bars: [UIView] = []
    private var timer: Timer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupBars()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupBars()
    }
    
    private func setupBars() {
        let barCount = 30
        let barWidth: CGFloat = 4
        let spacing: CGFloat = 6
        
        for i in 0..<barCount {
            let bar = UIView()
            bar.backgroundColor = .systemRed
            bar.layer.cornerRadius = barWidth / 2
            bar.translatesAutoresizingMaskIntoConstraints = false
            addSubview(bar)
            
            NSLayoutConstraint.activate([
                bar.widthAnchor.constraint(equalToConstant: barWidth),
                bar.centerYAnchor.constraint(equalTo: centerYAnchor),
                bar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: CGFloat(i) * (barWidth + spacing)),
                bar.heightAnchor.constraint(equalToConstant: 10)
            ])
            
            bars.append(bar)
        }
    }
    
    func startAnimating() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.animateBars()
        }
    }
    
    func stopAnimating() {
        timer?.invalidate()
        timer = nil
        
        for bar in bars {
            UIView.animate(withDuration: 0.2) {
                bar.transform = .identity
            }
        }
    }
    
    private func animateBars() {
        for bar in bars {
            let randomHeight = CGFloat.random(in: 0.3...1.0)
            UIView.animate(withDuration: 0.15) {
                //bar.transform = CGAffineTransform(y: randomHeight * 5)
            }
        }
    }
}
