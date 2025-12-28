import UIKit

final class ItemsViewController: UIViewController {

    // MARK: - Properties

    private var items: [Item] = []
    private let tableView = UITableView()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Items"
        view.backgroundColor = .systemBackground

        setupTableView()
        items = generateSampleData()
    }

    // MARK: - Setup

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(
            ItemTableViewCell.self,
            forCellReuseIdentifier: ItemTableViewCell.reuseIdentifier
        )
        tableView.dataSource = self
        tableView.delegate = self

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Sample Data

    private func generateSampleData() -> [Item] {
        return (1...10).map {
            Item(id: UUID(), title: "Sample Item \($0)")
        }
    }
}
extension ItemsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ItemTableViewCell.reuseIdentifier,
            for: indexPath
        ) as? ItemTableViewCell else {
            return UITableViewCell()
        }

        let item = items[indexPath.row]
        cell.configure(with: item)

        // Button actions
        cell.onAddTapped = {
            print("Add tapped for \(item.title)")
        }

        cell.onEditTapped = {
            print("Edit tapped for \(item.title)")
        }

        cell.onDeleteTapped = { [weak self] in
            self?.items.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }

        return cell
    }
}

