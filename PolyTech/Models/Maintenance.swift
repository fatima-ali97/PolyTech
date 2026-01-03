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
    var imageUrl: String?
    var userId: String?
    var status: String
    var technicianID: String
    var declinedBy: [String]
    
    // MARK: - Urgency Enum
    enum UrgencyLevel: String, Codable {
        case low
        case medium
        case high
    }
    
    // MARK: - Firestore Initializer
    init?(dictionary: [String: Any], id: String) {
        guard
            let category = dictionary["category"] as? String,
            let requestName = dictionary["requestName"] as? String,
            let urgencyString = dictionary["urgency"] as? String,
            let urgency = UrgencyLevel(rawValue: urgencyString),
            let createdAt = dictionary["createdAt"] as? Timestamp,
            let updatedAt = dictionary["updatedAt"] as? Timestamp
        else {
            print("❌ Failed to parse MaintenanceRequest \(id)")
            print("📦 Raw data: \(dictionary)")
            return nil
        }
        
        self.id = id
        self.category = category
        self.requestName = requestName
        self.urgency = urgency
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.imageUrl = dictionary["imageUrl"] as? String
        self.userId = dictionary["userId"] as? String
        self.status = dictionary["status"] as? String ?? "Pending"
        self.technicianID = dictionary["technicianID"] as? String ?? ""
        self.declinedBy = dictionary["declinedBy"] as? [String] ?? []
        
        // Handle location saved as String or Int
        if let locStr = dictionary["location"] as? String {
            self.location = locStr
        } else if let locInt = dictionary["location"] as? Int {
            self.location = String(locInt)
        } else {
            self.location = "Unknown"
        }
    }
    
    // MARK: - Convert to Firestore Dictionary
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "category": category,
            "requestName": requestName,
            "location": location,
            "urgency": urgency.rawValue,
            "createdAt": createdAt,
            "updatedAt": updatedAt,
            "status": status,
            "technicianID": technicianID,
            "declinedBy": declinedBy
        ]
        if let imageUrl = imageUrl { dict["imageUrl"] = imageUrl }
        if let userId = userId { dict["userId"] = userId }
        return dict
    }
    
    // MARK: - Computed Properties
    var createdTimeText: String {
        let date = createdAt.dateValue()
        let now = Date()
        let comp = Calendar.current.dateComponents([.day, .hour, .minute], from: date, to: now)
        if let day = comp.day, day > 0 { return "\(day)d ago" }
        if let hour = comp.hour, hour > 0 { return "\(hour)h ago" }
        if let minute = comp.minute, minute > 0 { return "\(minute)m ago" }
        return "Just now"
    }
    
    var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: createdAt.dateValue())
    }
    
    var urgencyIcon: String {
        switch urgency {
        case .low: return "checkmark.circle.fill"
        case .medium: return "exclamationmark.circle.fill"
        case .high: return "exclamationmark.triangle.fill"
        }
    }
    
    var categoryIcon: String {
        switch category.lowercased() {
        case "software_issue": return "exclamationmark.triangle.fill"
        case "hardware_issue": return "wrench.and.screwdriver.fill"
        case "network_issue": return "wifi.exclamationmark"
        case "facility_issue": return "building.2.fill"
        default: return "exclamationmark.circle.fill"
        }
    }
}
