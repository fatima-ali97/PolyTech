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
        self.id = dictionary["id"] as? String ?? ""
        self.description = dictionary["description"] as? String ?? ""
        self.status = dictionary["status"] as? String ?? ""
        self.address = dictionary["Address"] as? String ?? ""
        self.client = dictionary["client"] as? String ?? ""
        self.note = dictionary["note"] as? String ?? ""
        self.createdAt = dictionary["createdAt"] as? String ?? ""

        if let ts = dictionary["acceptedDate"] as? Timestamp {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy"
            self.acceptedDate = formatter.string(from: ts.dateValue())
        } else {
            self.acceptedDate = "قيد الانتظار"
        }
    }
}
