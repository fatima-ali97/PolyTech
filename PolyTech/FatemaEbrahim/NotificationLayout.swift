//
//  NotificationLayout.swift
//  PolyTech
//
//  Created by BP-19-130-15 on 24/12/2025.
//
import UIKit

class NotificationLayout: UIView {
    
    // UI Elements
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.2
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemBlue
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .secondaryLabel
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // Callback for tap action
    var onTap: (() -> Void)?
    var onDismiss: (() -> Void)?
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup
    
    private func setupView() {
        backgroundColor = .clear
        
        // Add subviews
        addSubview(containerView)
        containerView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(messageLabel)
        containerView.addSubview(closeButton)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            
            // Icon
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 32),
            iconImageView.heightAnchor.constraint(equalToConstant: 32),
            
            // Close button
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            closeButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalToConstant: 24),
            
            // Title label
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),
            
            // Message label
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            messageLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),
            messageLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        containerView.addGestureRecognizer(tapGesture)
        containerView.isUserInteractionEnabled = true
        
        // Add close button action
        closeButton.addTarget(self, action: #selector(handleDismiss), for: .touchUpInside)
    }
    
    // MARK: - Configuration
    
    func configure(title: String, message: String, icon: UIImage? = nil, backgroundColor: UIColor = .systemBackground) {
        titleLabel.text = title
        messageLabel.text = message
        iconImageView.image = icon ?? UIImage(systemName: "bell.fill")
        containerView.backgroundColor = backgroundColor
    }
    
    // MARK: - Actions
    
    @objc private func handleTap() {
        onTap?()
    }
    
    @objc private func handleDismiss() {
        onDismiss?()
    }
}
