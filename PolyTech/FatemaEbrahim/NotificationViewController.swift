import UIKit
import FirebaseFirestore

class NotificationsViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var clearAllButton: UIButton! // Connect this in Storyboard
    
    // MARK: - Properties
    private var notifications: [NotificationModel] = []
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    // Replace with actual user ID from your auth system
    private let currentUserId = "7fgOEVpMQUPHR9kgBPEv7mFRgLt1"  // Note: Letter 'O' not zero
    
    private let refreshControl = UIRefreshControl()
    private let emptyStateView = EmptyStateView()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupTableView()
        setupEmptyState()
        loadNotifications()
        
        // Uncomment to add sample data for testing
        // addSampleNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        listener?.remove()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = "Notifications"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemGroupedBackground
        
        // Add "Mark All Read" button
        let markAllButton = UIBarButtonItem(
            title: "Mark All Read",
            style: .plain,
            target: self,
            action: #selector(markAllAsRead)
        )
        
        // Add "Clear All" button
        let clearAllButton = UIBarButtonItem(
            title: "Clear All",
            style: .plain,
            target: self,
            action: #selector(clearAllNotifications)
        )
        clearAllButton.tintColor = .systemRed
        
        navigationItem.rightBarButtonItems = [markAllButton, clearAllButton]
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .systemGroupedBackground
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        
        // Register cell programmatically if not using storyboard
        tableView.register(NotificationTableViewCell.self, forCellReuseIdentifier: "NotificationCell")
        
        // Add refresh control
        refreshControl.addTarget(self, action: #selector(refreshNotifications), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    private func setupEmptyState() {
        emptyStateView.configure(
            icon: UIImage(systemName: "bell.slash.fill"),
            title: "No Notifications",
            message: "You're all caught up! Check back later for updates."
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
    
    private func loadNotifications() {
        print("🔍 Starting to load notifications for userId: \(currentUserId)")
        
        // Real-time listener for notifications
        listener = db.collection("Notifications")  // Capital N to match Firestore
            .whereField("userId", isEqualTo: currentUserId)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error fetching notifications: \(error.localizedDescription)")
                    self.showError("Failed to load notifications")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("⚠️ No documents returned from query")
                    self.updateEmptyState()
                    return
                }
                
<<<<<<< HEAD
                print("📦 Fetched \(documents.count) notification documents")
                
                // Debug: Print all documents
                for (index, document) in documents.enumerated() {
                    print("📄 Document \(index + 1):")
                    print("   ID: \(document.documentID)")
                    print("   Data: \(document.data())")
                }
=======
              
>>>>>>> master
                
                self.notifications = documents.compactMap { document in
                    let notification = NotificationModel(dictionary: document.data(), id: document.documentID)
                    if notification == nil {
                        print("⚠️ Failed to parse document: \(document.documentID)")
                        print("   Data: \(document.data())")
                    }
                    return notification
                }
                
                print("✅ Successfully parsed \(self.notifications.count) notifications")
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.updateEmptyState()
                    self.updateMarkAllReadButton()
                }
            }
    }
    
    @objc private func refreshNotifications() {
        // Refresh is handled automatically by the real-time listener
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.refreshControl.endRefreshing()
        }
    }
    
    private func updateEmptyState() {
        emptyStateView.isHidden = !notifications.isEmpty
        tableView.isHidden = notifications.isEmpty
    }
    
    private func updateMarkAllReadButton() {
        let hasUnread = notifications.contains { !$0.isRead }
        navigationItem.rightBarButtonItem?.isEnabled = hasUnread
        
        // Update clear all button visibility
        clearAllButton?.isHidden = notifications.isEmpty
    }
    
    // MARK: - Actions
    
    @objc private func markAllAsRead() {
        let unreadNotifications = notifications.filter { !$0.isRead }
        guard !unreadNotifications.isEmpty else { return }
        
        let batch = db.batch()
        
        for notification in unreadNotifications {
            let docRef = db.collection("Notifications").document(notification.id)
            batch.updateData(["isRead": true], forDocument: docRef)
        }
        
        batch.commit { [weak self] error in
            if let error = error {
                print("Error marking all as read: \(error.localizedDescription)")
                self?.showError("Failed to mark notifications as read")
            } else {
                self?.showSuccessToast(message: "All notifications marked as read")
            }
        }
    }
    
    @objc private func clearAllNotifications() {
        guard !notifications.isEmpty else { return }
        
        let alert = UIAlertController(
            title: "Clear All Notifications",
            message: "Are you sure you want to delete all notifications? This action cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear All", style: .destructive) { [weak self] _ in
            self?.performClearAll()
        })
        
        present(alert, animated: true)
    }
    
    private func performClearAll() {
        let batch = db.batch()
        
        for notification in notifications {
            let docRef = db.collection("Notifications").document(notification.id)
            batch.deleteDocument(docRef)
        }
        
        batch.commit { [weak self] error in
            if let error = error {
                print("Error clearing all notifications: \(error.localizedDescription)")
                self?.showError("Failed to clear notifications")
            } else {
                self?.showSuccessToast(message: "All notifications cleared")
            }
        }
    }
    
    private func markAsRead(notification: NotificationModel) {
        guard !notification.isRead else { return }
        
        db.collection("Notifications")
            .document(notification.id)
            .updateData(["isRead": true]) { error in
                if let error = error {
                    print("Error marking notification as read: \(error.localizedDescription)")
                }
            }
    }
    
    private func deleteNotification(at indexPath: IndexPath) {
        let notification = notifications[indexPath.row]
        
        db.collection("Notifications")
            .document(notification.id)
            .delete { [weak self] error in
                if let error = error {
                    print("Error deleting notification: \(error.localizedDescription)")
                    self?.showError("Failed to delete notification")
                } else {
                    self?.showSuccessToast(message: "Notification deleted")
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
    
    private func addSampleNotifications() {
        let sampleNotifications: [[String: Any]] = [
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
        
        for notification in sampleNotifications {
            db.collection("Notifications").addDocument(data: notification) { error in
                if let error = error {
                    print("Error adding sample notification: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource

extension NotificationsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "NotificationCell",
            for: indexPath
        ) as? NotificationTableViewCell else {
            return UITableViewCell()
        }
        
        let notification = notifications[indexPath.row]
        cell.configure(with: notification) { [weak self] actionUrl in
            // Handle action button tap
            print("Action tapped for URL: \(actionUrl)")
            self?.handleNotificationAction(actionUrl: actionUrl, notification: notification)
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension NotificationsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let notification = notifications[indexPath.row]
        
        // Mark as read
        markAsRead(notification: notification)
        
        // Handle action
        if let actionUrl = notification.actionUrl {
            handleNotificationAction(actionUrl: actionUrl, notification: notification)
        }
        
        // Add haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    private func handleNotificationAction(actionUrl: String, notification: NotificationModel) {
        print("Navigate to: \(actionUrl)")
        // TODO: Implement navigation based on actionUrl
        // Example: Navigate to different view controllers based on the URL or notification type
        
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
            self?.deleteNotification(at: indexPath)
            completion(true)
        }
        deleteAction.image = UIImage(systemName: "trash.fill")
        
        let notification = notifications[indexPath.row]
        if !notification.isRead {
            let markReadAction = UIContextualAction(style: .normal, title: "Mark Read") { [weak self] _, _, completion in
                self?.markAsRead(notification: notification)
                completion(true)
            }
            markReadAction.backgroundColor = .systemBlue
            markReadAction.image = UIImage(systemName: "checkmark")
            
            return UISwipeActionsConfiguration(actions: [deleteAction, markReadAction])
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

// MARK: - Empty State View

class EmptyStateView: UIView {
    
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .systemGray3
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(messageLabel)
        
        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.topAnchor.constraint(equalTo: topAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 80),
            iconImageView.heightAnchor.constraint(equalToConstant: 80),
            
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func configure(icon: UIImage?, title: String, message: String) {
        iconImageView.image = icon
        titleLabel.text = title
        messageLabel.text = message
    }
}
