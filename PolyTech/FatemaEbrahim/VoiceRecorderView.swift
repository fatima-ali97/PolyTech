////
////  VoiceRecorderView.swift
////  PolyTech
////
////  Created by BP-36-213-19 on 02/01/2026.
////
//
//
//import UIKit
//
//class VoiceRecorderView: UIView {
//    
//    // MARK: - UI Components
//    
//    private let containerView: UIView = {
//        let view = UIView()
//        view.backgroundColor = .systemBackground
//        view.layer.cornerRadius = 16
//        view.layer.borderWidth = 1.5
//        view.layer.borderColor = UIColor.systemGray4.cgColor
//        view.translatesAutoresizingMaskIntoConstraints = false
//        return view
//    }()
//    
//    private let titleLabel: UILabel = {
//        let label = UILabel()
//        label.text = "Voice Note (Optional)"
//        label.font = .systemFont(ofSize: 16, weight: .semibold)
//        label.textColor = .label
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//    
//    private let recordButton: UIButton = {
//        let button = UIButton(type: .system)
//        var config = UIButton.Configuration.filled()
//        config.image = UIImage(systemName: "mic.fill")
//        config.baseBackgroundColor = .systemRed
//        config.baseForegroundColor = .white
//        config.cornerStyle = .capsule
//        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
//        button.configuration = config
//        button.translatesAutoresizingMaskIntoConstraints = false
//        return button
//    }()
//    
//    private let timeLabel: UILabel = {
//        let label = UILabel()
//        label.text = "00:00"
//        label.font = .monospacedDigitSystemFont(ofSize: 18, weight: .medium)
//        label.textColor = .label
//        label.textAlignment = .center
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//    
//    private let statusLabel: UILabel = {
//        let label = UILabel()
//        label.text = "Tap to record"
//        label.font = .systemFont(ofSize: 14, weight: .regular)
//        label.textColor = .secondaryLabel
//        label.textAlignment = .center
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//    
//    private let waveformView: WaveformView = {
//        let view = WaveformView()
//        view.translatesAutoresizingMaskIntoConstraints = false
//        view.isHidden = true
//        return view
//    }()
//    
//    private let deleteButton: UIButton = {
//        let button = UIButton(type: .system)
//        var config = UIButton.Configuration.plain()
//        config.image = UIImage(systemName: "trash.fill")
//        config.baseForegroundColor = .systemRed
//        button.configuration = config
//        button.translatesAutoresizingMaskIntoConstraints = false
//        button.isHidden = true
//        return button
//    }()
//    
//    private let playButton: UIButton = {
//        let button = UIButton(type: .system)
//        var config = UIButton.Configuration.filled()
//        config.image = UIImage(systemName: "play.fill")
//        config.baseBackgroundColor = .systemBlue
//        config.baseForegroundColor = .white
//        config.cornerStyle = .capsule
//        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
//        button.configuration = config
//        button.translatesAutoresizingMaskIntoConstraints = false
//        button.isHidden = true
//        return button
//    }()
//    
//    // MARK: - Properties
//    
//    private var timer: Timer?
//    private var recordingStartTime: Date?
//    
//    enum State {
//        case idle
//        case recording
//        case recorded
//        case playing
//        case paused
//    }
//    
//    private var state: State = .idle {
//        didSet {
//            updateUI()
//        }
//    }
//    
//    var onRecordTapped: (() -> Void)?
//    var onStopTapped: (() -> Void)?
//    var onPlayTapped: (() -> Void)?
//    var onPauseTapped: (() -> Void)?
//    var onDeleteTapped: (() -> Void)?
//    
//    // MARK: - Initialization
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        setupUI()
//    }
//    
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        setupUI()
//    }
//    
//    // MARK: - Setup
//    
//    private func setupUI() {
//        addSubview(containerView)
//        containerView.addSubview(titleLabel)
//        containerView.addSubview(recordButton)
//        containerView.addSubview(timeLabel)
//        containerView.addSubview(statusLabel)
//        containerView.addSubview(waveformView)
//        containerView.addSubview(deleteButton)
//        containerView.addSubview(playButton)
//        
//        NSLayoutConstraint.activate([
//            containerView.topAnchor.constraint(equalTo: topAnchor),
//            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
//            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
//            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
//            
//            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
//            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
//            
//            deleteButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
//            deleteButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
//            deleteButton.widthAnchor.constraint(equalToConstant: 44),
//            deleteButton.heightAnchor.constraint(equalToConstant: 44),
//            
//            recordButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
//            recordButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
//            recordButton.widthAnchor.constraint(equalToConstant: 64),
//            recordButton.heightAnchor.constraint(equalToConstant: 64),
//            
//            playButton.centerYAnchor.constraint(equalTo: recordButton.centerYAnchor),
//            playButton.trailingAnchor.constraint(equalTo: recordButton.leadingAnchor, constant: -20),
//            playButton.widthAnchor.constraint(equalToConstant: 48),
//            playButton.heightAnchor.constraint(equalToConstant: 48),
//            
//            timeLabel.topAnchor.constraint(equalTo: recordButton.bottomAnchor, constant: 16),
//            timeLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
//            
//            statusLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 4),
//            statusLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
//            
//            waveformView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 12),
//            waveformView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
//            waveformView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
//            waveformView.heightAnchor.constraint(equalToConstant: 40),
//            waveformView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
//        ])
//        
//        recordButton.addTarget(self, action: #selector(recordButtonTapped), for: .touchUpInside)
//        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
//        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
//    }
//    
//    // MARK: - Actions
//    
//    @objc private func recordButtonTapped() {
//        switch state {
//        case .idle:
//            onRecordTapped?()
//        case .recording:
//            onStopTapped?()
//        case .recorded, .paused:
//            // Do nothing - use play button
//            break
//        case .playing:
//            onPauseTapped?()
//        }
//    }
//    
//    @objc private func playButtonTapped() {
//        switch state {
//        case .recorded, .paused:
//            onPlayTapped?()
//        case .playing:
//            onPauseTapped?()
//        default:
//            break
//        }
//    }
//    
//    @objc private func deleteButtonTapped() {
//        onDeleteTapped?()
//    }
//    
//    // MARK: - Public Methods
//    
//    func startRecording() {
//        state = .recording
//        recordingStartTime = Date()
//        startTimer()
//        waveformView.startAnimating()
//    }
//    
//    func stopRecording(duration: TimeInterval) {
//        state = .recorded
//        stopTimer()
//        waveformView.stopAnimating()
//        timeLabel.text = formatTime(duration)
//    }
//    
//    func startPlaying() {
//        state = .playing
//        startTimer()
//    }
//    
//    func pausePlaying() {
//        state = .paused
//        stopTimer()
//    }
//    
//    func stopPlaying() {
//        state = .recorded
//        stopTimer()
//    }
//    
//    func reset() {
//        state = .idle
//        stopTimer()
//        timeLabel.text = "00:00"
//        waveformView.stopAnimating()
//    }
//    
//    func updateTime(_ time: TimeInterval) {
//        timeLabel.text = formatTime(time)
//    }
//    
//    // MARK: - Private Methods
//    
//    private func updateUI() {
//        UIView.animate(withDuration: 0.3) {
//            switch self.state {
//            case .idle:
//                self.recordButton.configuration?.image = UIImage(systemName: "mic.fill")
//                self.recordButton.configuration?.baseBackgroundColor = .systemRed
//                self.statusLabel.text = "Tap to record"
//                self.waveformView.isHidden = true
//                self.deleteButton.isHidden = true
//                self.playButton.isHidden = true
//                self.timeLabel.text = "00:00"
//                
//            case .recording:
//                self.recordButton.configuration?.image = UIImage(systemName: "stop.fill")
//                self.recordButton.configuration?.baseBackgroundColor = .systemRed
//                self.statusLabel.text = "Recording..."
//                self.waveformView.isHidden = false
//                self.deleteButton.isHidden = true
//                self.playButton.isHidden = true
//                
//                // Pulse animation for recording
//                UIView.animate(withDuration: 0.8, delay: 0, options: [.repeat, .autoreverse]) {
//                    self.recordButton.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
//                }
//                
//            case .recorded:
//                self.recordButton.transform = .identity
//                self.recordButton.layer.removeAllAnimations()
//                self.recordButton.configuration?.image = UIImage(systemName: "waveform")
//                self.recordButton.configuration?.baseBackgroundColor = .systemGreen
//                self.statusLabel.text = "Recording saved"
//                self.waveformView.isHidden = true
//                self.deleteButton.isHidden = false
//                self.playButton.isHidden = false
//                self.playButton.configuration?.image = UIImage(systemName: "play.fill")
//                
//            case .playing:
//                self.recordButton.configuration?.image = UIImage(systemName: "pause.fill")
//                self.recordButton.configuration?.baseBackgroundColor = .systemBlue
//                self.statusLabel.text = "Playing..."
//                self.playButton.configuration?.image = UIImage(systemName: "pause.fill")
//                
//            case .paused:
//                self.recordButton.configuration?.image = UIImage(systemName: "waveform")
//                self.recordButton.configuration?.baseBackgroundColor = .systemGreen
//                self.statusLabel.text = "Paused"
//                self.playButton.configuration?.image = UIImage(systemName: "play.fill")
//            }
//        }
//    }
//    
//    private func startTimer() {
//        timer?.invalidate()
//        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
//            self?.updateTimerLabel()
//        }
//    }
//    
//    private func stopTimer() {
//        timer?.invalidate()
//        timer = nil
//    }
//    
//    private func updateTimerLabel() {
//        guard let startTime = recordingStartTime else { return }
//        let elapsed = Date().timeIntervalSince(startTime)
//        timeLabel.text = formatTime(elapsed)
//    }
//    
//    private func formatTime(_ time: TimeInterval) -> String {
//        let minutes = Int(time) / 60
//        let seconds = Int(time) % 60
//        return String(format: "%02d:%02d", minutes, seconds)
//    }
//}
//
//// MARK: - Waveform View
//
//class WaveformView: UIView {
//    
//    private var bars: [UIView] = []
//    private var timer: Timer?
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        setupBars()
//    }
//    
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        setupBars()
//    }
//    
//    private func setupBars() {
//        let barCount = 20
//        let barWidth: CGFloat = 3
//        let spacing: CGFloat = 4
//        
//        for i in 0..<barCount {
//            let bar = UIView()
//            bar.backgroundColor = .systemBlue
//            bar.layer.cornerRadius = barWidth / 2
//            bar.translatesAutoresizingMaskIntoConstraints = false
//            addSubview(bar)
//            
//            NSLayoutConstraint.activate([
//                bar.widthAnchor.constraint(equalToConstant: barWidth),
//                bar.centerYAnchor.constraint(equalTo: centerYAnchor),
//                bar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: CGFloat(i) * (barWidth + spacing)),
//                bar.heightAnchor.constraint(equalToConstant: 8)
//            ])
//            
//            bars.append(bar)
//        }
//    }
//    
//    func startAnimating() {
//        timer?.invalidate()
//        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
//            self?.animateBars()
//        }
//    }
//    
//    func stopAnimating() {
//        timer?.invalidate()
//        timer = nil
//        
//        // Reset all bars to minimum height
//        for bar in bars {
//            UIView.animate(withDuration: 0.2) {
//                bar.transform = .identity
//            }
//        }
//    }
//    
//    private func animateBars() {
//        for bar in bars {
//            let randomHeight = CGFloat.random(in: 0.3...1.0)
//            UIView.animate(withDuration: 0.2) {
//              // bar.transform = CGAffineTransform(scaleY: randomHeight * 4)
//            }
//        }
//    }
//}
