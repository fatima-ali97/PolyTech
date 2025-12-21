//
//  ViewController.swift
//  PolyTech
//
//  Created by BP-36-201-02 on 30/11/2025.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
       
        // Do any additional setup after loading the view.
    }

    func showAlert(title: String, message: String) {
    let alert = UIAlertController(title: title, message:
    message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style:
    .default))
    present(alert, animated: true)
    }
    
    
    
    
    //MARK: declarations
    @IBOutlet weak var AcademicIdTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    
    //MARK: DB setup
    let db = Firestore.firestore()
    
    
    //MARK: Login btn function
    @IBAction func loginButtonTapped(
        _
        sender: UIButton) {
        guard var email = AcademicIdTextField.text, !email.isEmpty else
        {
        showAlert(title: "Missing Academic Id", message: "Please enter your email address.")
        return
        }
        guard let password = passwordTextField.text,
        !password.isEmpty else {
        showAlert(title: "Missing Password", message: "Please enter your password.")
        return
        }
        email = email + "@student.polytechnic.bh"
        // Sign in with Firebase Authentication
            Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
                        guard let self = self else { return }
                        
                        if let error = error {
                            
                            self.showAlert(title: "Login Failed", message: error.localizedDescription)
                            return
                        }
                        
                        // Successfully authenticated, now get user role from Firestore
                        guard let userId = authResult?.user.uid else { return }
                        self.fetchUserRole(userId: userId)
                    }
        }
    
    // MARK: - Fetch User Role from Firestore
        func fetchUserRole(userId: String) {
            db.collection("users").document(userId).getDocument { [weak self] document, error in
                guard let self = self else { return }
                if let error = error {
                    self.showAlert(title: "Error", message: "Failed to fetch user data: \\(error.localizedDescription)")
                    return
                }
                
                guard let document = document, document.exists,
                      let data = document.data(),
                      let role = data["role"] as? String else {
                    self.showAlert(title: "Error", message: "User role not found in database")
                    return
                }
                
                // Navigate based on role
                self.navigateToAppropriateScreen(role: role)
            }
        }
    
    // MARK: - Navigation Based on Role
        func navigateToAppropriateScreen(role: String) {
            var storyboardID: String
            
            switch role.lowercased() {
            case "student":
                storyboardID = "StudentHomeViewController"
            case "admin":
                storyboardID = "AdminHomeViewController"
            case "technician":
                storyboardID = "TechnicianHomeViewController"
            default:
                showAlert(title: "Error", message: "Invalid user role")
                return
            }
            
            // Navigate to the appropriate view controller
            if let homeVC = storyboard?.instantiateViewController(withIdentifier: storyboardID) {
                // Set as root view controller to prevent going back to login
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    window.rootViewController = homeVC
                    window.makeKeyAndVisible()
                    
                    // Optional: Add transition animation
                    UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
                }
            }
        }
 
}

