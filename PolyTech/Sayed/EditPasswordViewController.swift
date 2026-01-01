//
//  EditPasswordViewController.swift
//  PolyTech
//
//  Created by BP-36-212-04 on 29/12/2025.
//

import UIKit
import FirebaseAuth

class EditPasswordViewController: UIViewController {
    
    @IBOutlet weak var currentPasswordTextField: UITextField!
    @IBOutlet weak var newPasswordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var savePasswordButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupPasswordToggle(for: currentPasswordTextField)
        setupPasswordToggle(for: newPasswordTextField)
        setupPasswordToggle(for: confirmPasswordTextField)
    }

    private func setupPasswordToggle(for textField: UITextField) {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "eye.slash.fill"), for: .normal)
        button.setImage(UIImage(systemName: "eye.fill"), for: .selected)
        button.tintColor = .systemGray
        
        button.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        button.addTarget(self, action: #selector(toggleVisibility(_:)), for: .touchUpInside)
        
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 30))
        button.center = paddingView.center
        paddingView.addSubview(button)
        
        textField.rightView = paddingView
        textField.rightViewMode = .always
        textField.isSecureTextEntry = true
    }

    @objc private func toggleVisibility(_ sender: UIButton) {
        guard let paddingView = sender.superview,
              let textField = paddingView.superview as? UITextField else {
            
            if sender.isSelected {
                currentPasswordTextField.rightView?.subviews.contains(sender) == true ? toggle(currentPasswordTextField, btn: sender) : ()
                newPasswordTextField.rightView?.subviews.contains(sender) == true ? toggle(newPasswordTextField, btn: sender) : ()
                confirmPasswordTextField.rightView?.subviews.contains(sender) == true ? toggle(confirmPasswordTextField, btn: sender) : ()
            }
            return
        }
        
        toggle(textField, btn: sender)
    }

    private func toggle(_ textField: UITextField, btn: UIButton) {
        textField.isSecureTextEntry.toggle()
        btn.isSelected.toggle()
        
        if let text = textField.text {
            textField.text = nil
            textField.text = text
        }
    }

    private func updateTextField(_ textField: UITextField, sender: UIButton) {
        sender.isSelected.toggle()
        textField.isSecureTextEntry.toggle()
        
        if let text = textField.text {
            textField.text = nil
            textField.text = text
        }
    }
    
    @IBAction func savePasswordTapped(_ sender: UIButton) {
        guard let currentPwd = currentPasswordTextField.text, !currentPwd.isEmpty,
              let newPwd = newPasswordTextField.text, !newPwd.isEmpty,
              let confirmPwd = confirmPasswordTextField.text, !confirmPwd.isEmpty else {
            showAlert(message: "Please fill in all fields")
            return
        }

        if newPwd != confirmPwd {
            showAlert(message: "New passwords do not match")
            return
        }

        reauthenticateAndChangePassword(currentPwd: currentPwd, newPwd: newPwd)
    }
    
    private func reauthenticateAndChangePassword(currentPwd: String, newPwd: String) {
        let trimmedCurrentPwd = currentPwd.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNewPwd = newPwd.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let user = Auth.auth().currentUser, let email = user.email else {
            print("No user logged in")
            return
        }
        
        print("Re-authenticating for: \(email)")
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: trimmedCurrentPwd)
        
        user.reauthenticate(with: credential) { [weak self] authResult, error in
            if let error = error {
                self?.showAlert(message: "The current password you entered is incorrect.")
                return
            }
            
            user.updatePassword(to: trimmedNewPwd) { error in
                if let error = error {
                    self?.showAlert(message: error.localizedDescription)
                } else {
                    self?.showAlert(message: "Password updated successfully! Please login again.") {
                        self?.logoutUser()
                    }
                }
            }
        }
    }
    
    private func showAlert(message: String, completion: (() -> Void)? = nil) {
            let alert = UIAlertController(title: "Change Password", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completion?() })
            present(alert, animated: true)
        }
    
    private func logoutUser() {
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
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }

    
}
