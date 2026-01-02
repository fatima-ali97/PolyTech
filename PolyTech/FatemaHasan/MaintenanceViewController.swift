import UIKit
import FirebaseFirestore
import FirebaseAuth

class MaintenanceViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Data
    private var maintenanceItems: [MaintenanceRequestModel] = []
    private var filteredItems: [MaintenanceRequestModel] = []   // used for search results
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private let currentUserId = UserDefaults.standard.string(forKey: "userId")
    
    // MARK: - UI Helpers
    private let refreshControl = UIRefreshControl()
    private let emptyStateView = EmptyStateView()
    private let searchController = UISearchController(searchResultsController: nil)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationButtons()
        setupTableView()
        setupEmptyState()
        setupSearch()
        attachMaintenanceListener()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if listener == nil { attachMaintenanceListener() }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        listener?.remove()
        listener = nil
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "Maintenance"
        navigationController?.navigationBar.prefersLargeTitles = true // match Inventory large title
        view.backgroundColor = .systemBackground
    }
    
    private func setupNavigationButtons() {
        let addBarButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addTapped)
        )
        navigationItem.rightBarButtonItem = addBarButton
    }
    
    private func setupSearch() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search maintenance requests"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    @objc private func addTapped() {
        let storyboard = UIStoryboard(name: "NewMaintenance", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "NewMaintenanceViewController")
                as? NewMaintenanceViewController else {
            print("❌ NewMaintenanceViewController not found or wrong class")
            return
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func setupTableView() {
        guard let tableView = tableView else {
            print("ERROR: tableView outlet is not connected!")
            return
        }
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        tableView.register(MaintenanceTableViewCell.self, forCellReuseIdentifier: "MaintenanceCell")
        
        refreshControl.addTarget(self, action: #selector(refreshMaintenanceItems), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    private func setupEmptyState() {
        emptyStateView.configure(
            title: "No Maintenance Requests",
            message: "Tap '+' to create a new maintenance request."
        )
        emptyStateView.isHidden = true
        view.addSubview(emptyStateView)
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }
    
    // MARK: - Real-time listener
    private func attachMaintenanceListener() {
        guard listener == nil else { return }
        guard let uid = currentUserId, !uid.isEmpty else {
            print("❌ currentUserId is nil or empty")
            filteredItems = []
            updateEmptyState()
            return
        }
        
        listener = db.collection("maintenanceRequest")
            .whereField("userId", isEqualTo: uid)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("❌ Error fetching maintenance items: \(error.localizedDescription)")
                    self.maintenanceItems.removeAll()
                    self.applySearchFilter()
                    return
                }
                guard let documents = snapshot?.documents else {
                    self.maintenanceItems.removeAll()
                    self.applySearchFilter()
                    return
                }
                
                self.maintenanceItems = documents.compactMap {
                    MaintenanceRequestModel(dictionary: $0.data(), id: $0.documentID)
                }
                
                self.maintenanceItems.sort { $0.createdAt.dateValue() > $1.createdAt.dateValue() }
                self.applySearchFilter()
            }
    }
    
    // MARK: - Pull to refresh
    @objc private func refreshMaintenanceItems() {
        listener?.remove()
        listener = nil
        attachMaintenanceListener()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.refreshControl.endRefreshing()
        }
    }
    
    private func updateEmptyState() {
        guard let tableView = tableView else { return }
        let isEmpty = filteredItems.isEmpty
        emptyStateView.isHidden = !isEmpty
        tableView.isHidden = isEmpty
    }
    
    private func applySearchFilter() {
        if let query = searchController.searchBar.text, !query.isEmpty {
            let q = query.lowercased()
            filteredItems = maintenanceItems.filter {
                $0.requestName.lowercased().contains(q) ||
                $0.category.lowercased().contains(q) ||
                $0.location.lowercased().contains(q) ||
                $0.urgency.rawValue.lowercased().contains(q)
            }
        } else {
            filteredItems = maintenanceItems
        }
        DispatchQueue.main.async {
            self.tableView?.reloadData()
            self.updateEmptyState()
        }
    }
    
    // MARK: - Details Popup
    private func showDetailsPopup(for item: MaintenanceRequestModel) {
        let alertVC = UIViewController()
        alertVC.view.backgroundColor = .systemBackground
        alertVC.preferredContentSize = CGSize(width: 320, height: 420)
        
        let titleLabel = UILabel()
        titleLabel.text = "Maintenance Details"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textAlignment = .center
        
        let detailsLabel = UILabel()
        detailsLabel.numberOfLines = 0
        detailsLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        detailsLabel.textColor = .label
        detailsLabel.text = """
        🛠️ Request: \(item.requestName)
        📍 Location: \(item.location)
        🏷️ Category: \(item.category.capitalized)
        ⚡ Urgency: \(item.urgency.rawValue.capitalized)
        🕐 Created: \(item.formattedDate)
        """
        
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
        imageView.backgroundColor = .secondarySystemBackground
        
        if let imageUrl = item.imageUrl, let url = URL(string: imageUrl) {
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                    DispatchQueue.main.async { imageView.image = image }
                }
            }
        }
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, detailsLabel, imageView])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        alertVC.view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: alertVC.view.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: alertVC.view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: alertVC.view.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: alertVC.view.bottomAnchor, constant: -20),
            imageView.heightAnchor.constraint(equalToConstant: 180)
        ])
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        alert.setValue(alertVC, forKey: "contentViewController")
        alert.addAction(UIAlertAction(title: "Close", style: .cancel))
        present(alert, animated: true)
    }
    
    private func navigateToEdit(item: MaintenanceRequestModel) {
        let storyboard = UIStoryboard(name: "NewMaintenance", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "NewMaintenanceViewController")
                as? NewMaintenanceViewController else {
            print("❌ NewMaintenanceViewController not found or wrong class")
            return
        }
        vc.requestToEdit = item
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func deleteItem(at indexPath: IndexPath) {
        let item = filteredItems[indexPath.row] // match visible list
        let alert = UIAlertController(
            title: "Delete Maintenance",
            message: "Are you sure you want to delete this maintenance request?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.performDelete(item: item)
        })
        present(alert, animated: true)
    }
    
    private func performDelete(item: MaintenanceRequestModel) {
        db.collection("maintenanceRequest")
            .document(item.id)
            .delete { error in
                if let error = error {
                    print("❌ Error deleting item: \(error.localizedDescription)")
                } else {
                    print("✅ Item deleted successfully")
                }
            }
    }
}

// MARK: - UITableViewDataSource
extension MaintenanceViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredItems.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "MaintenanceCell",
            for: indexPath
        ) as? MaintenanceTableViewCell else {
            return UITableViewCell()
        }
        
        let item = filteredItems[indexPath.row]
        cell.configure(
            with: item,
            viewCallback: { [weak self] in self?.showDetailsPopup(for: item) },
            editCallback: { [weak self] in self?.navigateToEdit(item: item) }
        )
        return cell
    }
}

// MARK: - UITableViewDelegate
extension MaintenanceViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        showDetailsPopup(for: filteredItems[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {
        let item = filteredItems[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.deleteItem(at: indexPath)
            completion(true)
        }
        deleteAction.image = UIImage(systemName: "trash")
        
        let editAction = UIContextualAction(style: .normal, title: "Edit") { [weak self] _, _, completion in
            self?.navigateToEdit(item: item)
            completion(true)
        }
        editAction.backgroundColor = .systemBlue
        editAction.image = UIImage(systemName: "pencil")
        
        let viewAction = UIContextualAction(style: .normal, title: "Details") { [weak self] _, _, completion in
            self?.showDetailsPopup(for: item)
            completion(true)
        }
        viewAction.backgroundColor = .systemGreen
        viewAction.image = UIImage(systemName: "info.circle")
        
        return UISwipeActionsConfiguration(actions: [deleteAction, editAction, viewAction])
    }
}

// MARK: - UISearchResultsUpdating
extension MaintenanceViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        applySearchFilter()
    }
}
