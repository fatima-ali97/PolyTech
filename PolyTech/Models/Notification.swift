import Foundation
import FirebaseFirestore

struct NotificationModel: Codable {
    var id: String
    var userId: String
    var title: String
    var message: String
    var type: NotificationType
    var iconName: String
    var isRead: Bool
    var timestamp: Timestamp
    var actionUrl: String?
    var metadata: [String: String]?
    
    enum NotificationType: String, Codable {
        case success = "success"
        case error = "error"
        case warning = "warning"
        case info = "info"
        case message = "message"
        case like = "like"
        case comment = "comment"
        case follow = "follow"
    }
    
    // Computed property for display date
    var displayTime: String {
        let date = timestamp.dateValue()
        let now = Date()
        let calendar = Calendar.current
        
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let day = components.day, day > 0 {
            return "\(day)d ago"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)h ago"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)m ago"
        } else {
            return "Just now"
        }
    }
    
    // Convert Firestore document to model - WITH OPTIONAL iconName
    init?(dictionary: [String: Any], id: String) {
        guard let userId = dictionary["userId"] as? String,
              let title = dictionary["title"] as? String,
              let message = dictionary["message"] as? String,
              let typeString = dictionary["type"] as? String,
              let type = NotificationType(rawValue: typeString),
              let isRead = dictionary["isRead"] as? Bool,
              let timestamp = dictionary["timestamp"] as? Timestamp else {
            print(" Failed to parse notification - missing required fields")
            print("   userId: \(dictionary["userId"] ?? "nil")")
            print("   title: \(dictionary["title"] ?? "nil")")
            print("   message: \(dictionary["message"] ?? "nil")")
            print("   type: \(dictionary["type"] ?? "nil")")
            print("   isRead: \(dictionary["isRead"] ?? "nil")")
            print("   timestamp: \(dictionary["timestamp"] ?? "nil")")
            return nil
        }
        
        self.id = id
        self.userId = userId
        self.title = title
        self.message = message
        self.type = type
        // Make iconName optional with a default based on type
        self.iconName = dictionary["iconName"] as? String ?? NotificationModel.defaultIcon(for: type)
        self.isRead = isRead
        self.timestamp = timestamp
        self.actionUrl = dictionary["actionUrl"] as? String
        self.metadata = dictionary["metadata"] as? [String: String]
    }
    
    // Helper function to get default icon based on notification type
    private static func defaultIcon(for type: NotificationType) -> String {
        switch type {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "xmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .info:
            return "info.circle.fill"
        case .message:
            return "envelope.fill"
        case .like:
            return "heart.fill"
        case .comment:
            return "bubble.left.fill"
        case .follow:
            return "location.fill"
        }
    }
    
    // Convert model to Firestore dictionary
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "userId": userId,
            "title": title,
            "message": message,
            "type": type.rawValue,
            "iconName": iconName,
            "isRead": isRead,
            "timestamp": timestamp
        ]
        
        if let actionUrl = actionUrl {
            dict["actionUrl"] = actionUrl
        }
        
        if let metadata = metadata {
            dict["metadata"] = metadata
        }
        
        return dict
    }
}
