import UIKit

class HomeViewController: UIViewController {
    
    @IBOutlet weak var Notificationbtn: UIImageView!
    @IBOutlet weak var FAQbtn: UIButton!
    @IBOutlet weak var chatBot: UIImageView!
    
    
    var userId: String?
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Ensure tab bar is visible
        if let tabBarController = self.tabBarController as? BaseCustomTabBarController {
            tabBarController.hideCustomTabBar(false, animated: true)
        }
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Get userId from UserDefaults if not passed
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

        let storyboard = UIStoryboard(name: "NotificationStoryboard", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "NotificationsViewController") as? NotificationsViewController else {
            print("NotificationsViewController not found in storyboard")
            return
        }
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func loadData() {
           guard let userId = userId else {
               print("⚠️ No user ID available")
               return
           }
           
           print("✅ Loading student dashboard for user: \(userId)")
           // Load student-specific data here
       }
       
    @IBAction func faqButtonTapped(_ sender: UIButton) {
        print("FAQ button tapped!") // Debugging log
        
        let storyboard = UIStoryboard(name: "FAQ", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "FAQViewController") as? FAQViewController else {
            print("FAQViewController not found in storyboard")
            return
        }

        print("FAQViewController successfully instantiated")
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    
    
    private func setupChatBotBtn() {

        chatBot.isUserInteractionEnabled = true

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(chatBotTapped))
        chatBot.addGestureRecognizer(tapGesture)
    }
    
    @objc func chatBotTapped() {

        let storyboard = UIStoryboard(name: "ChatBot", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "ChatBotViewController") as? ChatBotViewController else {
            print("ChatBotViewController not found in storyboard")
            return
        }
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    
    }

