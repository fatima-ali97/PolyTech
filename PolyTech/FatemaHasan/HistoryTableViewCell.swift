import UIKit

class HistoryTableViewCell: UITableViewCell {
    
    // MARK: - Callback
    private var feedbackCallback: (() -> Void)?
    
    // MARK: - UI
    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.layer.borderWidth = 0.8
        v.layer.borderColor = UIColor.systemGray4.cgColor
        v.layer.cornerRadius = 16
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.textColor = .label
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let locationLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let categoryLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .regular)
        l.textColor = .secondaryLabel
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let timeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .regular)
        l.textColor = .systemGray2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let feedbackButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Feedback"
        config.image = UIImage(systemName: "star.fill")
        config.imagePlacement = .leading
        config.imagePadding = 8
        config.baseBackgroundColor = UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1.0) // deep blue
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
        let b = UIButton(type: .system)
        b.configuration = config
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    private let contentStackView: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 8
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()
    
    // MARK: - Init
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
        selectionStyle = .default
        
        contentView.addSubview(containerView)
        containerView.addSubview(contentStackView)
        
        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(locationLabel)
        contentStackView.addArrangedSubview(categoryLabel)
        contentStackView.addArrangedSubview(timeLabel)
        contentStackView.addArrangedSubview(feedbackButton)
        
        feedbackButton.addTarget(self, action: #selector(feedbackTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            // Content stack
            contentStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            contentStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            contentStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            contentStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
        ])
    }
    
    // MARK: - Configure (Maintenance)
    func configure(with item: MaintenanceRequestModel,
                   feedbackCallback: (() -> Void)?) {
        titleLabel.text = item.requestName
        locationLabel.text = "📍 \(item.location)"
        categoryLabel.text = "Category: \(item.category.replacingOccurrences(of: "_", with: " ").capitalized)"
        timeLabel.text = item.createdTimeText
        self.feedbackCallback = feedbackCallback
    }
    
    // MARK: - Configure (Inventory)
    func configure(with item: Inventory,
                   feedbackCallback: (() -> Void)?) {
        titleLabel.text = item.requestName
        locationLabel.text = "📍 \(item.location)"
        categoryLabel.text = "\(item.itemName) — Qty: \(item.quantity)"
        timeLabel.text = item.createdTimeText
        self.feedbackCallback = feedbackCallback
    }
    
    // MARK: - Action
    @objc private func feedbackTapped() {
        feedbackCallback?()
    }
    
    // MARK: - Feedback (optional)
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        UIView.animate(withDuration: 0.1) {
            self.containerView.transform = selected ? CGAffineTransform(scaleX: 0.97, y: 0.97) : .identity
        }
    }
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        UIView.animate(withDuration: 0.1) {
            self.containerView.alpha = highlighted ? 0.85 : 1.0
        }
    }
}
