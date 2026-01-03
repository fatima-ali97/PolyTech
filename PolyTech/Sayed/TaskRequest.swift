//
//  TaskRequest.swift
//  PolyTech
//
//  Created by BP-36-212-01 on 31/12/2025.
//

import Foundation
import FirebaseFirestore

struct TaskRequest {
    let documentID: String
    let id: String
    let description: String
    let status: String
    let address: String
    let client: String
    let createdAt: String
    let note: String
    let acceptedDate: String

    init(docID: String, dictionary: [String: Any]) {
        self.documentID = docID
        self.id = dictionary["id"] as? String ?? String(docID.prefix(6))
        
        self.description = dictionary["requestName"] as? String ?? (dictionary["description"] as? String ?? "No Description")
        
        let rawStatus = dictionary["status"] as? String ?? "Pending"
        self.status = rawStatus.capitalized
        
        self.address = dictionary["location"] as? String ?? (dictionary["Address"] as? String ?? "No Address")
        
        self.client = dictionary["userId"] as? String ?? (dictionary["client"] as? String ?? "Unknown")
        
        self.note = dictionary["note"] as? String ?? ""

        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"

        if let ts = dictionary["createdAt"] as? Timestamp {
            self.createdAt = formatter.string(from: ts.dateValue())
        } else {
            self.createdAt = "N/A"
        }

        if let ts = dictionary["acceptedDate"] as? Timestamp {
            self.acceptedDate = formatter.string(from: ts.dateValue())
        } else {
            self.acceptedDate = "Pending"
        }
    }
}
