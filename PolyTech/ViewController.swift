//
//  ViewController.swift
//  PolyTech
//
//  Created by BP-36-201-02 on 30/11/2025.
//
import UIKit
import FirebaseAuth
import FirebaseFirestore

class LoginViewController: UIViewController {
    
    // MARK: - Properties
    private let db = Firestore.firestore()
    private let studentEmailSuffix = "@student.polytechnic.bh"
    private let staffEmailSuffix = "@polytechnic.bh"
    
    // MARK: - IBOutlets
    @IBOutlet weak var academicIdTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationManager.shared.showSuccess(
               title: "Welcome!",
               message: "The notification system is working"
           )
        setupUI()
    }
    
    // MARK: - Setup
    private func setupUI() {
        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        
        // Configure text fields
        academicIdTextField.autocapitalizationType = .none
        passwordTextField.isSecureTextEntry = true
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - IBActions
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        view.endEditing(true)
        
        guard let identifier = academicIdTextField.text?.trimmingCharacters(in: .whitespaces),
              !identifier.isEmpty else {
            showAlert(title: "Missing ID", message: "Please enter your academic ID or username.")
            return
        }
        
        guard let password = passwordTextField.text,
              !password.isEmpty else {
            showAlert(title: "Missing Password", message: "Please enter your password.")
            return
        }
        
        // Try to authenticate with both email formats
        attemptLogin(identifier: identifier, password: password)
    }
    
    // MARK: - Authentication
    private func attemptLogin(identifier: String, password: String) {
        setLoadingState(true)
        
        // First, try with student email format
        let studentEmail = identifier + studentEmailSuffix
        
        Auth.auth().signIn(withEmail: studentEmail, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            
            if error == nil, let userId = authResult?.user.uid {
                // Student login successful
                print("✅ Student login successful")
                self.fetchUserRole(userId: userId)
                return
            }
            
            // Student login failed, try staff email format
            print("⚠️ Student login failed, trying staff format...")
            let staffEmail = identifier + self.staffEmailSuffix
            
            Auth.auth().signIn(withEmail: staffEmail, password: password) { authResult, error in
                if let error = error {
                    // Both attempts failed
                    self.setLoadingState(false)
                    self.handleAuthError(error)
                    return
                }
                
                guard let userId = authResult?.user.uid else {
                    self.setLoadingState(false)
                    self.showAlert(title: "Error", message: "Unable to retrieve user information.")
                    return
                }
                
                // Staff login successful
                print("✅ Staff login successful")
                self.fetchUserRole(userId: userId)
            }
        }
    }
    
    // MARK: - Firestore
    private func fetchUserRole(userId: String) {
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            guard let self = self else { return }
            self.setLoadingState(false)
            
            if let error = error {
                self.showAlert(title: "Error", message: "Failed to fetch user data: \(error.localizedDescription)")
                self.signOutUser()
                return
            }
            
            guard let document = document,
                  document.exists,
                  let data = document.data(),
                  let role = data["role"] as? String else {
                self.showAlert(title: "Error", message: "User role not found in database.")
                self.signOutUser()
                return
            }
            
            // Save login state and user info
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
            UserDefaults.standard.set(userId, forKey: "userId")
            UserDefaults.standard.set(role, forKey: "userRole")
            
            self.navigateToHome(for: role, userId: userId)
        }
    }
    
    // MARK: - Navigation
    private func navigateToHome(for role: String, userId: String) {
        // Save login state and user info (already saved above, but keeping for clarity)
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        UserDefaults.standard.set(userId, forKey: "userId")
        UserDefaults.standard.set(role, forKey: "userRole")
        
        print("📱 Navigating to home for role: \(role)")
        print("💾 Saved login state to UserDefaults")
        
        // All roles now use the custom tab bar!
        if let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate {
            sceneDelegate.switchToDashboard()
        }
    }
    
    // MARK: - Error Handling
    private func handleAuthError(_ error: Error) {
        let authError = error as NSError
        var message = error.localizedDescription
        
        // Provide user-friendly error messages
        switch AuthErrorCode(rawValue: authError.code) {
        case .wrongPassword:
            message = "Incorrect password. Please try again."
        case .invalidEmail:
            message = "Invalid ID format."
        case .userNotFound:
            message = "No account found with this ID."
        case .networkError:
            message = "Network error. Please check your connection."
        case .tooManyRequests:
            message = "Too many failed attempts. Please try again later."
        default:
            break
        }
        
        showAlert(title: "Login Failed", message: message)
    }
    
    private func signOutUser() {
        try? Auth.auth().signOut()
    }
    
    // MARK: - UI Helpers
    private func setLoadingState(_ isLoading: Bool) {
        loginButton.isEnabled = !isLoading
        academicIdTextField.isEnabled = !isLoading
        passwordTextField.isEnabled = !isLoading
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

//// MARK: - Base Protocol for Home View Controllers
//protocol BaseHomeViewController: UIViewController {
//    var userId: String? { get set }
//}
