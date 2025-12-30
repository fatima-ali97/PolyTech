//
//  UserModel.swift
//  PolyTech
//
//  Created by BP-36-212-04 on 29/12/2025.
//

struct UserModel {
    let fullName: String
    let email: String
    let phoneNumber: String?
    let username: String?
    let address: String?
    let role: String

    init(dictionary: [String: Any]) {
        self.fullName = dictionary["fullName"] as? String ?? "No Name"
        self.email = dictionary["email"] as? String ?? ""
        self.phoneNumber = dictionary["phoneNumber"] as? String
        self.username = dictionary["username"] as? String
        self.address = dictionary["address"] as? String
        self.role = dictionary["role"] as? String ?? "User"
    }
}
