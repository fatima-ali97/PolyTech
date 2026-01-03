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
        view.backgroundColor = .clear
        view.layer.borderWidth = 1.5
        view.layer.borderColor = UIColor.systemGray4.cgColor
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
        iv.tintColor = .white
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
        label.textColor = .label
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let timeIconImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "mappin.circle.fill")
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .accent
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let locationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .tertiaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Properties
    
    private var actionUrlString: String?
    private var actionCallback: ((String) -> Void)?
    weak var parentViewController: UIViewController?
    
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
        containerView.addSubview(iconContainerView)
        iconContainerView.addSubview(iconImageView)
        containerView.addSubview(contentStackView)
        
        // Add header with title and location
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
            contentStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            contentStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }
    
    // MARK: - Configuration
    
    func configure(with notification: NotificationModel,
                   parentViewController: UIViewController? = nil,
                   actionCallback: ((String) -> Void)? = nil) {
        titleLabel.text = notification.title
        messageLabel.text = notification.message
        timeLabel.text = notification.displayTime
        locationLabel.text = notification.room
        self.parentViewController = parentViewController
        self.actionCallback = actionCallback
        
        // Set icon based on notification type
        configureIcon(for: notification.type)
        
        // Only show action button for success type
        if notification.type == .success {
            actionButton.isHidden = false
            self.actionUrlString = "serviceFeedback"
            configureActionButton(for: notification.type, actionUrl: "serviceFeedback")
        } else {
            actionButton.isHidden = true
            self.actionUrlString = nil
        }
        
        // Update border color based on read status
        if notification.isRead {
            containerView.layer.borderColor = UIColor.systemGray4.cgColor
            containerView.layer.borderWidth = 1.0
        } else {
            // Unread notification - use primary color
            containerView.layer.borderColor = UIColor.appPrimary.cgColor
            containerView.layer.borderWidth = 2.0
        }
    }
    
    private func configureIcon(for type: NotificationModel.NotificationType) {
        let config: (icon: String, backgroundColor: UIColor) = {
            switch type {
            case .success:
                return ("checkmark", .accent)
            case .error:
                return ("xmark", .accent)
            case .fail:
                return ("xmark", .accent)
            case .info:
                return ("info", .accent)
            case .message:
                return ("envelope.fill", .accent)
            case .accept:
                return ("checkmark", .accent)
            case .location:
                return ("person.badge.plus.fill", .accent)
            }
        }()
        
        iconImageView.image = UIImage(systemName: config.icon)
        iconContainerView.backgroundColor = config.backgroundColor
    }
    
    private func configureActionButton(for type: NotificationModel.NotificationType, actionUrl: String) {
        let config: (title: String, icon: String, backgroundColor: UIColor, textColor: UIColor) = {
            switch type {
            case .success:
                return ("Rate The Service", "hand.thumbsup.fill", .appPrimary, .onPrimary)
            case .info:
                return ("View Request Info", "info", .appPrimary, .onPrimary)
            case .error, .fail, .accept, .location:
                return ("View Request Details", "doc.text.fill", .appPrimary, .onPrimary)
            case .message:
                return ("View Message", "envelope.fill", .appPrimary, .onPrimary)
            }
        }()
        
        var configuration = UIButton.Configuration.filled()
        configuration.title = config.title
        configuration.image = UIImage(systemName: config.icon)
        configuration.imagePlacement = .leading
        configuration.imagePadding = 8
        configuration.baseBackgroundColor = config.backgroundColor
        configuration.baseForegroundColor = config.textColor
        configuration.cornerStyle = .medium
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
        
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            return outgoing
        }
        
        actionButton.configuration = configuration
    }
    
    @objc private func actionButtonTapped() {
        guard let actionUrl = actionUrlString else { return }
        
        // Call the callback first (for any additional logic)
        actionCallback?(actionUrl)
        
        // Navigate to storyboard
        navigateToStoryboard(actionUrl)
    }
    
    // MARK: - Navigation
    
    private func navigateToStoryboard(_ storyboardName: String) {
        guard let parentVC = parentViewController else {
            print("Error: Parent view controller not set")
            return
        }
        
        // Create storyboard instance
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        
        // Instantiate the initial view controller from the storyboard
        guard let destinationVC = storyboard.instantiateInitialViewController() else {
            print("Error: Could not instantiate initial view controller from storyboard: \(storyboardName)")
            return
        }
        
        // Navigate using the navigation controller if available
        if let navigationController = parentVC.navigationController {
            navigationController.pushViewController(destinationVC, animated: true)
        } else {
            // Present modally if no navigation controller
            destinationVC.modalPresentationStyle = .fullScreen
            parentVC.present(destinationVC, animated: true)
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        messageLabel.text = nil
        timeLabel.text = nil
        locationLabel.text = nil
        actionUrlString = nil
        actionCallback = nil
        actionButton.isHidden = true
        parentViewController = nil
    }
}
