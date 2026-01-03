import UIKit
import FirebaseFirestore

class HistoryViewController: UIViewController {

    @IBOutlet weak var SearchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    private var maintenanceRequests: [MaintenanceRequestModel] = []
    private var inventoryRequests: [Inventory] = []
    private var filteredMaintenanceRequests: [MaintenanceRequestModel] = []
    private var filteredInventoryRequests: [Inventory] = []
    private var isSearching = false
    
    private let db = Firestore.firestore()
    private var maintenanceListener: ListenerRegistration?
    private var inventoryListener: ListenerRegistration?
    
    private let currentUserId = UserDefaults.standard.string(forKey: "userId")
    
    private let refreshControl = UIRefreshControl()
    private let emptyStateView = EmptyStateView()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupEmptyState()
        loadHistoryItems()
        
        SearchBar.delegate = self
        // Setup custom back button
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(goBack)
        )
        backButton.tintColor = .background
        navigationItem.leftBarButtonItem = backButton
        
        // Only hide the default back button if needed
        navigationItem.hidesBackButton = true
    }

    
    @objc private func goBack() {
        print("🔙 Back button tapped")
        
        // Since we're presented modally, use dismiss instead of pop
        if presentingViewController != nil {
            dismiss(animated: true, completion: nil)
        } else if let navController = navigationController, navController.viewControllers.count > 1 {
            navController.popViewController(animated: true)
        } else {
            print("❌ No way to go back")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Re-attach listeners if they were removed
        if maintenanceListener == nil || inventoryListener == nil {
            loadHistoryItems()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Don't remove listeners here - keep them active for real-time updates
        // maintenanceListener?.remove()
        // inventoryListener?.remove()
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
        tableView.register(HistoryTableViewCell.self, forCellReuseIdentifier: "HistoryCell")
        
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
            title: "No History Items",
            message: "Your maintenance and inventory requests will appear here."
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
        print("📥 Loading history items for userId: \(currentUserId ?? "nil")")
        
        // Maintenance Requests
        maintenanceListener = db.collection("maintenanceRequest")
            .whereField("userId", isEqualTo: currentUserId ?? "")
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error fetching maintenance requests: \(error.localizedDescription)")
                    self.updateEmptyState()
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    self.maintenanceRequests.removeAll()
                    self.updateEmptyState()
                    return
                }
                
                self.maintenanceRequests = documents.compactMap {
                    MaintenanceRequestModel(dictionary: $0.data(), id: $0.documentID)
                }
                
                // Sort by newest first (descending order)
                self.maintenanceRequests.sort { $0.createdAt.dateValue() > $1.createdAt.dateValue() }
                
                DispatchQueue.main.async {
                    self.tableView?.reloadData()
                    self.updateEmptyState()
                }
            }
        
        // Inventory Requests - fetch from 'inventoryRequest' collection (matching InventoryViewController)
        inventoryListener = db.collection("inventoryRequest")
            .whereField("userId", isEqualTo: currentUserId ?? "")
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error fetching inventory requests: \(error.localizedDescription)")
                    self.updateEmptyState()
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("⚠️ No documents found in inventoryRequest collection")
                    self.inventoryRequests.removeAll()
                    self.updateEmptyState()
                    return
                }
                
                print("📦 Found \(documents.count) inventory request documents")
                
                self.inventoryRequests = documents.compactMap {
                    Inventory(dictionary: $0.data(), id: $0.documentID)
                }
                
                print("✅ Successfully parsed \(self.inventoryRequests.count) inventory requests")
                
                // Sort by newest first (descending order)
                self.inventoryRequests.sort { $0.createdAt.dateValue() > $1.createdAt.dateValue() }
                
                DispatchQueue.main.async {
                    self.tableView?.reloadData()
                    self.updateEmptyState()
                    print("🔄 Table view reloaded with \(self.getTotalCount()) total items")
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
        let isEmpty = maintenanceRequests.isEmpty && inventoryRequests.isEmpty
        emptyStateView.isHidden = !isEmpty
        tableView.isHidden = isEmpty
    }
    
    // MARK: - Navigation
    private func navigateToFeedback(for requestType: String, requestId: String) {
        // Ensure this VC is embedded in a UINavigationController
        guard let nav = navigationController else {
            print("❌ No navigationController; embed HistoryViewController in a UINavigationController.")
            return
        }
        
        let storyboard = UIStoryboard(name: "ServiceFeedback", bundle: nil)
        guard let vc = storyboard.instantiateViewController(
            withIdentifier: "ServiceFeedbackViewController"
        ) as? ServiceFeedbackViewController else {
            print("❌ ServiceFeedbackViewController not found or wrong class")
            return
        }
        
        // Pass context to feedback screen (add these properties in ServiceFeedbackViewController)
        vc.requestType = requestType
        vc.requestId = requestId
        
        nav.pushViewController(vc, animated: true)
    }
    
    // MARK: - Helpers
    private func getTotalCount() -> Int {
        return isSearching
            ? filteredMaintenanceRequests.count + filteredInventoryRequests.count
            : maintenanceRequests.count + inventoryRequests.count
    }
    
    private func getItemType(at index: Int) -> (type: String, item: Any) {
        // Combine both arrays and sort by date
        let maintenanceItems: [(date: Date, type: String, item: Any)] = (isSearching ? filteredMaintenanceRequests : maintenanceRequests).map {
            (date: $0.createdAt.dateValue(), type: "maintenance", item: $0)
        }
        
        let inventoryItems: [(date: Date, type: String, item: Any)] = (isSearching ? filteredInventoryRequests : inventoryRequests).map {
            (date: $0.createdAt.dateValue(), type: "inventory", item: $0)
        }
        
        // Combine and sort by date (newest first)
        let allItems = (maintenanceItems + inventoryItems).sorted { $0.date > $1.date }
        
        let item = allItems[index]
        return (type: item.type, item: item.item)
    }
}

// MARK: - UITableViewDataSource
extension HistoryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getTotalCount()
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "HistoryCell",
            for: indexPath
        ) as? HistoryTableViewCell else {
            return UITableViewCell()
        }
        
        let itemData = getItemType(at: indexPath.row)
        
        if itemData.type == "maintenance", let item = itemData.item as? MaintenanceRequestModel {
            cell.configure(with: item, feedbackCallback: { [weak self] in
                guard let self else { return }

                let status = item.status.lowercased()
                let isCompleted = (status == "completed" || status == "done")

                let alreadySubmitted = item.feedbackSubmitted

                guard isCompleted && !alreadySubmitted else {
                    let alert = UIAlertController(
                        title: "Feedback not available",
                        message: alreadySubmitted
                            ? "You already submitted feedback for this request."
                            : "You can only leave feedback after the request is completed.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                    return
                }

                self.navigateToFeedback(for: "maintenance", requestId: item.id)
            })
        } else if itemData.type == "inventory", let item = itemData.item as? Inventory {
            cell.configure(with: item, feedbackCallback: { [weak self] in
                self?.navigateToFeedback(for: "inventory", requestId: item.id)
            })
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension HistoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            guard let self = self else { completion(false); return }
            let itemData = self.getItemType(at: indexPath.row)
            
            if itemData.type == "maintenance", let item = itemData.item as? MaintenanceRequestModel {
                self.db.collection("maintenanceRequest").document(item.id).delete { error in
                    if let error = error {
                        self.showError("Failed to delete: \(error.localizedDescription)")
                    } else {
                        print("✅ Maintenance request deleted successfully")
                    }
                }
            } else if itemData.type == "inventory", let item = itemData.item as? Inventory {
                self.db.collection("inventoryRequest").document(item.id).delete { error in
                    if let error = error {
                        self.showError("Failed to delete: \(error.localizedDescription)")
                    } else {
                        print("✅ Inventory request deleted successfully")
                    }
                }
            }
            
            completion(true)
        }
        deleteAction.image = UIImage(systemName: "trash")
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    // MARK: - UI Helpers
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UISearchBarDelegate
extension HistoryViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        if query.isEmpty {
            isSearching = false
            filteredMaintenanceRequests.removeAll()
            filteredInventoryRequests.removeAll()
        } else {
            isSearching = true
            
            filteredMaintenanceRequests = maintenanceRequests.filter { item in
                let nameMatch = item.requestName.range(of: query, options: .caseInsensitive) != nil
                let locationMatch = item.location.range(of: query, options: .caseInsensitive) != nil
                let categoryMatch = item.category.range(of: query, options: .caseInsensitive) != nil
                return nameMatch || locationMatch || categoryMatch
            }
            
            filteredInventoryRequests = inventoryRequests.filter { item in
                let nameMatch = item.requestName.range(of: query, options: .caseInsensitive) != nil
                let itemNameMatch = item.itemName.range(of: query, options: .caseInsensitive) != nil
                let categoryMatch = item.category.range(of: query, options: .caseInsensitive) != nil
                let locationMatch = item.location.range(of: query, options: .caseInsensitive) != nil
                return nameMatch || itemNameMatch || categoryMatch || locationMatch
            }
        }

        tableView.reloadData()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isSearching = false
        searchBar.text = ""
        filteredMaintenanceRequests.removeAll()
        filteredInventoryRequests.removeAll()
        tableView.reloadData()
        searchBar.resignFirstResponder()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
