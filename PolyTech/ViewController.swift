import UIKit
import FirebaseAuth
import FirebaseFirestore
import LocalAuthentication

class LoginViewController: UIViewController {
    
    // MARK: - Properties
    private let db = Firestore.firestore()
    private let studentEmailSuffix = "@student.polytechnic.bh"
    private let staffEmailSuffix = "@polytechnic.bh"
    
    // MARK: - IBOutlets
    @IBOutlet weak var academicIdTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel! // Add this to your storyboard
    
    // Password visibility toggle button
    private var passwordToggleButton: UIButton?
    
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
        
        // Setup password visibility toggle
        setupPasswordToggle()
        
        // Hide error label initially
        errorLabel?.isHidden = true
        errorLabel?.textColor = .systemRed
        errorLabel?.numberOfLines = 0
        
        // Add text field delegates for real-time feedback
        academicIdTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    private func setupPasswordToggle() {
        // Create toggle button
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "eye.slash.fill"), for: .normal)
        button.setImage(UIImage(systemName: "eye.fill"), for: .selected)
        button.tintColor = .systemGray
        button.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        button.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
        
        // Add button to password text field
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 30))
        button.center = paddingView.center
        paddingView.addSubview(button)
        
        passwordTextField.rightView = paddingView
        passwordTextField.rightViewMode = .always
        
        passwordToggleButton = button
    }
    
    @objc private func togglePasswordVisibility() {
        passwordTextField.isSecureTextEntry.toggle()
        passwordToggleButton?.isSelected.toggle()
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func textFieldDidChange() {
        // Reset UI to normal state when user starts typing
        resetFieldAppearance()
    }
    
    // MARK: - IBActions
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        view.endEditing(true)
        
        guard let identifier = academicIdTextField.text?.trimmingCharacters(in: .whitespaces),
              !identifier.isEmpty else {
            showFieldError(for: academicIdTextField, message: "Please enter your academic ID or username.")
            return
        }
        
        guard let password = passwordTextField.text,
              !password.isEmpty else {
            showFieldError(for: passwordTextField, message: "Please enter your password.")
            return
        }
        
        // Try to authenticate with both email formats
        attemptLogin(identifier: identifier, password: password)
    }
    
    // MARK: - Authentication
    private func attemptLogin(identifier: String, password: String) {
        setLoadingState(true)
        resetFieldAppearance()
        
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
                    self.showGeneralError(message: "Unable to retrieve user information.")
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
                self.showGeneralError(message: "Failed to fetch user data: \(error.localizedDescription)")
                self.signOutUser()
                return
            }
            
            guard let document = document,
                  document.exists,
                  let data = document.data(),
                  let role = data["role"] as? String else {
                self.showGeneralError(message: "User role not found in database.")
                self.signOutUser()
                return
            }
            
            // Save login state and user info
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
            UserDefaults.standard.set(userId, forKey: "userId")
            UserDefaults.standard.set(role, forKey: "userRole")
            
            // Attempt Face ID authentication
            self.authenticateWithBiometrics(role: role, userId: userId)
        }
    }
    
    // MARK: - Biometric Authentication
    private func authenticateWithBiometrics(role: String, userId: String) {
        let context = LAContext()
        var error: NSError?
        
        // Check if biometric authentication is available
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate to access your account"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, evaluationError in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    
                    if success {
                        // Biometric authentication successful
                        self.navigateToHome(for: role, userId: userId)
                    } else {
                        // Handle biometric authentication errors
                        self.handleBiometricError(evaluationError, role: role, userId: userId)
                    }
                }
            }
        } else {
            // Biometric authentication not available
            handleBiometricNotAvailable(error, role: role, userId: userId)
        }
    }
    
    private func handleBiometricError(_ error: Error?, role: String, userId: String) {
        guard let laError = error as? LAError else {
            navigateToHome(for: role, userId: userId)
            return
        }
        
        var shouldHighlightFields = true
        var errorMessage = ""
        
        switch laError.code {
        case .authenticationFailed:
            errorMessage = "Face ID authentication failed. Please try again."
            showBiometricAlert(
                title: "Authentication Failed",
                message: errorMessage,
                allowPasscode: true,
                role: role,
                userId: userId
            )
            
        case .userCancel:
            // User canceled, just sign them out
            print("User canceled biometric authentication")
            signOutUser()
            shouldHighlightFields = false
            
        case .userFallback:
            // User chose to enter password instead
            navigateToHome(for: role, userId: userId)
            shouldHighlightFields = false
            
        case .biometryNotAvailable:
            // Biometrics not available, proceed without it
            print("ℹ️ Face ID not available, proceeding to dashboard")
            navigateToHome(for: role, userId: userId)
            shouldHighlightFields = false
            
        case .biometryNotEnrolled:
            // Face ID not set up, proceed directly to dashboard
            print("ℹ️ Face ID not enrolled, proceeding to dashboard")
            navigateToHome(for: role, userId: userId)
            shouldHighlightFields = false
            
        case .biometryLockout:
            // Too many failed attempts
            errorMessage = "Face ID has been locked due to too many failed attempts. Please use your device passcode."
            showBiometricAlert(
                title: "Face ID Locked",
                message: errorMessage,
                allowPasscode: true,
                role: role,
                userId: userId
            )
            
        case .appCancel, .systemCancel:
            // App or system canceled, sign out
            print("Biometric authentication was canceled by the system")
            signOutUser()
            shouldHighlightFields = false
            
        case .invalidContext:
            // Context is invalid, proceed without biometrics
            navigateToHome(for: role, userId: userId)
            shouldHighlightFields = false
            
        case .notInteractive:
            // Cannot display UI, proceed without biometrics
            navigateToHome(for: role, userId: userId)
            shouldHighlightFields = false
            
        case .passcodeNotSet:
            // No passcode set on device, proceed directly to dashboard
            print("ℹ️ Device passcode not set, proceeding to dashboard")
            navigateToHome(for: role, userId: userId)
            shouldHighlightFields = false
            
        @unknown default:
            // Unknown error, proceed without biometrics
            navigateToHome(for: role, userId: userId)
            shouldHighlightFields = false
        }
        
        // Highlight input fields in red for all error scenarios
        if shouldHighlightFields && !errorMessage.isEmpty {
            highlightFieldsAsError()
        }
    }
    
    private func handleBiometricNotAvailable(_ error: NSError?, role: String, userId: String) {
        // If biometrics are not available at all, just proceed to dashboard
        print("ℹ️ Biometric authentication not available, proceeding to dashboard")
        navigateToHome(for: role, userId: userId)
    }
    
    private func showBiometricAlert(title: String, message: String, allowPasscode: Bool, role: String, userId: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        if allowPasscode {
            alert.addAction(UIAlertAction(title: "Use Passcode", style: .default) { [weak self] _ in
                self?.authenticateWithPasscode(role: role, userId: userId)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Continue", style: .default) { [weak self] _ in
            self?.navigateToHome(for: role, userId: userId)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.signOutUser()
        })
        
        present(alert, animated: true)
    }
    
    private func authenticateWithPasscode(role: String, userId: String) {
        let context = LAContext()
        let reason = "Authenticate to access your account"
        
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { [weak self] success, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if success {
                    self.navigateToHome(for: role, userId: userId)
                } else {
                    self.signOutUser()
                }
            }
        }
    }
    
    // MARK: - Navigation
    private func navigateToHome(for role: String, userId: String) {
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        UserDefaults.standard.set(userId, forKey: "userId")
        UserDefaults.standard.set(role, forKey: "userRole")
        
        print("📱 Navigating to home for role: \(role)")
        print("💾 Saved login state to UserDefaults")
        
        if let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate {
            sceneDelegate.switchToDashboard()
        }
    }
    
    // MARK: - Error Handling
    private func handleAuthError(_ error: Error) {
        let authError = error as NSError
        var message = error.localizedDescription
        var highlightFields: [UITextField] = []
        
        // Provide user-friendly error messages
        switch AuthErrorCode(rawValue: authError.code) {
        case .wrongPassword:
            message = "Incorrect password. Please try again."
            highlightFields = [passwordTextField]
        case .invalidEmail:
            message = "Invalid ID format."
            highlightFields = [academicIdTextField]
        case .userNotFound:
            message = "No account found with this ID."
            highlightFields = [academicIdTextField]
        case .networkError:
            message = "Network error. Please check your connection."
        case .tooManyRequests:
            message = "Too many failed attempts. Please try again later."
        default:
            break
        }
        
        showFieldError(for: highlightFields.first ?? academicIdTextField, message: message, highlightMultiple: highlightFields)
        
        // Add shake animation
        shakeView(loginButton)
    }
    
    private func signOutUser() {
        try? Auth.auth().signOut()
        UserDefaults.standard.removeObject(forKey: "isLoggedIn")
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "userRole")
    }
    
    // MARK: - UI Helpers
    private func setLoadingState(_ isLoading: Bool) {
        loginButton.isEnabled = !isLoading
        academicIdTextField.isEnabled = !isLoading
        passwordTextField.isEnabled = !isLoading
        
        if isLoading {
            loginButton.setTitle("Logging in...", for: .normal)
            loginButton.alpha = 0.7
        } else {
            loginButton.setTitle("Login", for: .normal)
            loginButton.alpha = 1.0
        }
    }
    
    private func highlightFieldsAsError() {
        // Highlight both input fields in red
        academicIdTextField.layer.borderColor = UIColor.systemRed.cgColor
        academicIdTextField.layer.borderWidth = 2.0
        academicIdTextField.layer.cornerRadius = 8.0
        
        passwordTextField.layer.borderColor = UIColor.systemRed.cgColor
        passwordTextField.layer.borderWidth = 2.0
        passwordTextField.layer.cornerRadius = 8.0
        
        // Shake animation only on fields
        shakeView(academicIdTextField)
        shakeView(passwordTextField)
    }
    
    private func showFieldError(for textField: UITextField, message: String, highlightMultiple: [UITextField]? = nil) {
        // Show error message
        errorLabel?.text = message
        errorLabel?.isHidden = false
        
        // Highlight the problematic fields
        let fieldsToHighlight = highlightMultiple ?? [textField]
        for field in fieldsToHighlight {
            field.layer.borderColor = UIColor.systemRed.cgColor
            field.layer.borderWidth = 2.0
            field.layer.cornerRadius = 8.0
            
            // Shake animation
            shakeView(field)
        }
    }
    
    private func showGeneralError(message: String) {
        errorLabel?.text = message
        errorLabel?.isHidden = false
        highlightFieldsAsError()
    }
    
    private func resetFieldAppearance() {
        errorLabel?.isHidden = true
        
        academicIdTextField.layer.borderWidth = 0
        passwordTextField.layer.borderWidth = 0
    }
    
    private func shakeView(_ view: UIView) {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.6
        animation.values = [-20, 20, -20, 20, -10, 10, -5, 5, 0]
        view.layer.add(animation, forKey: "shake")
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
