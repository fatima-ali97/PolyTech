//
//  NotificationViewController.swift
//  PolyTech
//
//  Created by BP-19-130-15 on 22/12/2025.
//

import UIKit
import FirebaseFirestore

class NotificationsViewController: UIViewController {

    // MARK: - IBOutlets
        @IBOutlet weak var tableView: UITableView!
        
        // MARK: - Properties
        private var notifications: [NotificationModel] = []
        private let db = Firestore.firestore()
        private var listener: ListenerRegistration?
        
        // Replace with actual user ID from your auth system
        private let currentUserId = "user_abc"
        
        // MARK: - Lifecycle
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            setupUI()
            setupTableView()
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
            
            // Add "Mark All Read" button
            let markAllButton = UIBarButtonItem(
                title: "Mark All Read",
                style: .plain,
                target: self,
                action: #selector(markAllAsRead)
            )
            navigationItem.rightBarButtonItem = markAllButton
        }
        
        private func setupTableView() {
            tableView.delegate = self
            tableView.dataSource = self
            tableView.separatorStyle = .none
            tableView.rowHeight = UITableView.automaticDimension
            tableView.estimatedRowHeight = 80
        }
        
        // MARK: - Data Loading
        
        private func loadNotifications() {
            // Real-time listener for notifications
            listener = db.collection("notifications")
                .whereField("userId", isEqualTo: currentUserId)
                .order(by: "timestamp", descending: true)
                .addSnapshotListener { [weak self] querySnapshot, error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("Error fetching notifications: \(error.localizedDescription)")
                        self.showError("Failed to load notifications")
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        print("No notifications found")
                        return
                    }
                    
                    self.notifications = documents.compactMap { document in
                        NotificationModel(dictionary: document.data(), id: document.documentID)
                    }
                    
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
        }
        
        // MARK: - Actions
        
        @objc private func markAllAsRead() {
            let batch = db.batch()
            
            for notification in notifications where !notification.isRead {
                let docRef = db.collection("notifications").document(notification.id)
                batch.updateData(["isRead": true], forDocument: docRef)
            }
            
            batch.commit { [weak self] error in
                if let error = error {
                    print("Error marking all as read: \(error.localizedDescription)")
                    self?.showError("Failed to mark notifications as read")
                }
            }
        }
        
        private func markAsRead(notification: NotificationModel) {
            guard !notification.isRead else { return }
            
            db.collection("notifications")
                .document(notification.id)
                .updateData(["isRead": true]) { error in
                    if let error = error {
                        print("Error marking notification as read: \(error.localizedDescription)")
                    }
                }
        }
        
        private func deleteNotification(at indexPath: IndexPath) {
            let notification = notifications[indexPath.row]
            
            db.collection("notifications")
                .document(notification.id)
                .delete { [weak self] error in
                    if let error = error {
                        print("Error deleting notification: \(error.localizedDescription)")
                        self?.showError("Failed to delete notification")
                    }
                }
        }
        
        private func showError(_ message: String) {
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
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
                ]
            ]
            
            for notification in sampleNotifications {
                db.collection("notifications").addDocument(data: notification) { error in
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
            cell.configure(with: notification)
            
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
                print("Navigate to: \(actionUrl)")
                // TODO: Implement navigation based on actionUrl
            }
            
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        // Swipe to delete
        func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            if editingStyle == .delete {
                deleteNotification(at: indexPath)
            }
        }
}
