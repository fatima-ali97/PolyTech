import Foundation
import FirebaseFirestore

struct NotificationModel {
    let id: String
    let userId: String
    let title: String
    let message: String
    let type: NotificationType
    let timestamp: Date
    let isRead: Bool
    let actionUrl: String?
    let room: String?
    
    enum NotificationType: String {
        case success
        case error
        case fail
        case info
        case message
        case accept
        case location
    }
    
    var displayTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    init?(dictionary: [String: Any], id: String) {
        // ✅ FIXED: More lenient parsing with debug logging
        guard let userId = dictionary["userId"] as? String else {
            print("❌ Missing userId in notification")
            return nil
        }
        
        guard let title = dictionary["title"] as? String else {
            print("❌ Missing title in notification")
            return nil
        }
        
        guard let message = dictionary["message"] as? String else {
            print("❌ Missing message in notification")
            return nil
        }
        
        guard let typeString = dictionary["type"] as? String else {
            print("❌ Missing type in notification")
            return nil
        }
        
        guard let type = NotificationType(rawValue: typeString) else {
            print("❌ Invalid type: \(typeString)")
            return nil
        }
        
        guard let timestamp = dictionary["timestamp"] as? Timestamp else {
            print("❌ Missing or invalid timestamp in notification")
            return nil
        }
        
        // ✅ All required fields present
        self.id = id
        self.userId = userId
        self.title = title
        self.message = message
        self.type = type
        self.timestamp = timestamp.dateValue()
        self.isRead = dictionary["isRead"] as? Bool ?? false
        self.actionUrl = dictionary["actionUrl"] as? String
        self.room = dictionary["room"] as? String
        
        print("✅ Successfully created NotificationModel with ID: \(id)")
    }
}
