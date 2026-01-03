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
    
    var displayTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    enum NotificationType: String {
        case success = "success"
        case error = "error"
        case fail = "fail"
        case info = "info"
        case message = "message"
        case accept = "accept"
        case location = "location"
        
        init?(rawValue: String) {
            switch rawValue.lowercased() {
            case "success":
                self = .success
            case "error":
                self = .error
            case "fail":
                self = .fail
            case "info":
                self = .info
            case "message":
                self = .message
            case "accept":
                self = .accept
            case "location":
                self = .location
            default:
                return nil
            }
        }
    }
    
    // MARK: - Initialize from Firestore Document
    
    init?(dictionary: [String: Any], id: String) {
        // Document ID is passed separately
        self.id = id
        
        // Parse required fields
        guard let userId = dictionary["userId"] as? String,
              let title = dictionary["title"] as? String,
              let message = dictionary["message"] as? String,
              let typeString = dictionary["type"] as? String,
              let type = NotificationType(rawValue: typeString) else {
            print("❌ Failed to parse notification - missing required fields")
            print("   Document ID: \(id)")
            print("   Data: \(dictionary)")
            return nil
        }
        
        self.userId = userId
        self.title = title
        self.message = message
        self.type = type
        
        // Parse timestamp
        if let timestamp = dictionary["timestamp"] as? Timestamp {
            self.timestamp = timestamp.dateValue()
        } else if let timestamp = dictionary["timestamp"] as? Date {
            self.timestamp = timestamp
        } else {
            print("⚠️ No timestamp found, using current date")
            self.timestamp = Date()
        }
        
        // Parse optional fields
        self.isRead = dictionary["isRead"] as? Bool ?? false
        self.actionUrl = dictionary["actionUrl"] as? String
        self.room = dictionary["room"] as? String
        
        print("✅ Successfully parsed notification:")
        print("   ID: \(id)")
        print("   Title: \(title)")
        print("   Type: \(type.rawValue)")
        print("   IsRead: \(isRead)")
    }
    
    // MARK: - Convert to Dictionary (for creating new notifications)
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "userId": userId,
            "title": title,
            "message": message,
            "type": type.rawValue,
            "timestamp": Timestamp(date: timestamp),
            "isRead": isRead
        ]
        
        if let actionUrl = actionUrl {
            dict["actionUrl"] = actionUrl
        }
        
        if let room = room {
            dict["room"] = room
        }
        
        return dict
    }
}
