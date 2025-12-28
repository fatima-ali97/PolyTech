//
//  SceneDelegate.swift
//  PolyTech
//
//  Created by BP-36-201-02 on 30/11/2025.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        
        // ⚠️ TEMPORARY: Force logout for testing - REMOVE THIS IN PRODUCTION
        #if DEBUG
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "userRole")
        print("🔧 DEBUG: Force logged out for testing")
        #endif
        
        // Check if user is logged in
        let isLoggedIn = isUserLoggedIn()
        print("📊 Login status check: \(isLoggedIn ? "LOGGED IN" : "NOT LOGGED IN")")
        
        if isLoggedIn {
            print("➡️ User is logged in - showing dashboard")
            showDashboard(in: window)
        } else {
            print("➡️ User is NOT logged in - showing login screen")
            showLogin(in: window)
        }
        
        self.window = window
        window.makeKeyAndVisible()
    }
    
    // MARK: - Navigation Methods
    
    private func showLogin(in window: UIWindow) {
        print("🔐 Loading login storyboard...")
        
        // Load from your LOGIN storyboard
        let loginStoryboard = UIStoryboard(name: "LoginStoryboard", bundle: nil)
        
        guard let loginVC = loginStoryboard.instantiateInitialViewController() else {
            fatalError("❌ Cannot instantiate initial view controller from loginStoryboard. Make sure 'Is Initial View Controller' is checked in the storyboard.")
        }
        
        print("✅ Login VC loaded successfully")
        window.rootViewController = loginVC
    }
    
    private func showDashboard(in window: UIWindow) {
        print("📱 Loading dashboard with custom tab bar...")
        let tabBarController = CustomTabBarController()
        window.rootViewController = tabBarController
        print("✅ Dashboard loaded successfully")
    }
    
    // Check if user is logged in
    private func isUserLoggedIn() -> Bool {
        let isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        let userId = UserDefaults.standard.string(forKey: "userId")
        let userRole = UserDefaults.standard.string(forKey: "userRole")
        
        print("📝 UserDefaults status:")
        print("   - isLoggedIn: \(isLoggedIn)")
        print("   - userId: \(userId ?? "nil")")
        print("   - userRole: \(userRole ?? "nil")")
        
        return isLoggedIn
    }
    
    // MARK: - Public Methods (call from anywhere in your app)
    
    func switchToLogin() {
        print("🔄 Switching to login screen...")
        guard let window = window else {
            print("❌ Window is nil, cannot switch to login")
            return
        }
        
        showLogin(in: window)
        
        // Animate transition - Fixed closure syntax
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil) { _ in
            print("✅ Transition to login complete")
        }
    }
    
    func switchToDashboard() {
        print("🔄 Switching to dashboard...")
        guard let window = window else {
            print("❌ Window is nil, cannot switch to dashboard")
            return
        }
        
        showDashboard(in: window)
        
        // Animate transition - Fixed closure syntax
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil) { _ in
            print("✅ Transition to dashboard complete")
        }
    }

    // MARK: - Scene Lifecycle Methods
    
    func sceneDidDisconnect(_ scene: UIScene) {
        print("🔌 Scene did disconnect")
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        print("🟢 Scene did become active")
    }

    func sceneWillResignActive(_ scene: UIScene) {
        print("🟡 Scene will resign active")
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        print("⬆️ Scene will enter foreground")
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        print("⬇️ Scene did enter background")
    }
}
