import UIKit
import FirebaseFirestore
import FirebaseAuth

class InventoryViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Data
    private var inventoryItems: [Inventory] = []
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private let currentUserId = UserDefaults.standard.string(forKey: "userId")
    
    // MARK: - UI Helpers
    private let refreshControl = UIRefreshControl()
    private let emptyStateView = EmptyStateView()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationButtons()
        setupTableView()
        setupEmptyState()
        loadInventoryItems()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        listener?.remove()
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
        // Left: Return text
        let returnBarButton = UIBarButtonItem(
            title: "Return",
            style: .plain,
            target: self,
            action: #selector(returnInventoryTapped)
        )
        navigationItem.rightBarButtonItem = addBarButton
        navigationItem.leftBarButtonItem = returnBarButton
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
    
    @objc private func returnInventoryTapped() {
        let storyboard = UIStoryboard(name: "ReturnInventory", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "ReturnInventoryViewController")
                as? ReturnInventoryViewController else {
            print("❌ ReturnInventoryViewController not found or wrong class")
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
        guard tableView != nil else { return }
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
    
    // MARK: - Data
    private func loadInventoryItems() {
        print("📥 Loading inventory items for userId: \(currentUserId ?? "nil")")
        guard let uid = currentUserId, !uid.isEmpty else {
            print("❌ currentUserId is nil or empty")
            updateEmptyState()
            return
        }
        
        listener = db.collection("inventoryRequest")
            .whereField("userId", isEqualTo: uid)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("❌ Error fetching inventory items: \(error.localizedDescription)")
                    self.showError("Failed to load inventory items")
                    self.updateEmptyState()
                    return
                }
                guard let documents = snapshot?.documents else {
                    print("📭 No inventory items found")
                    self.inventoryItems.removeAll()
                    self.updateEmptyState()
                    return
                }
                
                self.inventoryItems = documents.compactMap {
                    Inventory(dictionary: $0.data(), id: $0.documentID)
                }
                
                // Sort newest first
                self.inventoryItems.sort { ($0.timestamp ?? Date()) > ($1.timestamp ?? Date()) }
                
                DispatchQueue.main.async {
                    self.tableView?.reloadData()
                    self.updateEmptyState()
                }
            }
    }
    
    @objc private func refreshInventoryItems() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.refreshControl.endRefreshing()
        }
    }
    
    private func updateEmptyState() {
        guard let tableView = tableView else { return }
        let isEmpty = inventoryItems.isEmpty
        emptyStateView.isHidden = !isEmpty
        tableView.isHidden = isEmpty
    }
    
    // MARK: - Details/Edit/Delete
    private func showDetailsPopup(for item: Inventory) {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        let details = """
        📦 Item Name: \(item.itemName)
        🔢 Quantity: \(item.quantity)
        🏷️ Category: \(item.category.capitalized)
        📍 Location: \(item.location)
        📝 Request Name: \(item.requestName)
        🕐 Created: \(formatter.string(from: item.createdAt.dateValue()))
        🔄 Updated: \(formatter.string(from: item.updatedAt.dateValue()))
        """
        
        let alert = UIAlertController(title: "Inventory Details", message: details, preferredStyle: .alert)
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
        // Ensure NewInventoryViewController has: var itemToEdit: Inventory?
        vc.itemToEdit = item
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func deleteItem(at indexPath: IndexPath) {
        let item = inventoryItems[indexPath.row]
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
            .delete { [weak self] error in
                if let error = error {
                    print("❌ Error deleting item: \(error.localizedDescription)")
                    self?.showError("Failed to delete item")
                } else {
                    print("✅ Item deleted successfully")
                    self?.showSuccessToast(message: "Inventory deleted successfully")
                }
            }
    }
    
    // MARK: - UI Alerts
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
extension InventoryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        inventoryItems.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "InventoryCell",
            for: indexPath
        ) as? InventoryTableViewCell else {
            return UITableViewCell()
        }
        
        let item = inventoryItems[indexPath.row]
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
        showDetailsPopup(for: inventoryItems[indexPath.row])
    }
    
    // Keep swipe actions for flexibility (View, Edit, Delete)
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {
        // Delete
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.deleteItem(at: indexPath)
            completion(true)
        }
        deleteAction.image = UIImage(systemName: "trash")
        
        // Edit
        let editAction = UIContextualAction(style: .normal, title: "Edit") { [weak self] _, _, completion in
            guard let self = self else { completion(false); return }
            self.navigateToEdit(item: self.inventoryItems[indexPath.row])
            completion(true)
        }
        editAction.backgroundColor = .systemBlue
        editAction.image = UIImage(systemName: "pencil")
        
        // View
        let viewAction = UIContextualAction(style: .normal, title: "Details") { [weak self] _, _, completion in
            guard let self = self else { completion(false); return }
            self.showDetailsPopup(for: self.inventoryItems[indexPath.row])
            completion(true)
        }
        viewAction.backgroundColor = .systemGreen
        viewAction.image = UIImage(systemName: "info.circle")
        
        return UISwipeActionsConfiguration(actions: [deleteAction, editAction, viewAction])
    }
}
