import UIKit
import FirebaseFirestore
import FirebaseAuth

class InventoryViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Data
    private var inventoryItems: [Inventory] = []
    private var filteredItems: [Inventory] = []   // used for search results
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
        attachInventoryListener()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        listener?.remove()
        listener = nil
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "Inventory"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemBackground
    }
    
    private func setupNavigationButtons() {
        // Right: plus icon
        let addBarButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addTapped)
        )
        navigationItem.rightBarButtonItem = addBarButton
    }
    
    @objc private func addTapped() {
        let storyboard = UIStoryboard(name: "NewInventory", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "NewInventoryViewController")
                as? NewInventoryViewController else {
            print("❌ NewInventoryViewController not found or wrong class")
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
        tableView.register(InventoryTableViewCell.self, forCellReuseIdentifier: "InventoryCell")
        
        refreshControl.addTarget(self, action: #selector(refreshInventoryItems), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    private func setupEmptyState() {
        emptyStateView.configure(
            title: "No Inventory Items",
            message: "Tap '+' to create a new inventory request."
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
    
    private func setupSearch() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search requests by name, category, location"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    // MARK: - Real-time listener
    private func attachInventoryListener() {
        guard listener == nil else { return } // avoid multiple listeners
        guard let uid = currentUserId, !uid.isEmpty else {
            print("❌ currentUserId is nil or empty")
            filteredItems = []
            updateEmptyState()
            return
        }
        
        listener = db.collection("inventoryRequest")
            .whereField("userId", isEqualTo: uid)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("❌ Error fetching inventory items: \(error.localizedDescription)")
                    self.inventoryItems.removeAll()
                    self.applySearchFilter()
                    return
                }
                guard let documents = snapshot?.documents else {
                    self.inventoryItems.removeAll()
                    self.applySearchFilter()
                    return
                }
                
                self.inventoryItems = documents.compactMap {
                    Inventory(dictionary: $0.data(), id: $0.documentID)
                }
                // Sort newest first by createdAt
                self.inventoryItems.sort { $0.createdAt.dateValue() > $1.createdAt.dateValue() }
                
                self.applySearchFilter()
            }
    }
    
    // MARK: - Pull to refresh (optional)
    @objc private func refreshInventoryItems() {
        // Reattach listener to force a re-sync (optional)
        listener?.remove()
        listener = nil
        attachInventoryListener()
        
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
            filteredItems = inventoryItems.filter {
                $0.itemName.lowercased().contains(q) ||
                $0.category.lowercased().contains(q) ||
                $0.location.lowercased().contains(q) ||
                $0.requestName.lowercased().contains(q)
            }
        } else {
            filteredItems = inventoryItems
        }
        DispatchQueue.main.async {
            self.tableView?.reloadData()
            self.updateEmptyState()
        }
    }
    
    // MARK: - Details Popup
    private func showDetailsPopup(for item: Inventory) {
        let alertVC = UIViewController()
        alertVC.view.backgroundColor = .systemBackground
        alertVC.preferredContentSize = CGSize(width: 320, height: 300)
        
        let titleLabel = UILabel()
        titleLabel.text = "Inventory Details"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textAlignment = .center
        
        let detailsLabel = UILabel()
        detailsLabel.numberOfLines = 0
        detailsLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        detailsLabel.textColor = .label
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        let createdText = formatter.string(from: item.createdAt.dateValue())
        let updatedText = formatter.string(from: item.updatedAt.dateValue())
        
        detailsLabel.text = """
        📦 Item Name: \(item.itemName)
        🔢 Quantity: \(item.quantity)
        🏷️ Category: \(item.category.capitalized)
        📍 Location: \(item.location)
        📝 Request Name: \(item.requestName)
        🕐 Created: \(createdText)
        🔄 Updated: \(updatedText)
        """
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, detailsLabel])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        alertVC.view.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: alertVC.view.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: alertVC.view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: alertVC.view.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: alertVC.view.bottomAnchor, constant: -20)
        ])
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        alert.setValue(alertVC, forKey: "contentViewController")
        alert.addAction(UIAlertAction(title: "Close", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func navigateToEdit(item: Inventory) {
        let storyboard = UIStoryboard(name: "NewInventory", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "NewInventoryViewController")
                as? NewInventoryViewController else {
            print("❌ NewInventoryViewController not found or wrong class")
            return
        }
        vc.itemToEdit = item
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func deleteItem(at indexPath: IndexPath) {
        // Use filteredItems to match the row the user sees
        let item = filteredItems[indexPath.row]
        
        let alert = UIAlertController(
            title: "Delete Inventory",
            message: "Are you sure you want to delete this inventory item?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.performDelete(item: item)
        })
        present(alert, animated: true)
    }
    
    private func performDelete(item: Inventory) {
        db.collection("inventoryRequest")
            .document(item.id)
            .delete { error in
                if let error = error {
                    print("❌ Error deleting item: \(error.localizedDescription)")
                } else {
                    print("✅ Item deleted successfully")
                }
            }
    }
    
    // MARK: - Return Inventory
    private func returnInventoryItem(at indexPath: IndexPath) {
        let item = filteredItems[indexPath.row]
        
        let alert = UIAlertController(
            title: "Return Inventory",
            message: "Are you sure you want to return \(item.quantity) unit(s) of '\(item.itemName)'? This will update the inventory stock.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Return", style: .default) { [weak self] _ in
            self?.performReturn(item: item)
        })
        
        present(alert, animated: true)
    }
    
    private func performReturn(item: Inventory) {

        let loadingAlert = UIAlertController(
            title: nil,
            message: "Returning inventory...",
            preferredStyle: .alert
        )
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.startAnimating()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        loadingAlert.view.addSubview(indicator)

        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: loadingAlert.view.centerXAnchor),
            indicator.bottomAnchor.constraint(equalTo: loadingAlert.view.bottomAnchor, constant: -20)
        ])

        present(loadingAlert, animated: true)

        // ✅ Use a SAFE document ID (recommended)
        let stockRef = db.collection("inventoryStock")
            .document(item.itemName.lowercased().replacingOccurrences(of: " ", with: "_"))

        let requestRef = db.collection("inventoryRequest").document(item.id)

        db.runTransaction({ transaction, errorPointer in

            let stockDoc: DocumentSnapshot
            do {
                stockDoc = try transaction.getDocument(stockRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }

            let currentQty = stockDoc.data()?["quantity"] as? Int ?? 0
            let newQty = currentQty + item.quantity

            // 🔼 Increase stock
            transaction.setData([
                "itemName": item.itemName,
                "category": item.category,
                "location": item.location,
                "quantity": newQty,
                "lastUpdated": FieldValue.serverTimestamp()
            ], forDocument: stockRef, merge: true)

            // 🗑 Delete request
            transaction.deleteDocument(requestRef)

            return nil

        }) { [weak self] _, error in
            guard let self = self else { return }

            loadingAlert.dismiss(animated: true) {
                if let error = error {
                    print("❌ Return failed:", error.localizedDescription)
                    self.showReturnErrorAlert(message: error.localizedDescription)
                } else {
                    print("✅ Inventory returned & stock updated")
                    self.showReturnSuccessAlert(
                        itemName: item.itemName,
                        quantity: item.quantity
                    )
                }
            }
        }
    }

    
    private func showReturnSuccessAlert(itemName: String, quantity: Int) {
        let alert = UIAlertController(
            title: "Success",
            message: "Successfully returned \(quantity) unit(s) of '\(itemName)' to inventory stock.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showReturnErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: "Failed to return inventory: \(message)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension InventoryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredItems.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "InventoryCell",
            for: indexPath
        ) as? InventoryTableViewCell else {
            return UITableViewCell()
        }
        
        let item = filteredItems[indexPath.row]
        cell.configure(with: item,
                       viewCallback: { [weak self] in self?.showDetailsPopup(for: item) },
                       editCallback: { [weak self] in self?.navigateToEdit(item: item) })
        return cell
    }
}

// MARK: - UITableViewDelegate
extension InventoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        showDetailsPopup(for: filteredItems[indexPath.row])
    }
    
    // MARK: - Left Swipe Actions (trailing)
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
    
    // MARK: - Right Swipe Actions (leading)
    func tableView(_ tableView: UITableView,
                   leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {
        
        let returnAction = UIContextualAction(style: .normal, title: "Return") { [weak self] _, _, completion in
            self?.returnInventoryItem(at: indexPath)
            completion(true)
        }
        returnAction.backgroundColor = .systemOrange
        returnAction.image = UIImage(systemName: "arrow.uturn.backward")
        
        return UISwipeActionsConfiguration(actions: [returnAction])
    }
}

// MARK: - UISearchResultsUpdating
extension InventoryViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        applySearchFilter()
    }
}
