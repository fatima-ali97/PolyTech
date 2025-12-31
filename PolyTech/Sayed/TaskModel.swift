//
//  TaskModel.swift
//  PolyTech
//
//  Created by BP-36-212-02 on 14/12/2025.
//


struct TaskModel {
    let id: String
    let client: String
    let dueDate: String
    let status: String
    let description: String?
    let Address: String?
    var note: String?
    
    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let client = dictionary["client"] as? String,
              let dueDate = dictionary["dueDate"] as? String,
              let status = dictionary["status"] as? String else {
            return nil
        }
        
        self.id = id
        self.client = client
        self.dueDate = dueDate
        self.status = status
        self.description = dictionary["description"] as? String
        self.Address = dictionary["Address"] as? String
        self.note = dictionary["note"] as? String
    }
}
