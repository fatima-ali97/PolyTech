//
//  NotificationTableViewCell.swift
//  PolyTech
//
//  Created by BP-19-130-15 on 24/12/2025.
//

import UIKit

class NotificationTableViewCell: UITableViewCell {
    
    // MARK: - UI Components
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.systemGray5.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let iconBackgroundView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 20
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .white
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
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
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .tertiaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let unreadIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBlue
        view.layer.cornerRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        containerView.addSubview(iconBackgroundView)
        iconBackgroundView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(messageLabel)
        containerView.addSubview(timeLabel)
        containerView.addSubview(unreadIndicator)
        
        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            // Icon background
            iconBackgroundView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            iconBackgroundView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            iconBackgroundView.widthAnchor.constraint(equalToConstant: 40),
            iconBackgroundView.heightAnchor.constraint(equalToConstant: 40),
            
            // Icon image
            iconImageView.centerXAnchor.constraint(equalTo: iconBackgroundView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconBackgroundView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            // Title label
            titleLabel.leadingAnchor.constraint(equalTo: iconBackgroundView.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: unreadIndicator.leadingAnchor, constant: -8),
            
            // Message label
            messageLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            // Time label
            timeLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            timeLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 6),
            timeLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            
            // Unread indicator
            unreadIndicator.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            unreadIndicator.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            unreadIndicator.widthAnchor.constraint(equalToConstant: 8),
            unreadIndicator.heightAnchor.constraint(equalToConstant: 8)
        ])
    }
    
    // MARK: - Configuration
    
    func configure(with notification: NotificationModel) {
        titleLabel.text = notification.title
        messageLabel.text = notification.message
        timeLabel.text = notification.displayTime
        
        // Set icon
        if let icon = UIImage(systemName: notification.iconName) {
            iconImageView.image = icon
        }
        
        // Set colors based on type
        let colors = getColors(for: notification.type)
        iconBackgroundView.backgroundColor = colors.background
        iconImageView.tintColor = colors.icon
        
        // Show/hide unread indicator
        unreadIndicator.isHidden = notification.isRead
        
        // Update container appearance for read/unread
        if notification.isRead {
            containerView.backgroundColor = .systemBackground
            containerView.alpha = 0.7
        } else {
            containerView.backgroundColor = .systemBackground
            containerView.alpha = 1.0
        }
    }
    
    private func getColors(for type: NotificationModel.NotificationType) -> (background: UIColor, icon: UIColor) {
        switch type {
        case .success:
            return (.systemGreen.withAlphaComponent(0.2), .systemGreen)
        case .error:
            return (.systemRed.withAlphaComponent(0.2), .systemRed)
        case .warning:
            return (.systemOrange.withAlphaComponent(0.2), .systemOrange)
        case .info:
            return (.systemBlue.withAlphaComponent(0.2), .systemBlue)
        case .message:
            return (.systemPurple.withAlphaComponent(0.2), .systemPurple)
        case .like:
            return (.systemPink.withAlphaComponent(0.2), .systemPink)
        case .comment:
            return (.systemIndigo.withAlphaComponent(0.2), .systemIndigo)
        case .follow:
            return (.systemTeal.withAlphaComponent(0.2), .systemTeal)
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if selected {
            UIView.animate(withDuration: 0.1) {
                self.containerView.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
            }
        } else {
            UIView.animate(withDuration: 0.1) {
                self.containerView.transform = .identity
            }
        }
    }
}
