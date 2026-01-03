//
//  PushNotificationManager.swift
//  PolyTech
//
//  Created by BP-36-213-19 on 01/01/2026.
//


import Foundation
import UserNotifications
import FirebaseFirestore
import FirebaseAuth

class PushNotificationManager {
    
    static let shared = PushNotificationManager()
    
    private init() {}
    
    // MARK: - Request Notification Permissions
    
    /// Request authorization to show notifications
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("❌ Notification authorization error: \(error.localizedDescription)")
            }
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    // MARK: - Check Authorization Status
    
    /// Check current notification authorization status
    func checkAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }
    
    // MARK: - Schedule Local Push Notification
    
    /// Schedule a local push notification
    /// - Parameters:
    ///   - title: Notification title
    ///   - body: Notification message body
    ///   - timeInterval: Delay before notification fires (default: 1 second)
    ///   - identifier: Unique identifier for the notification
    ///   - userInfo: Additional data to pass with notification
    func scheduleNotification(
        title: String,
        body: String,
        timeInterval: TimeInterval = 1, // Fire after 1 second by default
        identifier: String = UUID().uuidString,
        userInfo: [AnyHashable: Any]? = nil
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        
        if let userInfo = userInfo {
            content.userInfo = userInfo
        }
        
        // Create trigger (fires after specified time interval)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Add notification request
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("✅ Notification scheduled successfully (will fire in \(timeInterval) seconds)")
            }
        }
    }
    
    // MARK: - Create Notification for Request
    
    /// Create a notification in Firestore and schedule a local push notification
    /// - Parameters:
    ///   - requestType: Type of request (e.g., "Inventory", "Maintenance")
    ///   - requestName: Name/title of the request
    ///   - status: Request status ("submitted", "approved", "rejected", "completed")
    ///   - location: Location/room where request is for
    ///   - completion: Callback with success status
    func createNotificationForRequest(
        requestType: String,
        requestName: String,
        status: String = "submitted",
        location: String? = nil,
        completion: @escaping (Bool) -> Void
    ) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No user logged in")
            completion(false)
            return
        }
        
        let db = Firestore.firestore()
        
        // Determine notification content based on status
        let title: String
        let message: String
        let type: String
        
        switch status {
        case "submitted":
            title = "Request Submitted"
            message = "Your \(requestType) request '\(requestName)' has been submitted successfully."
            type = "info"
            
        case "approved":
            title = "Request Approved"
            message = "Your \(requestType) request '\(requestName)' has been approved."
            type = "success"
            
        case "rejected":
            title = "Request Rejected"
            message = "Your \(requestType) request '\(requestName)' has been rejected."
            type = "error"
            
        case "completed":
            title = "Request Completed"
            message = "Your \(requestType) request '\(requestName)' has been completed."
            type = "success"
            
        default:
            title = "Request Updated"
            message = "Your \(requestType) request '\(requestName)' status has been updated."
            type = "info"
        }
        
        // Create notification data for Firestore
        let notificationData: [String: Any] = [
            "userId": userId,
            "title": title,
            "message": message,
            "type": type,
            "timestamp": Timestamp(),
            "isRead": false,
            "actionUrl": "/requests/\(requestType)",
            "room": location ?? ""
        ]
        
        // Save notification to Firestore
        db.collection("Notifications").addDocument(data: notificationData) { error in
            if let error = error {
                print("❌ Error creating notification in Firestore: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            print("✅ Notification saved to Firestore")
            
            // Schedule local push notification
            self.scheduleNotification(
                title: title,
                body: message,
                timeInterval: 1, // 1 second delay
                userInfo: [
                    "requestType": requestType,
                    "requestName": requestName,
                    "status": status
                ]
            )
            
            completion(true)
        }
    }
    
    // MARK: - Notification Management
    
    /// Remove all pending notifications
    func removeAllPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("🗑️ All pending notifications removed")
    }
    
    /// Remove specific notification by identifier
    func removeNotification(withIdentifier identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        print("🗑️ Notification \(identifier) removed")
    }
    
    /// Get count of delivered notifications
    func getDeliveredNotificationsCount(completion: @escaping (Int) -> Void) {
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            DispatchQueue.main.async {
                completion(notifications.count)
            }
        }
    }
    
    /// Clear app badge count
    func clearBadgeCount() {
        UNUserNotificationCenter.current().setBadgeCount(0)
        print("🔵 Badge count cleared")
    }
    
    // MARK: - Debugging Helpers
    
    /// Print all pending notification requests
    func printPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("📋 Pending Notifications: \(requests.count)")
            for request in requests {
                print("   - \(request.identifier): \(request.content.title)")
            }
        }
    }
    
    /// Print all delivered notifications
    func printDeliveredNotifications() {
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            print("📬 Delivered Notifications: \(notifications.count)")
            for notification in notifications {
                print("   - \(notification.request.identifier): \(notification.request.content.title)")
            }
        }
    }
}
