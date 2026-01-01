import Foundation
import FirebaseFirestore

struct Inventory: Codable {
    
    // MARK: - Properties
    let id: String
    var category: String
    var itemName: String
    var location: String
    var quantity: Int
    var reason: String
    var requestName: String
    var userId: String
    let createdAt: Timestamp
    var updatedAt: Timestamp
    
    // MARK: - Firestore Initializer
    init?(dictionary: [String: Any], id: String) {
        guard
            let category = dictionary["category"] as? String,
            let itemName = dictionary["itemName"] as? String,
            let location = dictionary["location"] as? String,
            let quantity = dictionary["quantity"] as? Int,
            let reason = dictionary["reason"] as? String,
            let requestName = dictionary["requestName"] as? String,
            let userId = dictionary["userId"] as? String,
            let createdAt = dictionary["createdAt"] as? Timestamp,
            let updatedAt = dictionary["updatedAt"] as? Timestamp
        else {
            print("❌ Failed to parse Inventory \(id)")
            print("📦 Raw data: \(dictionary)")
            return nil
        }
        
        self.id = id
        self.category = category
        self.itemName = itemName
        self.location = location
        self.quantity = quantity
        self.reason = reason
        self.requestName = requestName
        self.userId = userId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Convert to Firestore Dictionary
    func toDictionary() -> [String: Any] {
        return [
            "category": category,
            "itemName": itemName,
            "location": location,
            "quantity": quantity,
            "reason": reason,
            "requestName": requestName,
            "userId": userId,
            "createdAt": createdAt,
            "updatedAt": updatedAt
        ]
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
    
    var categoryIcon: String {
        switch category.lowercased() {
        case "laboratory": return "flask.fill"
        case "classroom": return "book.fill"
        case "office": return "briefcase.fill"
        case "equipment": return "wrench.and.screwdriver.fill"
        case "electronics": return "bolt.fill"
        default: return "square.grid.2x2.fill"
        }
    }
    
    var quantityStatusColor: String {
        if quantity == 0 {
            return "systemRed"
        } else if quantity < 5 {
            return "systemOrange"
        } else {
            return "systemGreen"
        }
    }
    
    // MARK: - Convenience Properties
    
    var timestamp: Date? {
        return createdAt.dateValue()
    }
    
    var description: String {
        return reason
    }
    
    var status: String {
        if quantity == 0 {
            return "Out of Stock"
        } else if quantity < 5 {
            return "Low Stock"
        } else {
            return "Available"
        }
    }
    
    var supplier: String? { return nil }
    var price: String? { return nil }
}

// MARK: - Category Extension
extension Inventory {
    enum Category: String, CaseIterable {
        case laboratory, classroom, office, equipment, electronics, other
        
        var displayName: String {
            return rawValue.capitalized
        }
        
        var icon: String {
            switch self {
            case .laboratory: return "flask.fill"
            case .classroom: return "book.fill"
            case .office: return "briefcase.fill"
            case .equipment: return "wrench.and.screwdriver.fill"
            case .electronics: return "bolt.fill"
            case .other: return "square.grid.2x2.fill"
            }
        }
    }
}
