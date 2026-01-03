//
//  TechnicianNotificationService.swift
//  PolyTech
//
//  Created by BP-36-213-19 on 03/01/2026.
//


import Foundation
import FirebaseFirestore
import UserNotifications

class TechnicianNotificationService {
    
    static let shared = TechnicianNotificationService()
    
    private let db = Firestore.firestore()
    private var assignmentListener: ListenerRegistration?
    private var notifiedAssignments: Set<String> = []  // Track notified assignments
    
    private init() {}
    
    // MARK: - Start Monitoring Assignments
    
    /// Start monitoring for new assignments (call for technician users)
    func startMonitoringAssignments(technicianId: String) {
        print("🔧 Starting assignment monitoring for technician: \(technicianId)")
        
        // Monitor requests assigned to this technician
        assignmentListener = db.collection("requests")
            .whereField("assignedTechnicianId", isEqualTo: technicianId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error monitoring assignments: \(error.localizedDescription)")
                    return
                }
                
                guard let changes = snapshot?.documentChanges else { return }
                
                for change in changes {
                    // Notify on new assignments or updates
                    if change.type == .added || change.type == .modified {
                        self.handleAssignment(document: change.document, changeType: change.type)
                    }
                }
            }
    }
    
    /// Stop monitoring assignments
    func stopMonitoring() {
        print("🛑 Stopping assignment monitoring")
        assignmentListener?.remove()
        assignmentListener = nil
        notifiedAssignments.removeAll()
    }
    
    // MARK: - Handle Assignment
    
    private func handleAssignment(document: DocumentSnapshot, changeType: DocumentChangeType) {
        let data = document.data() ?? [:]
        let requestId = document.documentID
        
        // Skip if already notified about this assignment
        guard !notifiedAssignments.contains(requestId) else {
            return
        }
        
        guard let requestName = data["requestName"] as? String,
              let technicianName = data["assignedTechnicianName"] as? String,
              let location = data["location"] as? String else {
            print("⚠️ Missing required fields for request: \(requestId)")
            return
        }
        
        let status = data["status"] as? String ?? "pending"
        let urgency = data["urgency"] as? String ?? "normal"
        let category = data["category"] as? String ?? "general"
        
        print("🔔 New assignment detected: '\(requestName)' at \(location)")
        
        // Mark as notified
        notifiedAssignments.insert(requestId)
        
        // Create notification
        createAssignmentNotification(
            requestId: requestId,
            requestName: requestName,
            location: location,
            urgency: urgency,
            category: category,
            status: status
        )
    }
    
    // MARK: - Create Assignment Notification
    
    private func createAssignmentNotification(
        requestId: String,
        requestName: String,
        location: String,
        urgency: String,
        category: String,
        status: String
    ) {
        guard let technicianId = UserDefaults.standard.string(forKey: "userId") else {
            print("❌ No technician ID found")
            return
        }
        
        // Determine notification based on urgency
        let title: String
        let message: String
        let type: String
        
        switch urgency.lowercased() {
        case "high", "urgent":
            title = "🚨 Urgent Assignment!"
            message = "You've been assigned to '\(requestName)' at \(location). High priority - immediate attention required."
            type = "error"
            
        case "medium":
            title = "⚡ New Assignment"
            message = "You've been assigned to '\(requestName)' at \(location). Medium priority."
            type = "info"
            
        default:
            title = "🔧 New Assignment"
            message = "You've been assigned to '\(requestName)' at \(location)."
            type = "info"
        }
        
        let notificationData: [String: Any] = [
            "userId": technicianId,
            "title": title,
            "message": message,
            "type": type,
            "timestamp": Timestamp(),
            "isRead": false,
            "actionUrl": "/technician/requests/\(requestId)",
            "room": location
        ]
        
        // Save to Firestore
        db.collection("Notifications").addDocument(data: notificationData) { error in
            if let error = error {
                print("❌ Error creating assignment notification: \(error.localizedDescription)")
            } else {
                print("✅ Assignment notification created for request: \(requestName)")
            }
        }
        
        // Schedule local push notification
        scheduleLocalNotification(
            title: title,
            message: message,
            requestId: requestId,
            urgency: urgency
        )
    }
    
    // MARK: - Schedule Local Push Notification
    
    private func scheduleLocalNotification(
        title: String,
        message: String,
        requestId: String,
        urgency: String
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = urgency.lowercased() == "high" ? .defaultCritical : .default
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        content.userInfo = [
            "requestId": requestId,
            "notificationType": "technician_assignment",
            "urgency": urgency
        ]
        
        // Add category for interactive actions
        content.categoryIdentifier = "TECHNICIAN_ASSIGNMENT"
        
        // Fire immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "assignment_\(requestId)_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling assignment notification: \(error.localizedDescription)")
            } else {
                print("✅ Assignment push notification scheduled")
            }
        }
    }
    
    // MARK: - Manual Assignment Notification
    
    /// Manually trigger notification when admin assigns technician
    func notifyTechnicianAssignment(
        technicianId: String,
        technicianName: String,
        requestId: String,
        requestName: String,
        location: String,
        urgency: String = "normal",
        category: String = "general"
    ) {
        print("📤 Manually sending assignment notification to: \(technicianName)")
        
        // Determine title and message based on urgency
        let title: String
        let message: String
        let type: String
        
        switch urgency.lowercased() {
        case "high", "urgent":
            title = "🚨 Urgent Assignment!"
            message = "You've been assigned to '\(requestName)' at \(location). High priority - immediate attention required."
            type = "error"
            
        case "medium":
            title = "⚡ New Assignment"
            message = "You've been assigned to '\(requestName)' at \(location). Medium priority."
            type = "info"
            
        default:
            title = "🔧 New Assignment"
            message = "You've been assigned to '\(requestName)' at \(location)."
            type = "info"
        }
        
        let notificationData: [String: Any] = [
            "userId": technicianId,
            "title": title,
            "message": message,
            "type": type,
            "timestamp": Timestamp(),
            "isRead": false,
            "actionUrl": "/technician/requests/\(requestId)",
            "room": location
        ]
        
        // Save to Firestore
        db.collection("Notifications").addDocument(data: notificationData) { error in
            if let error = error {
                print("❌ Error creating manual assignment notification: \(error.localizedDescription)")
            } else {
                print("✅ Manual assignment notification sent to: \(technicianName)")
            }
        }
        
        // Schedule push notification (only if the technician is logged in on this device)
        if let currentUserId = UserDefaults.standard.string(forKey: "userId"),
           currentUserId == technicianId {
            scheduleLocalNotification(
                title: title,
                message: message,
                requestId: requestId,
                urgency: urgency
            )
        }
    }
    
    // MARK: - Setup Notification Actions
    
    /// Setup interactive notification actions for technicians
    func setupNotificationActions() {
        let acceptAction = UNNotificationAction(
            identifier: "ACCEPT_ACTION",
            title: "Accept",
            options: .foreground
        )
        
        let viewAction = UNNotificationAction(
            identifier: "VIEW_ACTION",
            title: "View Details",
            options: .foreground
        )
        
        let category = UNNotificationCategory(
            identifier: "TECHNICIAN_ASSIGNMENT",
            actions: [acceptAction, viewAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        print("✅ Technician notification actions configured")
    }
    
    // MARK: - Clear Tracked Assignments (for testing)
    
    func clearTrackedAssignments() {
        notifiedAssignments.removeAll()
        print("🧹 Cleared tracked assignments")
    }
}