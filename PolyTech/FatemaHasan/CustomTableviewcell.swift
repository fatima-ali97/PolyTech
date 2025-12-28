import UIKit

final class ItemTableViewCell: UITableViewCell {

    static let reuseIdentifier = "ItemTableViewCell"



    private let titleLabel = UILabel()
    private let addButton = UIButton(type: .system)
    private let editButton = UIButton(type: .system)
    private let deleteButton = UIButton(type: .system)



    var onAddTapped: (() -> Void)?
    var onEditTapped: (() -> Void)?
    var onDeleteTapped: (() -> Void)?



    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration

    func configure(with item: Item) {
        titleLabel.text = item.title
    }

    // MARK: - Setup

    private func setupUI() {
        selectionStyle = .none

        addButton.setTitle("Add", for: .normal)
        editButton.setTitle("Edit", for: .normal)
        deleteButton.setTitle("Delete", for: .normal)

        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)

        let buttonStack = UIStackView(arrangedSubviews: [addButton, editButton, deleteButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12

        let mainStack = UIStackView(arrangedSubviews: [titleLabel, buttonStack])
        mainStack.axis = .vertical
        mainStack.spacing = 8
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    // MARK: - Actions

    @objc private func addTapped() {
        onAddTapped?()
    }

    @objc private func editTapped() {
        onEditTapped?()
    }

    @objc private func deleteTapped() {
        onDeleteTapped?()
    }
}
