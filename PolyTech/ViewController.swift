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
    private let emailSuffix = "@student.polytechnic.bh"
    
    // MARK: - IBOutlets
    @IBOutlet weak var academicIdTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
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
        
        guard let academicId = academicIdTextField.text?.trimmingCharacters(in: .whitespaces),
              !academicId.isEmpty else {
            showAlert(title: "Missing Academic ID", message: "Please enter your academic ID.")
            return
        }
        
        guard let password = passwordTextField.text,
              !password.isEmpty else {
            showAlert(title: "Missing Password", message: "Please enter your password.")
            return
        }
        
        let email = academicId + emailSuffix
        authenticateUser(email: email, password: password)
    }
    
    // MARK: - Authentication
    private func authenticateUser(email: String, password: String) {
        setLoadingState(true)
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            
            if let error = error {
                self.setLoadingState(false)
                self.handleAuthError(error)
                return
            }
            
            guard let userId = authResult?.user.uid else {
                self.setLoadingState(false)
                self.showAlert(title: "Error", message: "Unable to retrieve user information.")
                return
            }
            
            self.fetchUserRole(userId: userId)
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
            
            self.navigateToHome(for: role, userId: userId)
        }
    }
    
    // MARK: - Navigation
    private func navigateToHome(for role: String, userId: String) {
        let storyboardID: String
        
        switch role.lowercased() {
        case "student":
            storyboardID = "StudentHomeViewController"
        case "admin":
            storyboardID = "AdminHomeViewController"
        case "technician":
            storyboardID = "TechnicianHomeViewController"
        default:
            showAlert(title: "Error", message: "Invalid user role: \(role)")
            signOutUser()
            return
        }
        
        guard let homeVC = storyboard?.instantiateViewController(withIdentifier: storyboardID) else {
            showAlert(title: "Error", message: "Unable to load home screen.")
            return
        }
        
        // Pass userId to the destination VC if needed
        if let homeVC = homeVC as? BaseHomeViewController {
            homeVC.userId = userId
        }
        
        // Embed in navigation controller if not already
        let navigationController = UINavigationController(rootViewController: homeVC)
        navigationController.modalPresentationStyle = .fullScreen
        
        // Transition to new root
        setNewRootViewController(navigationController)
    }
    
    private func setNewRootViewController(_ viewController: UIViewController) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }
        
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        
        UIView.transition(with: window,
                         duration: 0.3,
                         options: .transitionCrossDissolve,
                         animations: nil,
                         completion: nil)
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
            message = "Invalid academic ID format."
        case .userNotFound:
            message = "No account found with this academic ID."
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

// MARK: - Base Protocol for Home View Controllers
protocol BaseHomeViewController: UIViewController {
    var userId: String? { get set }
}
