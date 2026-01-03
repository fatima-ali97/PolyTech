import Foundation
import FirebaseFirestore
import UserNotifications

class DelayedRequestNotificationService {
    
    static let shared = DelayedRequestNotificationService()
    
    private let db = Firestore.firestore()
    private var delayedRequestsListener: ListenerRegistration?
    private var trackedDelayedRequests: Set<String> = []
    
    private let delayedAfterDays: Int = 3
    
    private init() {}
    
    // MARK: - Start Monitoring Delayed Requests
    
    /// Start monitoring for delayed requests (call this for admin users)
    func startMonitoringDelayedRequests() {
        print("⏰ Starting delayed request monitoring")
        
        // TEMPORARY: Monitor ALL pending requests, filter in memory
        // This avoids needing a composite index while it's being built
        delayedRequestsListener = db.collection("maintenanceRequest")
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error monitoring delayed requests: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("⚠️ No documents found")
                    return
                }
                
                print("📊 Found \(documents.count) pending requests, filtering for delayed ones...")
                
                let cutoffDate = Calendar.current.date(byAdding: .day, value: -self.delayedAfterDays, to: Date())!
                
                // Filter in memory for requests older than cutoff
                let delayedDocs = documents.filter { doc in
                    guard let createdAt = doc.data()["createdAt"] as? Timestamp else {
                        return false
                    }
                    return createdAt.dateValue() <= cutoffDate
                }
                
                print("📊 Found \(delayedDocs.count) delayed pending requests")
                
                for document in delayedDocs {
                    self.handleNewDelayedRequest(document: document)
                }
            }
    }
    
    /// Stop monitoring delayed requests
    func stopMonitoring() {
        print("🛑 Stopping delayed request monitoring")
        delayedRequestsListener?.remove()
        delayedRequestsListener = nil
        trackedDelayedRequests.removeAll()
    }
    
    // MARK: - Handle New Delayed Request
    
    private func handleNewDelayedRequest(document: DocumentSnapshot) {
        let data = document.data() ?? [:]
        let requestId = document.documentID
        
        print("\n🔍 Processing delayed request: \(requestId)")
        print("   Request data: \(data)")
        
        // Skip if already notified about this request
        guard !trackedDelayedRequests.contains(requestId) else {
            print("⏭️ Already notified about request: \(requestId)")
            return
        }
        
        // Double-check status is pending
        let status = (data["status"] as? String ?? "").lowercased()
        guard status == "pending" else {
            print("⏭️ Skipping non-pending request: \(requestId) - status: \(status)")
            return
        }
        
        guard let requestName = data["requestName"] as? String,
              let createdAt = data["createdAt"] as? Timestamp else {
            print("⚠️ Missing required fields for request: \(requestId)")
            print("   requestName: \(data["requestName"] ?? "nil")")
            print("   createdAt: \(data["createdAt"] ?? "nil")")
            return
        }
        
        let location = data["location"] as? String ?? "Unknown location"
        let userId = data["userId"] as? String ?? ""
        
        print("   Request name: \(requestName)")
        print("   Location: \(location)")
        print("   UserId: \(userId)")
        
        // Calculate how many days delayed
        let daysDelayed = calculateDaysDelayed(from: createdAt.dateValue())
        
        // Only process if actually delayed (3+ days)
        guard daysDelayed >= delayedAfterDays else {
            print("⏭️ Request not yet delayed enough: \(requestId) - only \(daysDelayed) days old")
            return
        }
        
        print("⏰ New delayed request detected: '\(requestName)' - \(daysDelayed) days old")
        
        // Mark as tracked
        trackedDelayedRequests.insert(requestId)
        
        // Create notification for the student who submitted the request
        if !userId.isEmpty {
            print("📝 Creating student notification for userId: \(userId)")
            createDelayedRequestNotification(
                requestId: requestId,
                requestName: requestName,
                location: location,
                daysDelayed: daysDelayed,
                userId: userId
            )
        } else {
            print("⚠️ No userId found in request - cannot create student notification")
        }
        
        // Create notification for admin
        print("📝 Creating admin notifications...")
        createAdminDelayedNotification(
            requestId: requestId,
            requestName: requestName,
            location: location,
            daysDelayed: daysDelayed
        )
    }
    
    // MARK: - Calculate Days Delayed
    
    private func calculateDaysDelayed(from date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: date, to: Date())
        return components.day ?? 0
    }
    
    // MARK: - Create Student Notification
    
    private func createDelayedRequestNotification(
        requestId: String,
        requestName: String,
        location: String,
        daysDelayed: Int,
        userId: String
    ) {
        let title = "Request Delayed ⏰"
        let message = "Your request '\(requestName)' has been pending for \(daysDelayed) days. We apologize for the delay."
        let type = "info"
        
        let notificationData: [String: Any] = [
            "userId": userId,
            "title": title,
            "message": message,
            "type": type,
            "timestamp": Timestamp(),
            "isRead": false,
            "actionUrl": "/requests/delayed",
            "room": location
        ]
        
        print("📝 Creating notification for user: \(userId)")
        print("📝 Notification data: \(notificationData)")
        
        db.collection("Notifications").addDocument(data: notificationData) { error in
            if let error = error {
                print("❌ Error creating student delayed notification: \(error.localizedDescription)")
            } else {
                print("✅ Student delayed notification created for request: \(requestName)")
                print("✅ Notification should appear for userId: \(userId)")
            }
        }
        
        // Schedule local push notification for student
        scheduleLocalNotification(
            title: title,
            message: message,
            requestId: requestId,
            userType: "student"
        )
    }
    
    // MARK: - Create Admin Notification
    
    private func createAdminDelayedNotification(
        requestId: String,
        requestName: String,
        location: String,
        daysDelayed: Int
    ) {
        // Get all admin users
        db.collection("users")
            .whereField("role", isEqualTo: "admin")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error fetching admin users: \(error.localizedDescription)")
                    return
                }
                
                let adminUsers = snapshot?.documents ?? []
                print("👥 Found \(adminUsers.count) admin users to notify")
                
                for adminDoc in adminUsers {
                    let adminId = adminDoc.documentID
                    print("📝 Creating notification for admin: \(adminId)")
                    
                    let title = "Delayed Request Alert ⚠️"
                    let message = "Request '\(requestName)' has been pending for \(daysDelayed) days at \(location). Action required."
                    let type = "info"
                    
                    let notificationData: [String: Any] = [
                        "userId": adminId,
                        "title": title,
                        "message": message,
                        "type": type,
                        "timestamp": Timestamp(),
                        "isRead": false,
                        "actionUrl": "/admin/delayed-requests",
                        "room": location
                    ]
                    
                    print("📝 Admin notification data: \(notificationData)")
                    
                    self.db.collection("Notifications").addDocument(data: notificationData) { error in
                        if let error = error {
                            print("❌ Error creating admin notification: \(error.localizedDescription)")
                        } else {
                            print("✅ Admin notification created for delayed request: \(requestName)")
                            print("✅ Notification should appear for adminId: \(adminId)")
                        }
                    }
                }
                
                // Schedule local push notification for current admin
                if let currentUserId = UserDefaults.standard.string(forKey: "userId"),
                   let currentUserRole = UserDefaults.standard.string(forKey: "userRole"),
                   currentUserRole == "admin" {
                    
                    print("📱 Current user is admin (\(currentUserId)), scheduling local notification")
                    
                    let title = "Delayed Request Alert ⚠️"
                    let message = "Request '\(requestName)' has been pending for \(daysDelayed) days. Action required."
                    
                    self.scheduleLocalNotification(
                        title: title,
                        message: message,
                        requestId: requestId,
                        userType: "admin"
                    )
                } else {
                    print("⚠️ Current user is not admin or userId not found")
                }
            }
    }
    
    // MARK: - Schedule Local Push Notification
    
    private func scheduleLocalNotification(
        title: String,
        message: String,
        requestId: String,
        userType: String
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        content.userInfo = [
            "requestId": requestId,
            "notificationType": "delayed_request",
            "userType": userType
        ]
        
        // Fire immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "delayed_\(requestId)_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling delayed notification: \(error.localizedDescription)")
            } else {
                print("✅ Delayed request push notification scheduled")
            }
        }
    }
    
    // MARK: - Manual Check for Delayed Requests
    
    /// Manually check for delayed requests (call this when DelayedRequestsViewController loads)
    func checkForDelayedRequests(completion: @escaping (Int) -> Void) {
        print("🔍 Checking for delayed requests...")
        
        // TEMPORARY: Fetch all pending requests, filter in memory
        // This avoids needing a composite index while it's being built
        db.collection("maintenanceRequest")
            .whereField("status", isEqualTo: "pending")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error checking delayed requests: \(error.localizedDescription)")
                    completion(0)
                    return
                }
                
                let documents = snapshot?.documents ?? []
                print("📊 Query returned \(documents.count) pending requests")
                
                let cutoffDate = Calendar.current.date(byAdding: .day, value: -self.delayedAfterDays, to: Date())!
                print("🔍 Filtering for requests older than \(cutoffDate)")
                
                // Filter in memory for requests older than 3 days
                let delayedRequests = documents.filter { doc in
                    let data = doc.data()
                    guard let createdAt = data["createdAt"] as? Timestamp else {
                        return false
                    }
                    let daysDelayed = self.calculateDaysDelayed(from: createdAt.dateValue())
                    return daysDelayed >= self.delayedAfterDays
                }
                
                let count = delayedRequests.count
                print("📊 Found \(count) truly delayed requests (3+ days old)")
                
                // Process each delayed request
                for document in delayedRequests {
                    self.handleNewDelayedRequest(document: document)
                }
                
                completion(count)
            }
    }
    
    // MARK: - Clear Tracked Requests (for testing)
    
    /// Clear the tracked requests set (useful for testing)
    func clearTrackedRequests() {
        trackedDelayedRequests.removeAll()
        print("🧹 Cleared tracked delayed requests")
    }
}
