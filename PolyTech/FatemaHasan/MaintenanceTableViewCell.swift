//
//  MaintenanceTableViewCell.swift
//  PolyTech
//
//  Created by BP-19-130-15 on 28/12/2025.
//
import UIKit

class MaintenanceTableViewCell: UITableViewCell {
    
    // MARK: - UI Components
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.borderWidth = 0.8
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
    
    private let titleLabel = UILabel()
    private let timeLabel = UILabel()
    private let locationLabel = UILabel()
    private let timeIconImageView = UIImageView()
    private let messageLabel = UILabel()
    
    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // ✅ NEW: Edit button
    private let editButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Edit", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Properties
    
    private var actionUrlString: String?
    private var actionCallback: ((String) -> Void)?
    private var editCallback: (() -> Void)?   // ✅ NEW callback
    
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
        
        contentView.addSubview(containerView)
        containerView.addSubview(iconContainerView)
        iconContainerView.addSubview(iconImageView)
        containerView.addSubview(contentStackView)
        
        headerStackView.addArrangedSubview(titleLabel)
        headerStackView.addArrangedSubview(timeIconImageView)
        headerStackView.addArrangedSubview(locationLabel)
        
        contentStackView.addArrangedSubview(headerStackView)
        contentStackView.addArrangedSubview(messageLabel)
        contentStackView.addArrangedSubview(timeLabel)
        contentStackView.addArrangedSubview(actionButton)
        contentStackView.addArrangedSubview(editButton)   // ✅ Add Edit button
        
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        editButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            iconContainerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            iconContainerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            iconContainerView.widthAnchor.constraint(equalToConstant: 60),
            iconContainerView.heightAnchor.constraint(equalToConstant: 60),
            
            iconImageView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 32),
            iconImageView.heightAnchor.constraint(equalToConstant: 32),
            
            timeIconImageView.widthAnchor.constraint(equalToConstant: 20),
            timeIconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            contentStackView.leadingAnchor.constraint(equalTo: iconContainerView.trailingAnchor, constant: 16),
            contentStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            contentStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            contentStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - Configuration
    
    func configure(with item: NotificationModel,
                   actionCallback: ((String) -> Void)? = nil,
                   editCallback: (() -> Void)? = nil) {
        titleLabel.text = item.title
        messageLabel.text = item.message
        timeLabel.text = item.displayTime
        locationLabel.text = item.room
        self.actionCallback = actionCallback
        self.editCallback = editCallback   // ✅ store callback
        self.actionUrlString = item.actionUrl
        
        configureIcon(for: item.type)
        
        if let actionUrl = item.actionUrl {
            actionButton.isHidden = false
            configureActionButton(for: item.type, actionUrl: actionUrl)
        } else {
            actionButton.isHidden = true
        }
    }
    
    private func configureIcon(for type: NotificationModel.NotificationType) {
        let config: (icon: String, backgroundColor: UIColor) = {
            switch type {
            case .success: return ("checkmark", UIColor.systemBlue)
            case .error, .fail: return ("xmark", UIColor.systemRed)
            case .info: return ("mappin.and.ellipse", UIColor.systemGreen)
            case .message: return ("envelope.fill", UIColor.systemOrange)
            case .accept: return ("checkmark", UIColor.systemTeal)
            case .location: return ("person.badge.plus.fill", UIColor.systemPurple)
            }
        }()
        
        iconImageView.image = UIImage(systemName: config.icon)
        iconContainerView.backgroundColor = config.backgroundColor
    }
    
    private func configureActionButton(for type: NotificationModel.NotificationType, actionUrl: String) {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Action"
        configuration.image = UIImage(systemName: "arrow.right.circle.fill")
        configuration.imagePlacement = .leading
        configuration.imagePadding = 12
        configuration.baseBackgroundColor = .systemGray6
        configuration.baseForegroundColor = .systemBlue
        configuration.cornerStyle = .medium
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
        
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
    
    @objc private func editButtonTapped() {
        editCallback?()   // ✅ triggers navigation to ReturnInventory
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
