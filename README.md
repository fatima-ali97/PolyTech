# PolyTech




## code-snippet-1
add this to the   
override func viewDidLoad() {super.viewDidLoad()} function



```swift

// Get userId from UserDefaults if needed
        if userId == nil {
            userId = UserDefaults.standard.string(forKey: "userId")
        }
        
        print("User ID: \(userId ?? "No user ID")")
        
        // Tab bar will be visible automatically
        // No need to call hideCustomTabBar(false) unless you previously hid it



```


## code-snippet-2
to force show the tab bar in ur screen
```swift
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Ensure tab bar is visible when this screen appears
        if let tabBarController = self.tabBarController as? CustomTabBarController {
            tabBarController.hideCustomTabBar(false, animated: true)
        }

```
## code-snippet-3
logout btn

```swift
@IBAction func logoutButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Logout", message: "Are you sure you want to logout?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive) { _ in
            AuthManager.shared.logout(from: self)
        })
        
        present(alert, animated: true)
    }
    ```
