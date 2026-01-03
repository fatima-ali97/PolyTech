import UIKit
import FirebaseCore
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Configure Firebase
        FirebaseApp.configure()
        
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Request notification permissions on app launch
        PushNotificationManager.shared.requestAuthorization { granted in
            if granted {
                print("✅ Notification permissions granted")
                
                // Get user info
                guard let userId = UserDefaults.standard.string(forKey: "userId"),
                      let userRole = UserDefaults.standard.string(forKey: "userRole") else {
                    return
                }
                
                // 🔔 Start monitoring request status changes (for students)
                RequestStatusNotificationService.shared.startMonitoring(userId: userId)
                
                // 🔔 Start monitoring delayed requests (for admins)
                if userRole == "admin" {
                    DelayedRequestNotificationService.shared.startMonitoringDelayedRequests()
                }
            } else {
                print("❌ Notification permissions denied")
            }
        }
        
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Stop monitoring when app closes
        RequestStatusNotificationService.shared.stopMonitoring()
        DelayedRequestNotificationService.shared.stopMonitoring()
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        print("📱 Notification received while app is in foreground")
        
        // Show banner, badge, and play sound even when app is in foreground
        completionHandler([.banner, .badge, .sound])
    }
    
    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               didReceive response: UNNotificationResponse,
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        
        print("📱 User tapped notification")
        print("User Info: \(userInfo)")
        
        // Handle the notification tap
        if let requestType = userInfo["requestType"] as? String {
            print("Request type: \(requestType)")
            
            // Navigate to appropriate screen based on request type
            NotificationCenter.default.post(
                name: NSNotification.Name("NavigateToRequest"),
                object: nil,
                userInfo: ["requestType": requestType]
            )
        }
        
        // Clear badge count when notification is tapped
        PushNotificationManager.shared.clearBadgeCount()
        
        completionHandler()
    }
}
