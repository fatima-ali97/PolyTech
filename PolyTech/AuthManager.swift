//
//  AuthManager.swift
//  PolyTech
//
//  Created by BP-19-130-15 on 27/12/2025.
//
//
//  AuthManager.swift
//  PolyTech
//

import UIKit
import FirebaseAuth

class AuthManager {
    static let shared = AuthManager()
    
    private init() {}
    
    func logout(from viewController: UIViewController) {
        // Sign out from Firebase
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
        
        // Clear UserDefaults
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "userRole")
        
        // Switch to login screen
        if let sceneDelegate = viewController.view.window?.windowScene?.delegate as? SceneDelegate {
            sceneDelegate.switchToLogin()
        }
    }
}
