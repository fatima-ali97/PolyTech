import UIKit

class MaintenanceTableViewCell: UITableViewCell {
    
    // MARK: - Callbacks
    private var viewCallback: (() -> Void)?
    private var editCallback: (() -> Void)?
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.borderWidth = 0.8
        view.layer.borderColor = UIColor.systemGray4.cgColor
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let requestNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.numberOfLines = 2
        return label
    }()
    
    private let locationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let categoryLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let urgencyLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.layer.cornerRadius = 12
        label.layer.masksToBounds = true
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .systemGray2
        return label
    }()
    
    private let buttonsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let viewButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "View"
        config.image = UIImage(systemName: "eye.fill")
        config.imagePlacement = .leading
        config.imagePadding = 6
        config.baseBackgroundColor = UIColor(red: 0.85, green: 0.9, blue: 0.95, alpha: 1.0)
        config.baseForegroundColor = UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1.0)
        config.cornerStyle = .medium
        return UIButton(configuration: config)
    }()
    
    private let editButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Edit"
        config.image = UIImage(systemName: "pencil")
        config.imagePlacement = .leading
        config.imagePadding = 6
        config.baseBackgroundColor = UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1.0)
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        return UIButton(configuration: config)
    }()
    
    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    required init?(coder: NSCoder) { super.init(coder: coder); setupUI() }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        
        let stack = UIStackView(arrangedSubviews: [
            requestNameLabel,
            locationLabel,
            categoryLabel,
            urgencyLabel,
            timeLabel,
            buttonsStackView
        ])
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(stack)
        buttonsStackView.addArrangedSubview(viewButton)
        buttonsStackView.addArrangedSubview(editButton)
        
        viewButton.addTarget(self, action: #selector(viewTapped), for: .touchUpInside)
        editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            stack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }
    
    // MARK: - Configure
    func configure(with item: MaintenanceRequestModel,
                   viewCallback: (() -> Void)?,
                   editCallback: (() -> Void)?) {
        requestNameLabel.text = item.requestName
        locationLabel.text = "📍 \(item.location)"
        categoryLabel.text = "Category: \(item.category.capitalized)"
        urgencyLabel.text = item.urgency.rawValue.capitalized
        timeLabel.text = item.formattedDate
        self.viewCallback = viewCallback
        self.editCallback = editCallback
        
        switch item.urgency {
        case .high:   urgencyLabel.backgroundColor = .systemRed
        case .medium: urgencyLabel.backgroundColor = .systemOrange
        case .low:    urgencyLabel.backgroundColor = .systemGreen
        }
    }
    
    // MARK: - Actions
    @objc private func viewTapped() { viewCallback?() }
    @objc private func editTapped() { editCallback?() }
}
