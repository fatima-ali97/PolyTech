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
<<<<<<< HEAD
        
        // Initialize your custom tab bar controller
        let tabBarController = CustomTabBarController()
        
        window.rootViewController = tabBarController
=======

        let storyboard = UIStoryboard(name: "FAQ", bundle: nil) //change this + make sure u select the "is initial storyboard"

        guard let initialVC = storyboard.instantiateInitialViewController() else {
            fatalError("FAQ storyboard has no initial view controller")
        }

        window.rootViewController = initialVC
>>>>>>> master
        self.window = window
        window.makeKeyAndVisible()
        
        
        
    }

    func sceneDidDisconnect(_ scene: UIScene) {
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
    }

    func sceneWillResignActive(_ scene: UIScene) {
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
    }
}
