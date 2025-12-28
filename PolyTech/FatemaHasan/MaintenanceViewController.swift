import UIKit
import FirebaseFirestore

class MaintenanceViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    private var maintenanceItems: [NotificationModel] = []
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    // TODO: Replace with actual user ID from your auth system
    private let currentUserId = "4gEMMK7yMPfJv3Xghk0iFefRBvH3"
    
    private let refreshControl = UIRefreshControl()
    private let emptyStateView = EmptyStateView()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupTableView()
        setupEmptyState()
        loadMaintenanceItems()
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
        
        // refresh control
        refreshControl.addTarget(self, action: #selector(refreshMaintenanceItems), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    // MARK: - EMPTY STATE
    private func setupEmptyState() {
        guard let tableView = tableView else {
            print("ERROR: Cannot setup empty state - tableView outlet is not connected!")
            return
        }
        
        emptyStateView.configure(
            //icon: UIImage(systemName: "bell.slash.fill"),
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
        print("load maintenance items for userId: \(currentUserId)")
        
        // Real-time listener for maintenance items
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
                    print(" No maintenance items for this user!!")
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
                
                print(" Successfully parsed \(self.maintenanceItems.count) maintenance items")
                
                DispatchQueue.main.async {
                    guard let tableView = self.tableView else { return }
                    tableView.reloadData()
                    self.updateEmptyState()
                }
            }
    }
    
    @objc private func refreshMaintenanceItems() {
        // Refresh is handled automatically by the real-time listener
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
    
    // MARK: - Sample Data (for testing)
    
    private func addSampleMaintenanceItems() {
        let sampleItems: [[String: Any]] = [
            [
                "userId": currentUserId,
                "title": "New Message",
                "message": "John Doe sent you a message",
                "type": "message",
                "iconName": "envelope.fill",
                "isRead": false,
                "timestamp": Timestamp(date: Date().addingTimeInterval(-300))
            ],
            [
                "userId": currentUserId,
                "title": "Success!",
                "message": "Your profile was updated successfully",
                "type": "success",
                "iconName": "checkmark.circle.fill",
                "isRead": false,
                "timestamp": Timestamp(date: Date().addingTimeInterval(-3600))
            ],
            [
                "userId": currentUserId,
                "title": "New Follower",
                "message": "Jane Smith started following you",
                "type": "follow",
                "iconName": "person.badge.plus.fill",
                "isRead": true,
                "timestamp": Timestamp(date: Date().addingTimeInterval(-7200))
            ],
            [
                "userId": currentUserId,
                "title": "Warning",
                "message": "Your storage is almost full",
                "type": "warning",
                "iconName": "exclamationmark.triangle.fill",
                "isRead": true,
                "timestamp": Timestamp(date: Date().addingTimeInterval(-86400))
            ],
            [
                "userId": currentUserId,
                "title": "You got a like!",
                "message": "Sarah Johnson liked your post",
                "type": "like",
                "iconName": "heart.fill",
                "isRead": false,
                "timestamp": Timestamp(date: Date().addingTimeInterval(-1800))
            ]
        ]
        
        for item in sampleItems {
            db.collection("Notifications").addDocument(data: item) { error in
                if let error = error {
                    print("Error adding sample item: \(error.localizedDescription)")
                }
            }
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
            // Handle action button tap
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
        
        // Mark as read
        markAsRead(item: item)
        
        // Handle action
        if let actionUrl = item.actionUrl {
            handleItemAction(actionUrl: actionUrl, item: item)
        }
        
        // Add haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    private func handleItemAction(actionUrl: String, item: NotificationModel) {
        print("Navigate to: \(actionUrl)")
        // TODO: Implement navigation based on actionUrl
        // Example: Navigate to different view controllers based on the URL or item type
        
        // You can parse the actionUrl and navigate accordingly
        // For example:
        // if actionUrl.contains("request") {
        //     navigateToRequestDetails(requestId: ...)
        // } else if actionUrl.contains("location") {
        //     navigateToLocationTracking(...)
        // }
    }
    
    // Swipe to delete
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
            // TODO: change this to read
            markReadAction.backgroundColor = .secondary
            markReadAction.image = UIImage(systemName: "checkmark")
            
            return UISwipeActionsConfiguration(actions: [deleteAction, markReadAction])
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}
