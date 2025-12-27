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
        
        // HERE
        view.backgroundColor =  .clear
        
        // 1. Set the border width (thickness)
        view.layer.borderWidth = 0.8

        // 2. Set the border color
        view.layer.borderColor = UIColor.systemGray.cgColor
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let iconContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .onPrimary
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let headerStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .onBackground
        label.numberOfLines = 3
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondary
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()
    private let locationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondary
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()
    
    private let timeIconImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "mappin")
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .primary
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .secondary
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    
    //TODO: CHANGE STYLIING
    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        // button.contentMode = .scaleAspectFit
        button.layer.cornerRadius = 12
        //button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Properties
    
    private var actionUrlString: String?
    private var actionCallback: ((String) -> Void)?
    
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
        //selectionStyle = .none
        
        contentView.addSubview(containerView)
        containerView.addSubview(iconContainerView)
        iconContainerView.addSubview(iconImageView)
        containerView.addSubview(contentStackView)
        
        // Add header with title and time
        headerStackView.addArrangedSubview(titleLabel)
        headerStackView.addArrangedSubview(timeIconImageView)
        headerStackView.addArrangedSubview(locationLabel)
        
        contentStackView.addArrangedSubview(headerStackView)
        contentStackView.addArrangedSubview(messageLabel)
        contentStackView.addArrangedSubview(timeLabel)
        contentStackView.addArrangedSubview(actionButton)
        
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            // Icon container
            iconContainerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            iconContainerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            iconContainerView.widthAnchor.constraint(equalToConstant: 60),
            iconContainerView.heightAnchor.constraint(equalToConstant: 60),
            
            // Icon image
            iconImageView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 32),
            iconImageView.heightAnchor.constraint(equalToConstant: 32),
            
            // Time icon
            timeIconImageView.widthAnchor.constraint(equalToConstant: 20),
            timeIconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            // Content stack
            contentStackView.leadingAnchor.constraint(equalTo: iconContainerView.trailingAnchor, constant: 16),
            contentStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            contentStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            contentStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - Configuration
    
    func configure(with notification: NotificationModel, actionCallback: ((String) -> Void)? = nil) {
        titleLabel.text = notification.title
        messageLabel.text = notification.message
        timeLabel.text = notification.displayTime
        locationLabel.text = notification.room 
        self.actionCallback = actionCallback
        self.actionUrlString = notification.actionUrl
        
        // Set icon based on notification type
        configureIcon(for: notification.type)
        
        // Configure action button if actionUrl exists
        if let actionUrl = notification.actionUrl {
            actionButton.isHidden = false
            configureActionButton(for: notification.type, actionUrl: actionUrl)
        } else {
            actionButton.isHidden = true
        }
        
        // Update appearance for read/unread
        //containerView.backgroundColor = notification.isRead ? .outline : .primary
        
        
        
        //containerView.alpha = notification.isRead ? 0.8 : 1
    }
    
    private func configureIcon(for type: NotificationModel.NotificationType) {
        let config: (icon: String, backgroundColor: UIColor) = {
            switch type {
            case .success:
                return ("checkmark", UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1.0))
            case .error:
                return ("xmark", UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1.0))
            case .fail:
                return ("xmark", UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1.0))
            case .info:
                return ("mappin.and.ellipse", UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1.0))
            case .message:
                return ("envelope.fill", UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1.0))
          case .accept:
                return ("checkmark", UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1.0))
            case .location:
                return ("person.badge.plus.fill", UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1.0))
            }
        }()
        
        iconImageView.image = UIImage(systemName: config.icon)
        iconContainerView.backgroundColor = config.backgroundColor
    }
    
    private func configureActionButton(for type: NotificationModel.NotificationType, actionUrl: String) {
        let config: (title: String, icon: String, backgroundColor: UIColor, textColor: UIColor) = {
            switch type {
            case .success:
                return ("Rate The Service", "hand.thumbsup.fill", UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1.0), .white)
            case .info:
                return ("Track Location", "mappin.circle.fill", UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1.0), .white)
            case .error, .fail, .accept, .location:
                return ("View Request Details", "doc.text.fill", UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1.0), .white)
            case .message:
                return ("View Message", "envelope.fill", UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1.0), .white)
            }
        }()
        
        // Configure button with icon
      

        var configuration = UIButton.Configuration.filled()
        configuration.title = config.title
        
        configuration.image = UIImage(systemName: config.icon)
        configuration.imagePlacement = .leading
        configuration.imagePadding = 12
        configuration.baseBackgroundColor = UIColor(named: "#fbfbfb")
        configuration.baseForegroundColor = config.textColor
        configuration.cornerStyle = .medium
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
        
        // change font size
        configuration.titleTextAttributesTransformer =
           UIConfigurationTextAttributesTransformer { incoming in
             var outgoing = incoming
               outgoing.font = UIFont.systemFont(ofSize: 14, weight: .bold)
             return outgoing
         }
        actionButton.configuration = configuration
    }
    
    @objc private func actionButtonTapped() {
        if let actionUrl = actionUrlString {
            actionCallback?(actionUrl)
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if selected {
            UIView.animate(withDuration: 0.1) {
                self.containerView.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
            }
        } else {
            UIView.animate(withDuration: 0.1) {
                self.containerView.transform = .identity
            }
        }
    }
}
