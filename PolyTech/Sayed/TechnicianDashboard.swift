import UIKit
import FirebaseAuth
import FirebaseFirestore

class TechnicianDashboardViewController: UIViewController {

    @IBOutlet weak var totalRequestsCard: UIView!
    @IBOutlet weak var pendingCard: UIView!
    @IBOutlet weak var inProgressCard: UIView!
    @IBOutlet weak var completedCard: UIView!
    @IBOutlet weak var StatusCard: UIView!
    
    @IBOutlet weak var totalCountLabel: UILabel!
    @IBOutlet weak var pendingCountLabel: UILabel!
    @IBOutlet weak var inProgressCountLabel: UILabel!
    @IBOutlet weak var completedCountLabel: UILabel!
    
    @IBOutlet weak var completedLegendLabel: UILabel!
    @IBOutlet weak var inProgressLegendLabel: UILabel!
    @IBOutlet weak var pendingLegendLabel: UILabel!
    
    @IBOutlet weak var donutChartView: DonutChartViewTwo!
    // Popup view
    //vars for notifications
    var userId: String?
    private var notificationListener: ListenerRegistration?
    private var unreadCount: Int = 0
    let db = Firestore.firestore()
    
    
    
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
        notificationListener = db.collection("Notifications")
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
        
        db.collection("Notifications")
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
    
    
    
    
    @objc private func didTapBell() {
        let notificationsVC = NotificationsViewController()
        let navController = UINavigationController(rootViewController: notificationsVC)
        present(navController, animated: true)
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let bell = UIBarButtonItem(
            image: UIImage(systemName: "bell.fill"),
            style: .plain,
            target: self,
            action: #selector(didTapBell)
        )
        navigationItem.rightBarButtonItem = bell
        
        navigationController?.navigationBar.prefersLargeTitles = true
        setupUIElements()
        fetchDashboardData()
        
        //notification functions
        //setupNotificationButton()
        setupNotificationPopup()
        fetchUnreadNotificationCount()
    }
    
    func fetchDashboardData() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }

        db.collection("maintenanceRequest").addSnapshotListener { [weak self] (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
                print("Error fetching tasks: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            let visibleTasks = documents.filter { doc in
                let data = doc.data()
                let status = data["status"] as? String ?? ""
                let techID = data["technicianID"] as? String ?? ""
                let declinedBy = data["declinedBy"] as? [String] ?? []

                if status == "Pending" {
                    return !declinedBy.contains(currentUserID)
                } else {
                    return techID == currentUserID
                }
            }

            let total = visibleTasks.count
            let pending = visibleTasks.filter { ($0.data()["status"] as? String) == "Pending" }.count
            let inProgress = visibleTasks.filter { ($0.data()["status"] as? String) == "In Progress" }.count
            let completed = visibleTasks.filter { ($0.data()["status"] as? String) == "Completed" }.count

            DispatchQueue.main.async {
                self?.updateDashboardUI(total: total, pending: pending, inProgress: inProgress, completed: completed)
                self?.updateChartData(pending: pending, inProgress: inProgress, completed: completed)
            }
        }
    }
    
    func updateDashboardUI(total: Int, pending: Int, inProgress: Int, completed: Int) {
        totalCountLabel.text = "\(total)"
        pendingCountLabel.text = "\(pending)"
        inProgressCountLabel.text = "\(inProgress)"
        completedCountLabel.text = "\(completed)"
        
        completedLegendLabel.text = "Completed (\(completed))"
        inProgressLegendLabel.text = "In Progress (\(inProgress))"
        pendingLegendLabel.text = "Pending (\(pending))"
        }
    
    func updateChartData(pending: Int, inProgress: Int, completed: Int) {
            guard let chart = donutChartView else { return }
            
            let colorCompleted = UIColor(red: 0.00, green: 0.42, blue: 0.85, alpha: 1.0)
            let colorInProgress = UIColor(red: 0.35, green: 0.67, blue: 0.93, alpha: 1.0)
            let colorPending = UIColor(red: 0.56, green: 0.62, blue: 0.67, alpha: 1.0)

            chart.segments = [
                DonutChartViewTwo.Segment(value: CGFloat(completed), color: colorCompleted),
                DonutChartViewTwo.Segment(value: CGFloat(inProgress), color: colorInProgress),
                DonutChartViewTwo.Segment(value: CGFloat(pending), color: colorPending)
            ]
            
            chart.setNeedsDisplay()
        }
    
    func setupUIElements() {
            let cornerRadius: CGFloat = 12.0
            
            [totalRequestsCard, pendingCard, inProgressCard, completedCard, StatusCard].forEach { card in
                if let card = card {
                    applyCardStyling(to: card, cornerRadius: cornerRadius)
                }
            }
        }
        
        func applyCardStyling(to view: UIView, cornerRadius: CGFloat) {
            view.layer.cornerRadius = cornerRadius
            view.layer.masksToBounds = false
            view.layer.shadowColor = UIColor.black.cgColor
            view.layer.shadowOpacity = 0.1
            view.layer.shadowOffset = CGSize(width: 0, height: 2)
            view.layer.shadowRadius = 4.0
            view.backgroundColor = .white
        }

    @IBAction func taskListButtonTapped(_ sender: UIButton) {
    }
}
