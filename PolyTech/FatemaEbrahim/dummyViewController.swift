//
//  dummyViewController.swift
//  PolyTech
//
//  Created by BP-19-130-15 on 27/12/2025.
//

import UIKit
class dummyViewController: UIViewController {

    var userId: String?

    @IBOutlet weak var logout: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get userId from UserDefaults if needed
        if userId == nil {
            userId = UserDefaults.standard.string(forKey: "userId")
        }
        
        print("User ID: \(userId ?? "No user ID")")
        
        // Tab bar will be visible automatically
        // No need to call hideCustomTabBar(false) unless you previously hid it
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Ensure tab bar is visible when this screen appears
        if let tabBarController = self.tabBarController as? BaseCustomTabBarController {
            tabBarController.hideCustomTabBar(false, animated: true)
        }
    }
    
    
    
    // In Profile or Settings screen
    @IBAction func logoutButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Logout", message: "Are you sure you want to logout?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive) { _ in
            AuthManager.shared.logout(from: self)
        })
        
        present(alert, animated: true)
    }

}




