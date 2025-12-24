import UIKit

class NotificationManager {
    
    static let shared = NotificationManager()
    
    private var currentNotification: NotificationLayout?
    private var notificationWindow: UIWindow?
    
    private init() {}
    
    // MARK: - Show Notification
    
    func show(title: String,
              message: String,
              icon: UIImage? = nil,
              backgroundColor: UIColor = .systemBackground,
              duration: TimeInterval = 4.0,
              onTap: (() -> Void)? = nil) {
        
        // Dismiss any existing notification first
        dismiss()
        
        // Get the key window
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let mainWindow = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return
        }
        
        // Create notification view
        let notification = NotificationLayout()
        notification.configure(title: title, message: message, icon: icon, backgroundColor: backgroundColor)
        notification.translatesAutoresizingMaskIntoConstraints = false
        notification.alpha = 0
        notification.transform = CGAffineTransform(translationX: 0, y: -100)
        
        // Set callbacks
        notification.onTap = { [weak self] in
            onTap?()
            self?.dismiss()
        }
        
        notification.onDismiss = { [weak self] in
            self?.dismiss()
        }
        
        // Add to window
        mainWindow.addSubview(notification)
        
        // Get safe area insets
        let safeAreaTop = mainWindow.safeAreaInsets.top
        
        // Setup constraints
        NSLayoutConstraint.activate([
            notification.topAnchor.constraint(equalTo: mainWindow.topAnchor, constant: safeAreaTop),
            notification.leadingAnchor.constraint(equalTo: mainWindow.leadingAnchor),
            notification.trailingAnchor.constraint(equalTo: mainWindow.trailingAnchor),
            notification.heightAnchor.constraint(greaterThanOrEqualToConstant: 80)
        ])
        
        currentNotification = notification
        
        // Animate in
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            notification.alpha = 1
            notification.transform = .identity
        }
        
        // Auto dismiss after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.dismiss()
        }
    }
    
    // MARK: - Dismiss Notification
    
    func dismiss() {
        guard let notification = currentNotification else { return }
        
        UIView.animate(withDuration: 0.3, animations: {
            notification.alpha = 0
            notification.transform = CGAffineTransform(translationX: 0, y: -100)
        }) { _ in
            notification.removeFromSuperview()
        }
        
        currentNotification = nil
    }
    
    // MARK: - Convenience Methods
    
    func showSuccess(title: String, message: String, onTap: (() -> Void)? = nil) {
        show(title: title,
             message: message,
             icon: UIImage(systemName: "checkmark.circle.fill"),
             backgroundColor: .systemGreen.withAlphaComponent(0.1),
             onTap: onTap)
    }
    
    func showError(title: String, message: String, onTap: (() -> Void)? = nil) {
        show(title: title,
             message: message,
             icon: UIImage(systemName: "xmark.circle.fill"),
             backgroundColor: .systemRed.withAlphaComponent(0.1),
             onTap: onTap)
    }
    
    func showWarning(title: String, message: String, onTap: (() -> Void)? = nil) {
        show(title: title,
             message: message,
             icon: UIImage(systemName: "exclamationmark.triangle.fill"),
             backgroundColor: .systemOrange.withAlphaComponent(0.1),
             onTap: onTap)
    }
    
    func showInfo(title: String, message: String, onTap: (() -> Void)? = nil) {
        show(title: title,
             message: message,
             icon: UIImage(systemName: "info.circle.fill"),
             backgroundColor: .systemBlue.withAlphaComponent(0.1),
             onTap: onTap)
    }
}
