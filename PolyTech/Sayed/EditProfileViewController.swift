//
//  EditProfileViewController.swift
//  PolyTech
//
//  Created by BP-36-212-01 on 22/12/2025.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class EditProfileViewController: UIViewController {

    @IBOutlet weak var fullNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var addressTextField: UITextField!
    @IBOutlet weak var changePasswordButton: UIButton!
    @IBOutlet weak var saveChangesButton: UIButton!
    
    private let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTextFieldsUI()
        setupButtonUI()
        loadCurrentUserData()
    }
    
    func setupTextFieldsUI() {
        let allTextFields = [
            fullNameTextField,
            emailTextField,
            phoneTextField,
            usernameTextField,
            addressTextField
        ]
        
        for textField in allTextFields {
            guard let field = textField else { continue }
            
            field.layer.cornerRadius = 12.0
            
            field.layer.borderColor = UIColor.black.cgColor
            field.layer.borderWidth = 1.0
            
            field.layer.masksToBounds = true
            
            let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: field.frame.height))
            field.leftView = paddingView
            field.leftViewMode = .always
        }
    }
    
    func setupButtonUI() {
        changePasswordButton.layer.masksToBounds = true
        changePasswordButton.backgroundColor = .clear
        
        saveChangesButton.layer.masksToBounds = true
    }
    
    private func loadCurrentUserData() {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            
            db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
                if let error = error {
                    print("Error loading user data: \(error.localizedDescription)")
                    return
                }
                
                if let data = snapshot?.data() {
                    DispatchQueue.main.async {
                        self?.fullNameTextField.text = data["fullName"] as? String
                        self?.emailTextField.text = data["email"] as? String
                        self?.phoneTextField.text = data["phoneNumber"] as? String
                        self?.usernameTextField.text = data["username"] as? String
                        self?.addressTextField.text = data["address"] as? String
                    }
                }
            }
        }
    
}
