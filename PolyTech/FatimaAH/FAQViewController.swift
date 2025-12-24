import UIKit

struct FAQRow: Hashable {
    let id = UUID()
    let question: String
    let answer: String
    var isExpanded: Bool = false
}

struct FAQSection {
    let title: String
    var isCollapsed: Bool = false
    var rows: [FAQRow]
}

final class FAQViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var getHelpButton: UIButton!

    // Original data (never changed)
    private var sections: [FAQSection] = []

    // Data shown in table (filtered or not)
    private var visibleSections: [FAQSection] = []

    private var isSearching: Bool {
        let text = (searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return !text.isEmpty
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        buildFAQDataSameAsYourScreenshot()
        visibleSections = sections

        tableView.reloadData()
    }

    private func setupUI() {
        searchBar.delegate = self

        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80

        tableView.register(FAQCell.self, forCellReuseIdentifier: FAQCell.reuseID)

        getHelpButton.layer.cornerRadius = 14
        getHelpButton.clipsToBounds = true
    }

    private func buildFAQDataSameAsYourScreenshot() {

        let generalRows: [FAQRow] = [
            FAQRow(
                question: "Banner login",
                answer:
"""
1. Visit Bahrain Polytechnic website.
2. Go to the Banner / Student tab.
3. Enter Student ID and password.
If you still can’t login, reset your Banner password or contact IT Help.
"""
            ),
            FAQRow(
                question: "Authenticator App setup",
                answer:
"""
1. Download Microsoft Authenticator (iOS/Android).
2. Login with your polytechnic email.
3. Scan the QR code provided by the system.
4. Approve the sign-in when requested.
If the code/approval does not work, remove the account from the app and add it again.
"""
            ),
            FAQRow(
                question: "VMware virtual machine Starting Error",
                answer:
"""
Steps to fix:
1) Open VMware Workstation Player.
2) Right-click on the virtual machine > Settings.
3) Go to Options.
4) Check the working directory path (where your VM is stored).
5) Open the VM folder using File Explorer.
6) Find the file with extension .vmx.
7) Edit it with Notepad (or any text editor).
8) Disable/Change the related setting if needed (based on your error message).
9) Save the file.
10) Restart the Virtual Machine.
If the error continues, reinstall VMware or contact support.
"""
            ),
            FAQRow(
                question: "Password reset on computer",
                answer:
"""
1) Click Ctrl+Alt+Delete.
2) Choose Change a password.
3) Enter your current password.
4) Enter a new password that matches the policy:
- At least 8 characters
- Includes uppercase + lowercase + number
5) Confirm and save.
If you forgot your password completely, contact IT Help.
"""
            ),
            FAQRow(
                question: "Moodle login",
                answer:
"""
1) Visit Moodle website.
2) Click Login.
3) Use your Polytechnic email/username and password.
4) If you can’t login:
- Reset password
- Clear browser cache
- Try another browser
- Contact IT Help
"""
            )
        ]

        sections = [
            FAQSection(title: "General", isCollapsed: false, rows: generalRows)
        ]
    }

    @IBAction func getHelpTapped(_ sender: UIButton) {
        let sb = UIStoryboard(name: "HelpPage", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "HelpPageVC")
        navigationController?.pushViewController(vc, animated: true)
    }

    private func toggleSectionCollapse(_ sectionIndex: Int) {
        guard visibleSections.indices.contains(sectionIndex) else { return }
        visibleSections[sectionIndex].isCollapsed.toggle()
        tableView.reloadSections(IndexSet(integer: sectionIndex), with: .automatic)
    }

    private func toggleRowExpand(section: Int, row: Int) {
        guard visibleSections.indices.contains(section),
              visibleSections[section].rows.indices.contains(row) else { return }

        visibleSections[section].rows[row].isExpanded.toggle()

        UIView.performWithoutAnimation {
            tableView.beginUpdates()
            tableView.endUpdates()
        }

        tableView.reloadRows(at: [IndexPath(row: row, section: section)], with: .automatic)
    }

    private func applySearch(_ query: String) {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard !q.isEmpty else {
            visibleSections = sections
            tableView.reloadData()
            return
        }

        visibleSections = sections.map { section in
            var s = section
            s.rows = section.rows.filter {
                $0.question.lowercased().contains(q) || $0.answer.lowercased().contains(q)
            }
            s.isCollapsed = false
            return s
        }.filter { !$0.rows.isEmpty }

        tableView.reloadData()
    }
}

extension FAQViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        visibleSections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        visibleSections[section].isCollapsed ? 0 : visibleSections[section].rows.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = FAQSectionHeaderView()
        header.configure(
            title: visibleSections[section].title,
            isCollapsed: visibleSections[section].isCollapsed
        )
        header.onTap = { [weak self] in
            self?.toggleSectionCollapse(section)
        }
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        44
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: FAQCell.reuseID, for: indexPath) as! FAQCell
        let item = visibleSections[indexPath.section].rows[indexPath.row]

        cell.configure(question: item.question, answer: item.answer, expanded: item.isExpanded)

        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        toggleRowExpand(section: indexPath.section, row: indexPath.row)
    }
}

extension FAQViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        applySearch(searchText)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

final class FAQSectionHeaderView: UIView {

    private let titleLabel = UILabel()
    private let chevron = UIImageView(image: UIImage(systemName: "chevron.down"))
    var onTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear

        let container = UIView()
        container.backgroundColor = .clear
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)

        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        chevron.tintColor = .secondaryLabel
        chevron.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(titleLabel)
        container.addSubview(chevron)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            chevron.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            chevron.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 16),
            chevron.heightAnchor.constraint(equalToConstant: 16)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        addGestureRecognizer(tap)
    }

    func configure(title: String, isCollapsed: Bool) {
        titleLabel.text = title
        UIView.animate(withDuration: 0.2) {
            self.chevron.transform = isCollapsed ? CGAffineTransform.identity : CGAffineTransform(rotationAngle: .pi)
        }
    }

    @objc private func didTap() {
        onTap?()
    }
}

final class FAQCell: UITableViewCell {

    static let reuseID = "FAQCell"

    private let cardView = UIView()
    private let questionLabel = UILabel()
    private let answerLabel = UILabel()
    private let chevron = UIImageView(image: UIImage(systemName: "chevron.down"))

    private var answerTopConstraint: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        contentView.backgroundColor = .clear

        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 12
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = UIColor.systemGray5.cgColor
        cardView.translatesAutoresizingMaskIntoConstraints = false

        questionLabel.numberOfLines = 0
        questionLabel.font = .systemFont(ofSize: 14, weight: .medium)
        questionLabel.textColor = .label
        questionLabel.translatesAutoresizingMaskIntoConstraints = false

        answerLabel.numberOfLines = 0
        answerLabel.font = .systemFont(ofSize: 13, weight: .regular)
        answerLabel.textColor = .secondaryLabel
        answerLabel.translatesAutoresizingMaskIntoConstraints = false

        chevron.tintColor = .secondaryLabel
        chevron.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(cardView)
        cardView.addSubview(questionLabel)
        cardView.addSubview(chevron)
        cardView.addSubview(answerLabel)

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            questionLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            questionLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            questionLabel.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -10),

            chevron.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            chevron.centerYAnchor.constraint(equalTo: questionLabel.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 16),
            chevron.heightAnchor.constraint(equalToConstant: 16),

            answerLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            answerLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            answerLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),
        ])

        answerTopConstraint = answerLabel.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: 10)
        answerTopConstraint.isActive = true
    }

    func configure(question: String, answer: String, expanded: Bool) {
        questionLabel.text = question
        answerLabel.text = answer
        answerLabel.isHidden = !expanded

        UIView.animate(withDuration: 0.2) {
            self.chevron.transform = expanded ? CGAffineTransform(rotationAngle: .pi) : .identity
        }
    }
}
