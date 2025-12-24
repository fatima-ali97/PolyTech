
import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct FAQSection {
    let question: String
    let answer: String
    var isCollapsed: Bool
}

final class FAQViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    private let db = Firestore.firestore()
    private var sections: [FAQSection] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self

        // مهم عشان نفس ستايل الريبو
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.backgroundColor = .systemGroupedBackground

        // تسجيل Cells
        tableView.register(FAQQuestionCell.self, forCellReuseIdentifier: FAQQuestionCell.reuseId)
        tableView.register(FAQAnswerCell.self, forCellReuseIdentifier: FAQAnswerCell.reuseId)

        fetchFAQ()
    }

    private func fetchFAQ() {
        db.collection("FAQ")
            .limit(to: 5)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("Firebase error:", error.localizedDescription)
                    return
                }

                self.sections = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    guard
                        let title = data["Title"] as? String,
                        let description = data["Description"] as? String
                    else { return nil }

                    return FAQSection(question: title, answer: description, isCollapsed: true)
                } ?? []

                DispatchQueue.main.async { self.tableView.reloadData() }
            }
    }
}

extension FAQViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { sections.count }

    // Row 0 = Question (دائمًا موجود)
    // Row 1 = Answer (يظهر فقط إذا السكشن مفتوح)
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].isCollapsed ? 1 : 2
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: FAQQuestionCell.reuseId,
                                                     for: indexPath) as! FAQQuestionCell
            let item = sections[indexPath.section]
            cell.configure(title: item.question, collapsed: item.isCollapsed)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: FAQAnswerCell.reuseId,
                                                     for: indexPath) as! FAQAnswerCell
            cell.configure(text: sections[indexPath.section].answer)
            return cell
        }
    }
}

extension FAQViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // نفس الريبو: الضغط على السؤال (Row 0) يفتح/يسكر
        guard indexPath.row == 0 else { return }

        sections[indexPath.section].isCollapsed.toggle()

        tableView.performBatchUpdates({
            tableView.reloadSections(IndexSet(integer: indexPath.section), with: .automatic)
        })
    }

    // عشان المسافات مثل grouped
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 10 }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? { UIView() }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { 0.01 }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? { UIView() }
}

final class FAQQuestionCell: UITableViewCell {

    static let reuseId = "FAQQuestionCell"

    private let titleLabel = UILabel()
    private let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        selectionStyle = .default
        accessoryType = .none
        backgroundColor = .secondarySystemGroupedBackground

        titleLabel.numberOfLines = 0
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)

        chevron.tintColor = .secondaryLabel
        chevron.contentMode = .scaleAspectFit

        contentView.addSubview(titleLabel)
        contentView.addSubview(chevron)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        chevron.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -12),

            chevron.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            chevron.widthAnchor.constraint(equalToConstant: 14),
            chevron.heightAnchor.constraint(equalToConstant: 14)
        ])
    }

    func configure(title: String, collapsed: Bool) {
        titleLabel.text = title
        UIView.animate(withDuration: 0.2) {
            self.chevron.transform = collapsed ? .identity : CGAffineTransform(rotationAngle: .pi/2)
        }
    }
}

final class FAQAnswerCell: UITableViewCell {

    static let reuseId = "FAQAnswerCell"

    private let bodyLabel = UILabel()

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
        backgroundColor = .secondarySystemGroupedBackground

        bodyLabel.numberOfLines = 0
        bodyLabel.font = .systemFont(ofSize: 15, weight: .regular)
        bodyLabel.textColor = .label

        contentView.addSubview(bodyLabel)
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            bodyLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            bodyLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14),
            bodyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            bodyLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }

    func configure(text: String) {
        bodyLabel.text = text
    }
}
