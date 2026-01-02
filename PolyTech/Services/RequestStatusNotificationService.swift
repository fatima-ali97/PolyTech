//
//  RequestStatusNotificationService.swift
//  PolyTech
//
//  Created by BP-36-213-19 on 02/01/2026.
//

import Foundation
import FirebaseFirestore
import UserNotifications

class RequestStatusNotificationService {
    
    static let shared = RequestStatusNotificationService()
    
    private let db = Firestore.firestore()
    private var maintenanceListener: ListenerRegistration?
    private var inventoryListener: ListenerRegistration?
    
    private init() {}
    
    // MARK: - Start Monitoring
    
    /// Start listening for status changes on user's requests
    func startMonitoring(userId: String) {
        print("🔔 Starting request status monitoring for user: \(userId)")
        
        // Monitor Maintenance Requests
        startMaintenanceMonitoring(userId: userId)
        
        // Monitor Inventory Requests
        startInventoryMonitoring(userId: userId)
    }
    
    /// Stop monitoring when user logs out or app closes
    func stopMonitoring() {
        print("🔕 Stopping request status monitoring")
        maintenanceListener?.remove()
        inventoryListener?.remove()
        maintenanceListener = nil
        inventoryListener = nil
    }
    
    // MARK: - Maintenance Request Monitoring
    
    private func startMaintenanceMonitoring(userId: String) {
        maintenanceListener = db.collection("maintenanceRequest")
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error monitoring maintenance requests: \(error.localizedDescription)")
                    return
                }
                
                guard let changes = querySnapshot?.documentChanges else { return }
                
                for change in changes {
                    if change.type == .modified {
                        self.handleMaintenanceStatusChange(document: change.document)
                    }
                }
            }
    }
    
    private func handleMaintenanceStatusChange(document: DocumentSnapshot) {
        let data = document.data() ?? [:]
        
        guard let requestName = data["requestName"] as? String,
              let location = data["location"] as? String,
              let status = data["status"] as? String else {
            return
        }
        
        print("📝 Maintenance request '\(requestName)' status changed to: \(status)")
        
        // Create notification based on status
        let notification = createStatusNotification(
            requestType: "Maintenance",
            requestName: requestName,
            location: location,
            status: status
        )
        
        // Save to Firestore Notifications collection
        saveNotificationToFirestore(notification)
        
        // Schedule local push notification
        scheduleLocalNotification(notification)
    }
    
    // MARK: - Inventory Request Monitoring
    
    private func startInventoryMonitoring(userId: String) {
        inventoryListener = db.collection("inventoryRequest")
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error monitoring inventory requests: \(error.localizedDescription)")
                    return
                }
                
                guard let changes = querySnapshot?.documentChanges else { return }
                
                for change in changes {
                    if change.type == .modified {
                        self.handleInventoryStatusChange(document: change.document)
                    }
                }
            }
    }
    
    private func handleInventoryStatusChange(document: DocumentSnapshot) {
        let data = document.data() ?? [:]
        
        guard let requestName = data["requestName"] as? String,
              let location = data["location"] as? String,
              let status = data["status"] as? String else {
            return
        }
        
        print("📦 Inventory request '\(requestName)' status changed to: \(status)")
        
        // Create notification based on status
        let notification = createStatusNotification(
            requestType: "Inventory",
            requestName: requestName,
            location: location,
            status: status
        )
        
        // Save to Firestore Notifications collection
        saveNotificationToFirestore(notification)
        
        // Schedule local push notification
        scheduleLocalNotification(notification)
    }
    
    // MARK: - Create Notification
    
    private func createStatusNotification(
        requestType: String,
        requestName: String,
        location: String,
        status: String
    ) -> StatusNotification {
        
        let title: String
        let message: String
        let type: String
        
        switch status.lowercased() {
        case "in_progress", "in progress", "inprogress":
            title = "Work Started 🔧"
            message = "Your \(requestType) request '\(requestName)' is now in progress."
            type = "info"
            
        case "completed", "complete", "done":
            title = "Request Completed ✓"
            message = "Your \(requestType) request '\(requestName)' has been completed."
            type = "success"
            
        case "approved", "approve":
            title = "Request Approved ✓"
            message = "Your \(requestType) request '\(requestName)' has been approved."
            type = "success"
            
        case "rejected", "reject", "declined":
            title = "Request Rejected"
            message = "Your \(requestType) request '\(requestName)' has been rejected."
            type = "error"
            
        case "pending", "waiting":
            title = "Request Pending"
            message = "Your \(requestType) request '\(requestName)' is pending review."
            type = "info"
            
        case "cancelled", "canceled":
            title = "Request Cancelled"
            message = "Your \(requestType) request '\(requestName)' has been cancelled."
            type = "error"
            
        default:
            title = "Request Updated"
            message = "Your \(requestType) request '\(requestName)' status: \(status)"
            type = "info"
        }
        
        return StatusNotification(
            requestType: requestType,
            requestName: requestName,
            location: location,
            status: status,
            title: title,
            message: message,
            type: type
        )
    }
    
    // MARK: - Save to Firestore
    
    private func saveNotificationToFirestore(_ notification: StatusNotification) {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            print("❌ No userId found")
            return
        }
        
        let notificationData: [String: Any] = [
            "userId": userId,
            "title": notification.title,
            "message": notification.message,
            "type": notification.type,
            "timestamp": Timestamp(),
            "isRead": false,
            "actionUrl": "/requests/\(notification.requestType)",
            "room": notification.location
        ]
        
        db.collection("Notifications").addDocument(data: notificationData) { error in
            if let error = error {
                print("❌ Error saving notification: \(error.localizedDescription)")
            } else {
                print("✅ Notification saved to Firestore")
            }
        }
    }
    
    // MARK: - Schedule Local Push Notification
    
    private func scheduleLocalNotification(_ notification: StatusNotification) {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.message
        content.sound = .default
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        content.userInfo = [
            "requestType": notification.requestType,
            "requestName": notification.requestName,
            "status": notification.status
        ]
        
        // Fire immediately (or use timeInterval for delay)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("✅ Local push notification scheduled")
            }
        }
    }
}

