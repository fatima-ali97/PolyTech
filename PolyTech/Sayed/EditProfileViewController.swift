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
    @IBAction func saveChangesButtonTapped(_ sender: UIButton) {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("Error: No user logged in")
            return
        }
        
        let updatedData: [String: Any] = [
            "fullName": fullNameTextField.text?.trimmingCharacters(in: .whitespaces) ?? "",
            "email": emailTextField.text?.trimmingCharacters(in: .whitespaces) ?? "",
            "phoneNumber": phoneTextField.text?.trimmingCharacters(in: .whitespaces) ?? "",
            "username": usernameTextField.text?.trimmingCharacters(in: .whitespaces) ?? "",
            "address": addressTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        ]
        
        print("Sending data to Firebase...")

        db.collection("users").document(uid).setData(updatedData, merge: true) { [weak self] error in
            if let error = error {
                print("Update Error: \(error.localizedDescription)")
                self?.showAlert(title: "Update Failed", message: error.localizedDescription)
            } else {
                print("Profile Updated Successfully!")
                
                self?.showAlert(title: "Success", message: "Your profile has been updated.") {
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
}
