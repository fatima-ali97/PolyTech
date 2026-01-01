import Foundation
import FirebaseFirestore

struct MaintenanceRequestModel: Codable {
    
    // MARK: - Properties
    let id: String
    var category: String
    var requestName: String
    var location: String
    var urgency: UrgencyLevel
    let createdAt: Timestamp
    var updatedAt: Timestamp
    var imageUrl: String?  // ✅ Added to support image display
    
    // MARK: - Urgency Enum
    enum UrgencyLevel: String, Codable {
        case low
        case medium
        case high
    }
    
    // MARK: - Firestore Initializer
    init?(dictionary: [String: Any], id: String) {
        print("🔍 Parsing MaintenanceRequest document: \(id)")
        print("📄 Raw data: \(dictionary)")
        
        guard
            let category = dictionary["category"] as? String,
            let requestName = dictionary["requestName"] as? String,
            let location = dictionary["location"] as? String,
            let urgencyString = dictionary["urgency"] as? String,
            let urgency = UrgencyLevel(rawValue: urgencyString),
            let createdAt = dictionary["createdAt"] as? Timestamp,
            let updatedAt = dictionary["updatedAt"] as? Timestamp
        else {
            print("❌ Failed to parse MaintenanceRequest \(id)")
            return nil
        }
        
        self.id = id
        self.category = category
        self.requestName = requestName
        self.location = location
        self.urgency = urgency
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.imageUrl = dictionary["imageUrl"] as? String  // ✅ Safely unwrap imageUrl
        
        print("✅ Successfully parsed MaintenanceRequest: \(requestName)")
    }
    
    // MARK: - Convert to Firestore Dictionary
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "category": category,
            "requestName": requestName,
            "location": location,
            "urgency": urgency.rawValue,
            "createdAt": createdAt,
            "updatedAt": updatedAt
        ]
        
        if let imageUrl = imageUrl {
            dict["imageUrl"] = imageUrl  // ✅ Include imageUrl if present
        }
        
        return dict
    }
    
    // MARK: - Computed Properties
    
    var createdTimeText: String {
        let date = createdAt.dateValue()
        let now = Date()
        let components = Calendar.current.dateComponents([.day, .hour, .minute], from: date, to: now)
        
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
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt.dateValue())
    }
    
    var urgencyIcon: String {
        switch urgency {
        case .low:
            return "checkmark.circle.fill"
        case .medium:
            return "exclamationmark.circle.fill"
        case .high:
            return "exclamationmark.triangle.fill"
        }
    }
    
    var categoryIcon: String {
        switch category.lowercased() {
        case "software_issue":
            return "exclamationmark.triangle.fill"
        case "hardware_issue":
            return "wrench.and.screwdriver.fill"
        case "network_issue":
            return "wifi.exclamationmark"
        case "facility_issue":
            return "building.2.fill"
        default:
            return "exclamationmark.circle.fill"
        }
    }
}
