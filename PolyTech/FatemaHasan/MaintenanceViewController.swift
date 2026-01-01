import UIKit
import FirebaseFirestore
import FirebaseAuth

class MaintenanceViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var Addbtn: UIButton!
    
    // MARK: - Programmatic UI
    private let addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Add", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Properties
    private var maintenanceItems: [NotificationModel] = []
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    private var currentUserId: String {
        Auth.auth().currentUser?.uid ?? ""
    }

    private let refreshControl = UIRefreshControl()
    private let emptyStateView = EmptyStateView()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupTableView()
        setupEmptyState()
        loadMaintenanceItems()
        setupProgrammaticAddButton()  // ✅ NEW: Setup programmatic button
    }
    
    // ✅ NEW: Setup programmatic add button in navigation bar
    private func setupProgrammaticAddButton() {
        // Add button to navigation bar
        let addBarButton = UIBarButtonItem(
            title: "Add",
            style: .plain,
            target: self,
            action: #selector(addTapped)
        )
        navigationItem.rightBarButtonItem = addBarButton
    }
    @objc func addTapped() {
        let storyboard = UIStoryboard(name: "NewMaintenance", bundle: nil)
        guard let vc = storyboard.instantiateViewController(
            withIdentifier: "NewMaintenanceViewController"
        ) as? NewMaintenanceViewController else {
            print("❌ NewMaintenanceViewController not found or wrong class")
            return
        }
        
        // Use modalPresentationStyle for full screen or push for navigation
        // Option 1: Present modally (full screen)
//        vc.modalPresentationStyle = .fullScreen
//        present(vc, animated: true)
//        
        // Option 2: Push with navigation controller (if you have one)
         navigationController?.pushViewController(vc, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        listener?.remove()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = "Maintenance"
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
        
        tableView.register(MaintenanceTableViewCell.self, forCellReuseIdentifier: "MaintenanceCell")
        
        refreshControl.addTarget(self, action: #selector(refreshMaintenanceItems), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    private func setupEmptyState() {
        guard tableView != nil else {
            print("ERROR: Cannot setup empty state - tableView outlet is not connected!")
            return
        }
        
        emptyStateView.configure(
            title: "No Maintenance Items For Now.",
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
    
    private func loadMaintenanceItems() {
        print("📥 load maintenance items for userId: \(currentUserId)")
        
        listener = db.collection("Notifications")
            .whereField("userId", isEqualTo: currentUserId)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("**Error fetching maintenance items: \(error.localizedDescription)")
                    self.showError("Failed to load maintenance items")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("📭 No maintenance items for this user!!")
                    self.updateEmptyState()
                    return
                }
                
                self.maintenanceItems = documents.compactMap { document in
                    let item = NotificationModel(dictionary: document.data(), id: document.documentID)
                    if item == nil {
                        print("Failed to parse document: \(document.documentID)")
                        print("   Data: \(document.data())")
                    }
                    return item
                }
                
                print("✅ Successfully parsed \(self.maintenanceItems.count) maintenance items")
                
                DispatchQueue.main.async {
                    guard let tableView = self.tableView else { return }
                    tableView.reloadData()
                    self.updateEmptyState()
                }
            }
    }
    
    @objc private func refreshMaintenanceItems() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.refreshControl.endRefreshing()
        }
    }
    
    private func updateEmptyState() {
        guard let tableView = tableView else { return }
        emptyStateView.isHidden = !maintenanceItems.isEmpty
        tableView.isHidden = maintenanceItems.isEmpty
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
        let item = maintenanceItems[indexPath.row]
        
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

extension MaintenanceViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return maintenanceItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "MaintenanceCell",
            for: indexPath
        ) as? MaintenanceTableViewCell else {
            return UITableViewCell()
        }
        
        let item = maintenanceItems[indexPath.row]
        cell.configure(with: item) { [weak self] actionUrl in
            print("Action tapped for URL: \(actionUrl)")
            self?.handleItemAction(actionUrl: actionUrl, item: item)
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension MaintenanceViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = maintenanceItems[indexPath.row]
        
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
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.deleteItem(at: indexPath)
            completion(true)
        }
        deleteAction.image = UIImage(systemName: "minus")
        
        let item = maintenanceItems[indexPath.row]
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
