import UIKit
import FirebaseFirestore

class NotificationsViewController: UIViewController {

    // MARK: - Properties
    private var notifications: [NotificationModel] = []
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private let currentUserId = UserDefaults.standard.string(forKey: "userId")
    private let refreshControl = UIRefreshControl()
    private let emptyStateView = EmptyStateView()
    
    // MARK: - UI Components (Programmatic)
    
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.separatorStyle = .none
        tv.backgroundColor = .clear
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 150
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    private let clearAllButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = "Clear All Notifications"
        config.image = UIImage(systemName: "trash.fill")
        config.imagePlacement = .leading
        config.imagePadding = 8
        config.baseBackgroundColor = .primary
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
        
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            return outgoing
        }
        
        button.configuration = config
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let markAllReadButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "checkmark.circle.fill")
        config.baseBackgroundColor = .accent
        config.baseForegroundColor = .onPrimary
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)
        
        button.configuration = config
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 8
        button.layer.shadowOpacity = 0.25
        
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupTableView()
        setupEmptyState()
        setupConstraints()
        loadNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        listener?.remove()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = "Notifications"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .background
        
        view.addSubview(tableView)
        view.addSubview(clearAllButton)
        view.addSubview(markAllReadButton)
        view.addSubview(emptyStateView)
        
        clearAllButton.addTarget(self, action: #selector(clearAllNotifications), for: .touchUpInside)
        markAllReadButton.addTarget(self, action: #selector(markAllAsRead), for: .touchUpInside)
        
        refreshControl.addTarget(self, action: #selector(refreshNotifications), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(NotificationTableViewCell.self, forCellReuseIdentifier: "NotificationCell")
    }
    
    private func setupEmptyState() {
        emptyStateView.configure(
            title: "No Notifications For Now.",
            message: "Once a request status gets updated, we will notify you immediately."
        )
        emptyStateView.isHidden = true
    }
    
    private func setupConstraints() {
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            clearAllButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            clearAllButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            clearAllButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            clearAllButton.heightAnchor.constraint(equalToConstant: 54),
            
            markAllReadButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            markAllReadButton.bottomAnchor.constraint(equalTo: clearAllButton.topAnchor, constant: -16),
            markAllReadButton.widthAnchor.constraint(equalToConstant: 56),
            markAllReadButton.heightAnchor.constraint(equalToConstant: 56),
            
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: markAllReadButton.topAnchor, constant: -6),
            
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }
    
    // MARK: - Data Loading
    
    private func loadNotifications() {
        guard let userId = currentUserId else {
            print("❌ No userId found")
            return
        }
        
        print("📱 Loading notifications for userId: \(userId)")
        
        listener = db.collection("Notifications")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error fetching notifications: \(error.localizedDescription)")
                    self.showError("Failed to load notifications")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("⚠️ No notifications found")
                    self.updateEmptyState()
                    return
                }
                
                print("📊 Found \(documents.count) notification documents")
                
                // ✅ FIXED: Properly parse notifications with correct document IDs
                self.notifications = documents.compactMap { document in
                    let data = document.data()
                    let documentId = document.documentID
                    
                    // Debug: Print document ID and data
                    print("📄 Document ID: \(documentId)")
                    print("   Data: \(data)")
                    
                    // Create notification with CORRECT document ID
                    guard let notification = NotificationModel(dictionary: data, id: documentId) else {
                        print("⚠️ Failed to parse document: \(documentId)")
                        return nil
                    }
                    
                    print("✅ Parsed notification: \(notification.id) - \(notification.title)")
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.refreshControl.endRefreshing()
        }
    }
    
    private func updateEmptyState() {
        let isEmpty = notifications.isEmpty
        emptyStateView.isHidden = !isEmpty
        tableView.isHidden = isEmpty
        clearAllButton.isHidden = isEmpty
        markAllReadButton.isHidden = isEmpty
    }
    
    private func updateMarkAllReadButton() {
        let hasUnread = notifications.contains { !$0.isRead }
        markAllReadButton.isEnabled = hasUnread
        
        UIView.animate(withDuration: 0.2) {
            self.markAllReadButton.alpha = hasUnread ? 1.0 : 0.4
            self.markAllReadButton.transform = hasUnread ? .identity : CGAffineTransform(scaleX: 0.9, y: 0.9)
        }
    }
    
    // MARK: - Actions
    
    @objc private func markAllAsRead() {
        let unreadNotifications = notifications.filter { !$0.isRead }
        guard !unreadNotifications.isEmpty else {
            print("⚠️ No unread notifications to mark")
            return
        }
        
        print("📝 Marking \(unreadNotifications.count) notifications as read")
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        UIView.animate(withDuration: 0.1, animations: {
            self.markAllReadButton.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.markAllReadButton.transform = .identity
            }
        }
        
        let batch = db.batch()
        
        for notification in unreadNotifications {
            let docRef = db.collection("Notifications").document(notification.id)
            print("   Marking as read: \(notification.id)")
            batch.updateData(["isRead": true], forDocument: docRef)
        }
        
        batch.commit { [weak self] error in
            if let error = error {
                print("❌ Error marking all as read: \(error.localizedDescription)")
                self?.showError("Failed to mark notifications as read")
            } else {
                print("✅ All notifications marked as read")
                self?.showSuccessToast(message: "All notifications marked as read")
            }
        }
    }
    
    @objc private func clearAllNotifications() {
        guard !notifications.isEmpty else {
            print("⚠️ No notifications to clear")
            return
        }
        
        let alert = UIAlertController(
            title: "Clear All Notifications",
            message: "This action cannot be undone. Do you wish to proceed?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear All", style: .destructive) { [weak self] _ in
            self?.performClearAll()
        })
        
        present(alert, animated: true)
    }
    
    private func performClearAll() {
        print("🗑️ Clearing \(notifications.count) notifications")
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        
        let batch = db.batch()
        
        for notification in notifications {
            let docRef = db.collection("Notifications").document(notification.id)
            print("   Deleting: \(notification.id)")
            batch.deleteDocument(docRef)
        }
        
        batch.commit { [weak self] error in
            if let error = error {
                print("❌ Error clearing all notifications: \(error.localizedDescription)")
                self?.showError("Failed to clear notifications")
            } else {
                print("✅ All notifications cleared")
                self?.showSuccessToast(message: "All notifications cleared")
            }
        }
    }
    
    private func markAsRead(notification: NotificationModel) {
        guard !notification.isRead else {
            print("⚠️ Notification already read: \(notification.id)")
            return
        }
        
        print("📝 Marking notification as read: \(notification.id)")
        
        db.collection("Notifications")
            .document(notification.id)
            .updateData(["isRead": true]) { error in
                if let error = error {
                    print("❌ Error marking notification as read: \(error.localizedDescription)")
                } else {
                    print("✅ Notification marked as read: \(notification.id)")
                }
            }
    }
    
    private func deleteNotification(at indexPath: IndexPath) {
        let notification = notifications[indexPath.row]
        
        print("🗑️ Deleting notification: \(notification.id)")
        
        db.collection("Notifications")
            .document(notification.id)
            .delete { [weak self] error in
                if let error = error {
                    print("❌ Error deleting notification: \(error.localizedDescription)")
                    self?.showError("Failed to delete notification")
                } else {
                    print("✅ Notification deleted: \(notification.id)")
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
            print("🔗 Action tapped for URL: \(actionUrl)")
            self?.handleNotificationAction(actionUrl: actionUrl, notification: notification)
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension NotificationsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let notification = notifications[indexPath.row]
        
        markAsRead(notification: notification)
        
        if let actionUrl = notification.actionUrl {
            handleNotificationAction(actionUrl: actionUrl, notification: notification)
        }
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    private func handleNotificationAction(actionUrl: String, notification: NotificationModel) {
        print("🔗 Navigate to: \(actionUrl)")
        // TODO: Implement navigation based on actionUrl
    }
    
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
            markReadAction.backgroundColor = .accent
            markReadAction.image = UIImage(systemName: "checkmark.circle.fill")
            
            return UISwipeActionsConfiguration(actions: [deleteAction, markReadAction])
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

// MARK: - Empty State View

class EmptyStateView: UIView {
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textColor = .primary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .primary
        label.textAlignment = .center
        label.numberOfLines = 0
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
        addSubview(stackView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(messageLabel)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func configure(title: String, message: String) {
        titleLabel.text = title
        messageLabel.text = message
    }
}
