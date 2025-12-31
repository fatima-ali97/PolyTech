//
//  ProfileViewController.swift
//  PolyTech
//
//  Created by BP-36-212-01 on 21/12/2025.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import FirebaseMessaging

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    private let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let isEnabled = UserDefaults.standard.bool(forKey:"pushNotificationsEnabled")
            notificationSwitch.isOn = isEnabled
        
        setupScrollViewUI()
        fetchUserData()
    }
    
    func setupScrollViewUI() {
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 900, right: 0)
    }
    
    func fetchUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(uid).addSnapshotListener { [weak self] snapshot, error in
            guard let data = snapshot?.data(), error == nil else { return }
            
            DispatchQueue.main.async {
                self?.nameLabel.text = data["fullName"] as? String ?? "No Name"
                self?.emailLabel.text = data["email"] as? String ?? "No Email"
            }
        }
    }
    
    @IBAction func logoutButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Logout", message: "Are you sure you want to log out?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive) { _ in
            self.performLogout()
        })
        
        present(alert, animated: true)
    }

    private func performLogout() {
        do {
            try Auth.auth().signOut()
            
            UserDefaults.standard.set(false, forKey: "isLoggedIn")
            UserDefaults.standard.removeObject(forKey: "userId")
            UserDefaults.standard.removeObject(forKey: "userRole")
            
            DispatchQueue.main.async {
                if let sceneDelegate = self.view.window?.windowScene?.delegate as? SceneDelegate {
                    sceneDelegate.switchToLogin()
                }
            }
        } catch let error {
            print("Failed to sign out: \(error.localizedDescription)")
        }
    }
    
    @IBAction func goToHistoryTapped(_ sender: UIButton) {
        let historyStoryboard = UIStoryboard(name: "History", bundle: nil)
        
        if let initialVC = historyStoryboard.instantiateInitialViewController() {
            initialVC.modalPresentationStyle = .fullScreen
            self.present(initialVC, animated: true, completion: nil)
        } else {
            print("History.storyboard missing 'Is Initial View Controller' setting.")
        }
    }
    
    @IBOutlet weak var notificationSwitch: UISwitch!

    @IBAction func notificationSwitchChanged(_ sender: UISwitch) {
        let isEnabled = sender.isOn
        UserDefaults.standard.set(isEnabled, forKey: "pushNotificationsEnabled")
        
        if isEnabled {
            Messaging.messaging().subscribe(toTopic: "all_users")
            print("Local: Notifications Enabled")
        } else {
            Messaging.messaging().unsubscribe(fromTopic: "all_users")
            print("Local: Notifications Disabled")
        }
    }
    
    private func enableNotifications() {
        Messaging.messaging().subscribe(toTopic: "all_users") { error in
            if let error = error {
                print("Error subscribing to notifications: \(error)")
            } else {
                print("Notifications Enabled: Subscribed to all_users topic")
                UserDefaults.standard.set(true, forKey: "pushNotificationsEnabled")
            }
        }
    }

    private func disableNotifications() {
        Messaging.messaging().unsubscribe(fromTopic: "all_users") { error in
            if let error = error {
                print("Error unsubscribing: \(error)")
            } else {
                print("Notifications Disabled: Unsubscribed from topic")
                UserDefaults.standard.set(false, forKey: "pushNotificationsEnabled")
            }
        }
    }
    
}
