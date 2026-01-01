import UIKit

class HomeViewController: UIViewController {
    
    @IBOutlet weak var Notificationbtn: UIImageView!
    @IBOutlet weak var FAQbtn: UIButton!
    @IBOutlet weak var chatBot: UIImageView!
    @IBOutlet weak var OptionsBtn: UIButton!
    
    var userId: String?
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let tabBarController = self.tabBarController as? BaseCustomTabBarController {
            tabBarController.hideCustomTabBar(false, animated: true)
        }
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if userId == nil {
            userId = UserDefaults.standard.string(forKey: "userId")
        }
        loadData()
        setupNotificationButton()
        setupChatBotBtn()
    }
    
    
    private func setupNotificationButton() {
        
        Notificationbtn.isUserInteractionEnabled = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(notificationTapped))
        Notificationbtn.addGestureRecognizer(tapGesture)
    }
    
    @objc func notificationTapped() {
        
        let notificationsVC = NotificationsViewController()
        let navController = UINavigationController(rootViewController: notificationsVC)
        present(navController, animated: true)
        
    }
    
    private func loadData() {
        guard let userId = userId else {
            print("⚠️ No user ID available")
            return
        }
        
        print("✅ Loading student dashboard for user: \(userId)")
    }
    
    @IBAction func faqButtonTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "FAQ", bundle: nil)
        guard let vc = storyboard.instantiateViewController(
            withIdentifier: "FAQViewController"
        ) as? FAQViewController else {
            print("❌ FAQViewController not found or wrong class")
            return
        }
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    
    
    private func setupChatBotBtn() {
        
        chatBot.isUserInteractionEnabled = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(chatBotTapped))
        chatBot.addGestureRecognizer(tapGesture)
    }
    
    @objc func chatBotTapped() {
        let storyboard = UIStoryboard(name: "ChatBot", bundle: nil)
        guard let vc = storyboard.instantiateViewController(
            withIdentifier: "ChatBotViewController"
        ) as? ChatBotViewController else {
            print("❌ ChatBotViewController not found or wrong class")
            return
        }
        
        navigationController?.pushViewController(vc, animated: true)
        
        
        
        
    }
    
}
