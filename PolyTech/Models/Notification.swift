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
        guard let userId = dictionary["userId"] as? String,
              let title = dictionary["title"] as? String,
              let message = dictionary["message"] as? String,
              let typeString = dictionary["type"] as? String,
              let type = NotificationType(rawValue: typeString),
              let timestamp = dictionary["timestamp"] as? Timestamp else {
            return nil
        }
        
        self.id = id
        self.userId = userId
        self.title = title
        self.message = message
        self.type = type
        self.timestamp = timestamp.dateValue()
        self.isRead = dictionary["isRead"] as? Bool ?? false
        self.actionUrl = dictionary["actionUrl"] as? String
        self.room = dictionary["room"] as? String
    }
}
