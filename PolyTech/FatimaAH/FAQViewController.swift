import UIKit
import FirebaseFirestore

// MARK: - Models
struct FAQRow: Hashable {
    // id: unique identifier for each FAQRow.
    // Used by Swift when comparing/Hashing items (useful for updates, diffable data sources, etc.)
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

// MARK: - FAQ Screen
 class FAQViewController: UIViewController {

    // MARK: UI Outlets
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var getHelpButton: UIButton!

    // MARK: Data
    private var sections: [FAQSection] = []
    private var visibleSections: [FAQSection] = []

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadFAQData()
        setupGetHelpBtn()

        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(goBack)
        )
        backButton.tintColor = .background
        navigationItem.leftBarButtonItem = backButton
    }

    @objc private func goBack() {
        navigationController?.popViewController(animated: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: UI Setup
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

    // MARK: Get Help Navigation
    private func setupGetHelpBtn() {
        getHelpButton.isUserInteractionEnabled = true
        getHelpButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(helpBtnTapped)))
    }

    @objc private func helpBtnTapped() {
        let sb = UIStoryboard(name: "GetHelp", bundle: nil)
        guard let vc = sb.instantiateViewController(withIdentifier: "HelpPageViewController") as? HelpPageViewController else { return }
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: Data (Firestore Fetch)
    private func loadFAQData() {
        let db = Firestore.firestore()

        // Document IDs you want to fetch (in order)
        let documentIDs = ["1", "2", "3", "4", "5", "6", "7"]

        var faqRows: [FAQRow] = []
        let group = DispatchGroup()

        for docID in documentIDs {
            group.enter()

            db.collection("FAQ").document(docID).getDocument { snapshot, error in
                defer { group.leave() }

                if let error = error {
                    print("Error fetching FAQ doc \(docID): \(error.localizedDescription)")
                    return
                }

                guard let data = snapshot?.data() else {
                    print("FAQ doc \(docID) has no data")
                    return
                }

                let question = (data["Title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                let answer   = (data["Description"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)

                faqRows.append(
                    FAQRow(
                        question: question?.isEmpty == false ? question! : "(No Title)",
                        answer: answer?.isEmpty == false ? answer! : "(No Description)"
                    )
                )
            }
        }

        // Update UI once ALL documents are fetched
        group.notify(queue: .main) {
            self.sections = [
                FAQSection(title: "General", isCollapsed: false, rows: faqRows)
            ]
            self.visibleSections = self.sections
            self.tableView.reloadData()
        }
    }

    // MARK: Expand / Collapse
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

    // MARK: Search
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

// MARK: - Table (DataSource & Delegate)
extension FAQViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int { visibleSections.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        visibleSections[section].isCollapsed ? 0 : visibleSections[section].rows.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = FAQSectionHeaderView()
        header.configure(title: visibleSections[section].title,
                         isCollapsed: visibleSections[section].isCollapsed)
        header.onTap = { [weak self] in self?.toggleSectionCollapse(section) }
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 44 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FAQCell.reuseID, for: indexPath) as! FAQCell
        let item = visibleSections[indexPath.section].rows[indexPath.row]
        cell.configure(question: item.question, answer: item.answer, expanded: item.isExpanded)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        toggleRowExpand(section: indexPath.section, row: indexPath.row)
    }
}

// MARK: - SearchBar Delegate
extension FAQViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) { applySearch(searchText) }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) { searchBar.resignFirstResponder() }
}

// MARK: - Section Header View
final class FAQSectionHeaderView: UIView {
    private let titleLabel = UILabel()
    private let chevron = UIImageView()
    var onTap: (() -> Void)?

    override init(frame: CGRect) { super.init(frame: frame); setup() }
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }

    private func setup() {
        backgroundColor = .clear

        let container = UIView()
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

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))
    }

    func configure(title: String, isCollapsed: Bool) {
        titleLabel.text = title
        chevron.image = isCollapsed ? UIImage(systemName: "chevron.down") : UIImage(systemName: "chevron.up")
    }

    @objc private func didTap() { onTap?() }
}

// MARK: - FAQ Cell
final class FAQCell: UITableViewCell {

    static let reuseID = "FAQCell"

    private let cardView = UIView()
    private let questionLabel = UILabel()
    private let answerLabel = UILabel()
    private let chevron = UIImageView()

    private var answerTopConstraint: NSLayoutConstraint!
    private var collapsedBottomConstraint: NSLayoutConstraint!
    private var expandedBottomConstraint: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        cardView.backgroundColor = .background
        cardView.layer.cornerRadius = 12
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = UIColor.systemGray5.cgColor
        cardView.translatesAutoresizingMaskIntoConstraints = false

        questionLabel.numberOfLines = 0
        questionLabel.font = .systemFont(ofSize: 14, weight: .medium)
        questionLabel.textColor = .onBackground
        questionLabel.translatesAutoresizingMaskIntoConstraints = false

        answerLabel.numberOfLines = 0
        answerLabel.font = .systemFont(ofSize: 13, weight: .regular)
        answerLabel.textColor = .onBackground
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
            answerLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14)
        ])

        answerTopConstraint = answerLabel.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: 0)
        answerTopConstraint.isActive = true

        collapsedBottomConstraint = questionLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12)
        collapsedBottomConstraint.isActive = true

        expandedBottomConstraint = answerLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12)
        expandedBottomConstraint.isActive = false

        answerLabel.isHidden = true
    }

    func configure(question: String, answer: String, expanded: Bool) {
        questionLabel.text = question
        answerLabel.text = answer

        if expanded {
            answerLabel.isHidden = false
            answerTopConstraint.constant = 10
            collapsedBottomConstraint.isActive = false
            expandedBottomConstraint.isActive = true
            chevron.image = UIImage(systemName: "chevron.up")
        } else {
            answerLabel.isHidden = true
            answerTopConstraint.constant = 0
            expandedBottomConstraint.isActive = false
            collapsedBottomConstraint.isActive = true
            chevron.image = UIImage(systemName: "chevron.down")
        }
    }
}
