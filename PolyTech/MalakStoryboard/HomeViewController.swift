import UIKit
import FirebaseFirestore

class HomeViewController: UIViewController {
    
    @IBOutlet weak var Notificationbtn: UIImageView!
    @IBOutlet weak var FAQbtn: UIButton!
    @IBOutlet weak var chatBot: UIImageView!
    @IBOutlet weak var OptionsBtn: UIButton!
    
    var userId: String?
    private let database = Firestore.firestore()
    private var notificationListener: ListenerRegistration?
    private var unreadCount: Int = 0
    
    // Badge label for unread count
    private let badgeLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .systemRed
        label.textColor = .white
        label.font = .systemFont(ofSize: 12, weight: .bold)
        label.textAlignment = .center
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        label.isHidden = true
        return label
    }()
    
    // Popup view
    private let notificationPopup: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.2
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 8
        view.alpha = 0
        view.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        return view
    }()
    
    private let popupLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let tabBarController = self.tabBarController as? BaseCustomTabBarController {
            tabBarController.hideCustomTabBar(false, animated: true)
        }
        navigationController?.setNavigationBarHidden(true, animated: animated)
        
        // Refresh unread count when view appears
        fetchUnreadNotificationCount()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if userId == nil {
            userId = UserDefaults.standard.string(forKey: "userId")
        }
        loadData()
        setupNotificationButton()
        setupChatBotBtn()
        setupNotificationBadge()
        setupNotificationPopup()
        startListeningForNotifications()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Remove listener when view disappears
        notificationListener?.remove()
    }
    
    // MARK: - Setup Notification Badge
    
    private func setupNotificationBadge() {
        // Add badge to notification bell
        //Notificationbtn.addSubview(badgeLabel)
//        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
//        
//        NSLayoutConstraint.activate([
//            badgeLabel.topAnchor.constraint(equalTo: Notificationbtn.topAnchor, constant: -5),
//            badgeLabel.trailingAnchor.constraint(equalTo: Notificationbtn.trailingAnchor, constant: 5),
//            badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 20),
//            badgeLabel.heightAnchor.constraint(equalToConstant: 20)
//        ])
    }
    
    // MARK: - Setup Notification Popup
    
    private func setupNotificationPopup() {
        // Add popup to view
        view.addSubview(notificationPopup)
        notificationPopup.addSubview(popupLabel)
        
        notificationPopup.translatesAutoresizingMaskIntoConstraints = false
        popupLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Position popup below notification bell (adjust these values based on your layout)
            notificationPopup.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            notificationPopup.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            notificationPopup.widthAnchor.constraint(equalToConstant: 200),
            notificationPopup.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),
            
            // Label inside popup
            popupLabel.topAnchor.constraint(equalTo: notificationPopup.topAnchor, constant: 12),
            popupLabel.leadingAnchor.constraint(equalTo: notificationPopup.leadingAnchor, constant: 12),
            popupLabel.trailingAnchor.constraint(equalTo: notificationPopup.trailingAnchor, constant: -12),
            popupLabel.bottomAnchor.constraint(equalTo: notificationPopup.bottomAnchor, constant: -12)
        ])
        
        // Add tap gesture to dismiss popup
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissPopup))
        notificationPopup.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Fetch Unread Notifications
    
    private func startListeningForNotifications() {
        guard let userId = userId else {
            print("⚠️ No user ID available")
            return
        }
        
        // Real-time listener for unread notifications
        notificationListener = database.collection("Notifications")
            .whereField("userId", isEqualTo: userId)
            .whereField("isRead", isEqualTo: false)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error fetching notifications: \(error.localizedDescription)")
                    return
                }
                
                let count = querySnapshot?.documents.count ?? 0
                self.unreadCount = count
                
                DispatchQueue.main.async {
                    //self.updateBadge(count: count)
                }
            }
    }
    
    private func fetchUnreadNotificationCount() {
        guard let userId = userId else { return }
        
        database.collection("Notifications")
            .whereField("userId", isEqualTo: userId)
            .whereField("isRead", isEqualTo: false)
            .getDocuments { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error fetching unread count: \(error.localizedDescription)")
                    return
                }
                
                let count = querySnapshot?.documents.count ?? 0
                self.unreadCount = count
                
                DispatchQueue.main.async {
                   // self.updateBadge(count: count)
                    
                    // Show popup only on first load if there are unread notifications
                    if count > 0 {
                        self.showNotificationPopup(count: count)
                    }
                }
            }
    }
    
    // MARK: - Update Badge
    
//    private func updateBadge(count: Int) {
//        if count > 0 {
//            badgeLabel.text = count > 99 ? "99+" : "\(count)"
//            badgeLabel.isHidden = false
//            
//            // Animate badge appearance
//            badgeLabel.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
//            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8) {
//                self.badgeLabel.transform = .identity
//            }
//        } else {
//            badgeLabel.isHidden = true
//        }
//    }
    
    // MARK: - Show Notification Popup
    
    private func showNotificationPopup(count: Int) {
        // Set popup text
        let message = count == 1
            ? "You have 1 unread notification"
            : "You have \(count) unread notifications"
        popupLabel.text = message
        
        // Animate popup appearance
        UIView.animate(withDuration: 0.4, delay: 0.2, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            self.notificationPopup.alpha = 1
            self.notificationPopup.transform = .identity
        }
        
        // Auto-dismiss after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.dismissPopup()
        }
    }
    
    @objc private func dismissPopup() {
        UIView.animate(withDuration: 0.3) {
            self.notificationPopup.alpha = 0
            self.notificationPopup.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }
    }
    
    // MARK: - Original Setup Methods
    
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
