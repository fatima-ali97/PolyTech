//
//  EnhancedNotificationService.swift
//  PolyTech
//
//  Created by BP-36-213-19 on 03/01/2026.
//


import Foundation
import FirebaseFirestore
import FirebaseAuth

class EnhancedNotificationService {
    
    static let shared = EnhancedNotificationService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Create Notifications for Multiple Users
    
    /// Creates notifications for both the requester and all admins
    func createInventoryRequestNotifications(
        requestId: String,
        requestName: String,
        itemName: String,
        location: String,
        requesterId: String,
        status: String
    ) {
        // 1. Create notification for the REQUESTER (student)
        createNotificationForRequester(
            requestId: requestId,
            requestName: requestName,
            itemName: itemName,
            location: location,
            requesterId: requesterId,
            status: status
        )
        
        // 2. Create notifications for ALL ADMINS
        createNotificationsForAdmins(
            requestId: requestId,
            requestName: requestName,
            itemName: itemName,
            location: location,
            requesterName: getUserName(userId: requesterId),
            status: status
        )
    }
    
    // MARK: - Requester Notification
    
    private func createNotificationForRequester(
        requestId: String,
        requestName: String,
        itemName: String,
        location: String,
        requesterId: String,
        status: String
    ) {
        let notificationData: [String: Any] = [
            "userId": requesterId,
            "title": "Request Submitted",
            "message": "Your inventory request '\(itemName)' has been submitted successfully.",
            "type": "info",
            "timestamp": Timestamp(),
            "isRead": false,
            "actionUrl": "/requests/inventory",
            "room": location,
            "requestId": requestId,
            "requestType": "inventory"
        ]
        
        db.collection("Notifications").addDocument(data: notificationData) { error in
            if let error = error {
                print("❌ Error creating requester notification: \(error.localizedDescription)")
            } else {
                print("✅ Requester notification created for userId: \(requesterId)")
            }
        }
    }
    
    // MARK: - Admin Notifications
    
    private func createNotificationsForAdmins(
        requestId: String,
        requestName: String,
        itemName: String,
        location: String,
        requesterName: String,
        status: String
    ) {
        // Query all users with admin or technician role
        db.collection("users")
            .whereField("role", in: ["admin", "technician"])
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error fetching admins: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("⚠️ No admins found")
                    return
                }
                
                print("📊 Found \(documents.count) admin/technician users")
                
                // Create notification for each admin
                for document in documents {
                    let adminId = document.documentID
                    self.createNotificationForAdmin(
                        adminId: adminId,
                        requestId: requestId,
                        requestName: requestName,
                        itemName: itemName,
                        location: location,
                        requesterName: requesterName
                    )
                }
            }
    }
    
    private func createNotificationForAdmin(
        adminId: String,
        requestId: String,
        requestName: String,
        itemName: String,
        location: String,
        requesterName: String
    ) {
        let notificationData: [String: Any] = [
            "userId": adminId,
            "title": "New Inventory Request",
            "message": "\(requesterName) requested '\(itemName)' at \(location)",
            "type": "info",
            "timestamp": Timestamp(),
            "isRead": false,
            "actionUrl": "/requests/inventory",
            "room": location,
            "requestId": requestId,
            "requestType": "inventory"
        ]
        
        db.collection("Notifications").addDocument(data: notificationData) { error in
            if let error = error {
                print("❌ Error creating admin notification: \(error.localizedDescription)")
            } else {
                print("✅ Admin notification created for userId: \(adminId)")
            }
        }
    }
    
    // MARK: - Status Update Notifications
    
    /// Creates notifications when request status changes (approved, rejected, completed)
    func createStatusUpdateNotifications(
        requestId: String,
        requestName: String,
        location: String,
        requesterId: String,
        newStatus: String,
        requestType: String = "inventory"
    ) {
        let (requesterTitle, requesterMessage, notificationType) = getRequesterStatusMessage(status: newStatus, requestName: requestName)
        
        // Notification for requester
        let requesterNotificationData: [String: Any] = [
            "userId": requesterId,
            "title": requesterTitle,
            "message": requesterMessage,
            "type": notificationType,
            "timestamp": Timestamp(),
            "isRead": false,
            "actionUrl": "/requests/\(requestType)",
            "room": location,
            "requestId": requestId,
            "requestType": requestType
        ]
        
        db.collection("Notifications").addDocument(data: requesterNotificationData) { error in
            if let error = error {
                print("❌ Error creating status update notification: \(error.localizedDescription)")
            } else {
                print("✅ Status update notification created for requester")
            }
        }
        
        // Also notify admins about status change
        notifyAdminsAboutStatusChange(
            requestId: requestId,
            requestName: requestName,
            location: location,
            newStatus: newStatus,
            requestType: requestType
        )
    }
    
    private func notifyAdminsAboutStatusChange(
        requestId: String,
        requestName: String,
        location: String,
        newStatus: String,
        requestType: String
    ) {
        db.collection("users")
            .whereField("role", in: ["admin", "technician"])
            .getDocuments { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                for document in documents {
                    let adminId = document.documentID
                    
                    let notificationData: [String: Any] = [
                        "userId": adminId,
                        "title": "Request Status Updated",
                        "message": "Request '\(requestName)' is now \(newStatus)",
                        "type": "info",
                        "timestamp": Timestamp(),
                        "isRead": false,
                        "actionUrl": "/requests/\(requestType)",
                        "room": location,
                        "requestId": requestId,
                        "requestType": requestType
                    ]
                    
                    self?.db.collection("Notifications").addDocument(data: notificationData)
                }
            }
    }
    
    // MARK: - Helper Methods
    
    private func getRequesterStatusMessage(status: String, requestName: String) -> (title: String, message: String, type: String) {
        switch status.lowercased() {
        case "approved", "accepted":
            return (
                "Request Approved ✓",
                "Your request '\(requestName)' has been approved!",
                "accept"
            )
        case "rejected", "declined":
            return (
                "Request Declined",
                "Your request '\(requestName)' has been declined.",
                "error"
            )
        case "completed", "done":
            return (
                "Request Completed ✓",
                "Your request '\(requestName)' has been completed successfully.",
                "success"
            )
        case "in_progress", "processing":
            return (
                "Request In Progress",
                "Your request '\(requestName)' is being processed.",
                "info"
            )
        default:
            return (
                "Status Updated",
                "Your request '\(requestName)' status has changed to \(status).",
                "info"
            )
        }
    }
    
    private func getUserName(userId: String) -> String {
        // This is synchronous - in production, you'd want to fetch this asynchronously
        // or pass it as a parameter
        var userName = "User"
        
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let data = snapshot?.data(),
               let name = data["name"] as? String {
                userName = name
            }
        }
        
        return userName
    }
}

// MARK: - Usage Extension for NewInventoryViewController

//extension NewInventoryViewController {
//    
//    func createRequestWithNotifications(data: [String: Any]) {
//        var newData = data
//        newData["createdAt"] = Timestamp()
//        newData["status"] = "pending"
//        
//        guard let userId = Auth.auth().currentUser?.uid else { return }
//        newData["userId"] = userId
//        
//        let collectionRef = database.collection("inventoryRequest")
//        let docRef = collectionRef.document()
//        let requestId = docRef.documentID
//        
//        docRef.setData(newData) { [weak self] error in
//            guard let self = self else { return }
//            
//            if let error = error {
//                //self.showAlert("Error saving request: \(error.localizedDescription)")
//                return
//            }
//            
//            print("✅ Inventory request saved to Firestore")
//            
//            // 🔔 Create notifications for BOTH requester and admins
//            EnhancedNotificationService.shared.createInventoryRequestNotifications(
//                requestId: requestId,
//                requestName: self.itemName.text ?? "Item",
//                itemName: self.itemName.text ?? "Item",
//                location: self.location.text ?? "",
//                requesterId: userId,
//                status: "submitted"
//            )
//            
//            // 🤖 Auto-assign technician
//            AutoAssignmentService.shared.autoAssignTechnician(
//                requestId: requestId,
//                requestType: "inventory",
//                category: self.selectedCategory?.rawValue ?? "general",
//                location: self.location.text ?? "",
//                urgency: "normal"
//            ) { success, errorMessage in
//                if !success {
//                    print("⚠️ Auto-assign failed: \(errorMessage ?? "unknown error")")
//                }
//            }
//            
//            // Show success message
//            let alert = UIAlertController(
//                title: "Success",
//                message: "Inventory request created successfully ✅\n\nBoth you and the admin team have been notified.",
//                preferredStyle: .alert
//            )
//            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
//                self.navigationController?.popViewController(animated: true)
//            })
//            self.present(alert, animated: true)
//        }
//    }
//}

// MARK: - Usage for Status Updates (e.g., from Admin Dashboard)
//
//extension AdminRequestViewController {
//    
//    func updateRequestStatus(requestId: String, newStatus: String, requesterId: String) {
//        // Update the request status in Firestore
//        db.collection("inventoryRequest")
//            .document(requestId)
//            .updateData(["status": newStatus]) { error in
//                if let error = error {
//                    print("❌ Error updating status: \(error.localizedDescription)")
//                    return
//                }
//                
//                // 🔔 Notify BOTH requester and admins about status change
//                EnhancedNotificationService.shared.createStatusUpdateNotifications(
//                    requestId: requestId,
//                    requestName: "Inventory Item", // You'd pass the actual request name
//                    location: "Location", // You'd pass the actual location
//                    requesterId: requesterId,
//                    newStatus: newStatus,
//                    requestType: "inventory"
//                )
//                
//                print("✅ Status updated and notifications sent")
//            }
//    }
//}
