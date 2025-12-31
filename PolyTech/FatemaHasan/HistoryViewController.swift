import UIKit
import FirebaseFirestore

class HistoryViewController: UIViewController {

    @IBOutlet weak var SearchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    private var historyItems: [NotificationModel] = []
    private var filteredItems: [NotificationModel] = []
    private var isSearching = false
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    // TODO: Replace with actual user ID from your auth system
    private let currentUserId = UserDefaults.standard.string(forKey: "userId")
    
    private let refreshControl = UIRefreshControl()
    private let emptyStateView = EmptyStateView()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupTableView()
        setupEmptyState()
        loadHistoryItems()
        
        // ✅ Hook up search bar delegate
        SearchBar.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        listener?.remove()
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "History"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .background
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
        tableView.estimatedRowHeight = 100
        
        tableView.register(InventoryTableViewCell.self, forCellReuseIdentifier: "InventoryCell")
        
        refreshControl.addTarget(self, action: #selector(refreshHistoryItems), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    // MARK: - Empty State
    private func setupEmptyState() {
        guard tableView != nil else {
            print("ERROR: Cannot setup empty state - tableView outlet is not connected!")
            return
        }
        
        emptyStateView.configure(
            title: "No History Items For Now.",
            message: "Once a request status gets updated, we will notify you immediately."
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
    
    // MARK: - Data Loading
    private func loadHistoryItems() {
        print("load history items for userId: \(currentUserId ?? "nil")")
        
        listener = db.collection("Notifications")
            .whereField("userId", isEqualTo: currentUserId ?? "")
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("**Error fetching history items: \(error.localizedDescription)")
                    self.showError("Failed to load history items")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No history items for this user!!")
                    self.updateEmptyState()
                    return
                }
                
                self.historyItems = documents.compactMap { document in
                    let item = NotificationModel(dictionary: document.data(), id: document.documentID)
                    if item == nil {
                        print("Failed to parse document: \(document.documentID)")
                        print("   Data: \(document.data())")
                    }
                    return item
                }
                
                print("Successfully parsed \(self.historyItems.count) history items")
                
                DispatchQueue.main.async {
                    self.tableView?.reloadData()
                    self.updateEmptyState()
                }
            }
    }
    
    @objc private func refreshHistoryItems() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.refreshControl.endRefreshing()
        }
    }
    
    private func updateEmptyState() {
        guard let tableView = tableView else { return }
        emptyStateView.isHidden = !historyItems.isEmpty
        tableView.isHidden = historyItems.isEmpty
    }
    
    // MARK: - Actions
    private func markAsRead(item: NotificationModel) {
        guard !item.isRead else { return }
        
        db.collection("Notifications")
            .document(item.id)
            .updateData(["isRead": true]) { error in
                if let error = error {
                    print("Error marking item as read: \(error.localizedDescription)")
                }
            }
    }
    
    private func deleteItem(at indexPath: IndexPath) {
        let item = isSearching ? filteredItems[indexPath.row] : historyItems[indexPath.row]
        
        db.collection("Notifications")
            .document(item.id)
            .delete { [weak self] error in
                if let error = error {
                    print("Error deleting item: \(error.localizedDescription)")
                    self?.showError("Failed to delete item")
                } else {
                    self?.showSuccessToast(message: "Item deleted")
                }
            }
    }
    
    // MARK: - UI Helpers
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showSuccessToast(message: String) {
        let toast = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(toast, animated: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            toast.dismiss(animated: true)
        }
    }
}

// MARK: - UITableViewDataSource
extension HistoryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching ? filteredItems.count : historyItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "InventoryCell",
            for: indexPath
        ) as? InventoryTableViewCell else {
            return UITableViewCell()
        }
        
        let item = isSearching ? filteredItems[indexPath.row] : historyItems[indexPath.row]
        cell.configure(with: item) { [weak self] actionUrl in
            print("Action tapped for URL: \(actionUrl)")
            self?.handleItemAction(actionUrl: actionUrl, item: item)
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension HistoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = isSearching ? filteredItems[indexPath.row] : historyItems[indexPath.row]
        
        markAsRead(item: item)
        
        if let actionUrl = item.actionUrl {
            handleItemAction(actionUrl: actionUrl, item: item)
        }
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    private func handleItemAction(actionUrl: String, item: NotificationModel) {
        print("Navigate to: \(actionUrl)")
        // TODO: Implement navigation based on actionUrl
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.deleteItem(at: indexPath)
            completion(true)
        }
        deleteAction.image = UIImage(systemName: "minus")
        
        let item = isSearching ? filteredItems[indexPath.row] : historyItems[indexPath.row]
        if !item.isRead {
            let markReadAction = UIContextualAction(style: .normal, title: "Mark Read") { [weak self] _, _, completion in
                self?.markAsRead(item: item)
                completion(true)
            }
            markReadAction.backgroundColor = .secondary
            markReadAction.image = UIImage(systemName: "checkmark")
            
            return UISwipeActionsConfiguration(actions: [deleteAction, markReadAction])
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}
// MARK: - UISearchBarDelegate
extension HistoryViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        if query.isEmpty {
            isSearching = false
            filteredItems.removeAll()
        } else {
            isSearching = true
            filteredItems = historyItems.filter { item in
                // Safely check type via rawValue (e.g., "message", "success", "request")
                let isRequest = item.type.rawValue.lowercased() == "request"

                // If title/message are optionals, coalesce to empty string
                let titleText = (item.title as String?) ?? ""
                let messageText = (item.message as String?) ?? ""

                let titleMatch = titleText.range(of: query, options: .caseInsensitive) != nil
                let messageMatch = messageText.range(of: query, options: .caseInsensitive) != nil

                return isRequest && (titleMatch || messageMatch)
            }
        }

        tableView.reloadData()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isSearching = false
        searchBar.text = ""
        filteredItems.removeAll()
        tableView.reloadData()
        searchBar.resignFirstResponder()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
