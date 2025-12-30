//
//  ProfileViewController.swift
//  PolyTech
//
//  Created by BP-36-212-01 on 21/12/2025.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    private let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupScrollViewUI()
        fetchUserData()
    }
    
    func setupScrollViewUI() {
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 1050, right: 0)
    }
    
    func fetchUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(uid).addSnapshotListener { [weak self] snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                print("Error fetching profile data")
                return
            }
            
            DispatchQueue.main.async {
                self?.nameLabel.text = data["fullName"] as? String ?? "No Name"
                self?.emailLabel.text = data["email"] as? String ?? "No Email"
            }
        }
    }
    
    }

