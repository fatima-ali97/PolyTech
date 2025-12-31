//
//  TaskRequest.swift
//  PolyTech
//
//  Created by BP-36-212-01 on 31/12/2025.
//

import Foundation

struct TaskRequest {
    let documentID: String
    let id: String
    let description: String
    let status: String
    let address: String
    let client: String
    let dueDate: String
    let note: String
    
    init(docID: String, dictionary: [String: Any]) {
        self.documentID = docID
        self.id = dictionary["id"] as? String ?? "No ID"
        self.description = dictionary["description"] as? String ?? ""
        self.status = dictionary["status"] as? String ?? "Pending"
        self.address = dictionary["Address"] as? String ?? ""
        self.client = dictionary["client"] as? String ?? ""
        self.dueDate = dictionary["dueDate"] as? String ?? ""
        self.note = dictionary["note"] as? String ?? ""
    }
}
