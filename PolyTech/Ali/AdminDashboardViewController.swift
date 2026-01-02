//
//  AdminDashboardViewController.swift
//  PolyTech
//
//  Created by BP-19-130-05 on 15/12/2025.
//

import UIKit
import FirebaseFirestore

class AdminDashboardViewController: UIViewController {

    @IBOutlet weak var techOfWeekRankLabel: UILabel!
    @IBOutlet weak var techOfWeekSubtitleLabel: UILabel!
    @IBOutlet weak var techOfWeekNameLabel: UILabel!
    @IBOutlet weak var pendingStatusLabel: UILabel!
    @IBOutlet weak var inProgressStatusLabel: UILabel!
    @IBOutlet weak var completedStatusLabel: UILabel!
    @IBOutlet weak var totalRequestsLabel: UILabel!
    @IBOutlet weak var pendingLabel: UILabel!
    @IBOutlet weak var inProgressLabel: UILabel!
    @IBOutlet weak var completedLabel: UILabel!
    @IBOutlet weak var donutChartView: DonutChartView!
    @IBOutlet var cardViews: [UIView]!
    
    private let db = Firestore.firestore()
    // Popup view
    //vars for notifications
    var userId: String?
    private var notificationListener: ListenerRegistration?
    private var unreadCount: Int = 0
    
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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Admin Dashboard"
        view.backgroundColor = .systemGroupedBackground
        
        let bell = UIBarButtonItem(
            image: UIImage(systemName: "bell.fill"),
            style: .plain,
            target: self,
            action: #selector(didTapBell)
        )
        navigationItem.rightBarButtonItem = bell
        
        navigationController?.navigationBar.prefersLargeTitles = true
        
        donutChartView.segments = [
            .init(value: 749, color: UIColor.systemBlue.withAlphaComponent(0.6)),
            .init(value: 342, color: UIColor.systemBlue),
            .init(value: 156, color: UIColor.systemGray)
        ]
        
        cardViews.forEach {
            $0.applyCardStyle()
        }
        
        startDashboardListener()
        
        loadTechnicianOfTheWeek()
        
        //notification functions
        //setupNotificationButton()
        setupNotificationPopup()
        fetchUnreadNotificationCount()
    }
    
    @objc private func didTapBell() {
        let notificationsVC = NotificationsViewController()
        let navController = UINavigationController(rootViewController: notificationsVC)
        present(navController, animated: true)
    }
    
    private func loadDashboardCounts() {
        // total requests
        db.collection("requests").addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }
            if let error = error {
                print("Total requests error:", error)
                return
            }
            let total = snapshot?.documents.count ?? 0
            DispatchQueue.main.async {
                self.totalRequestsLabel.text = "\(total)"
            }
        }
        
        // pending requests
        db.collection("requests")
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error = error {
                    print("Pending error:", error)
                    return
                }
                let count = snapshot?.documents.count ?? 0
                DispatchQueue.main.async {
                    self.pendingLabel.text = "\(count)"
                    self.pendingStatusLabel.text = "Pending (\(count))"
                }
            }
        
        // in progress
        db.collection("requests")
            .whereField("status", isEqualTo: "in_progress")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error = error {
                    print("In progress error:", error)
                    return
                }
                let count = snapshot?.documents.count ?? 0
                DispatchQueue.main.async {
                    self.inProgressLabel.text = "\(count)"
                    self.inProgressStatusLabel.text = "In Progress (\(count))"
                }
            }
        
        // completed
        db.collection("requests")
            .whereField("status", isEqualTo: "completed")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error = error {
                    print("Completed error:", error)
                    return
                }
                let count = snapshot?.documents.count ?? 0
                DispatchQueue.main.async {
                    self.completedLabel.text = "\(count)"
                    self.completedStatusLabel.text = "Completed (\(count))"
                }
            }
        
    }
    
    private var requestsListener: ListenerRegistration?
    
    private func startDonutListener() {
        
        requestsListener = db.collection("requests").addSnapshotListener { [weak self] snap, err in
            guard let self else { return }
            if let err = err {
                print("Donut total fetch error:", err)
                return
            }
            
            let docs = snap?.documents ?? []
            let statuses = docs.compactMap { $0.data()["status"] as? String }
            
            let pending = statuses.filter { $0 == "pending" }.count
            let inProgress = statuses.filter { $0 == "in_progress" }.count
            let completed = statuses.filter { $0 == "completed" }.count
            
            DispatchQueue.main.async {
                self.donutChartView.segments = [
                    .init(value: CGFloat(pending), color: .statusPending),
                    .init(value: CGFloat(inProgress), color: .statusInProgress),
                    .init(value: CGFloat(completed), color: .statusCompleted)
                ]
            }
        }
    }
    
    private var dashboardListener: ListenerRegistration?

    private func startDashboardListener() {
        dashboardListener = db.collection("requests").addSnapshotListener { [weak self] snap, err in
            guard let self else { return }
            if let err = err {
                print("❌ dashboard listener error:", err)
                return
            }

            let docs = snap?.documents ?? []

            var pending = 0
            var inProgress = 0
            var completed = 0

            // For technician-of-week
            var completedByTechId: [String: Int] = [:]

            for d in docs {
                let data = d.data()
                let status = data["status"] as? String ?? ""

                switch status {
                case "pending":
                    pending += 1
                case "in_progress":
                    inProgress += 1
                case "completed":
                    completed += 1
                    if let techId = data["assignedTechnicianId"] as? String {
                        completedByTechId[techId, default: 0] += 1
                    }
                default:
                    break
                }
            }

            let total = docs.count

            DispatchQueue.main.async {
                // labels
                self.totalRequestsLabel.text = "\(total)"

                self.pendingLabel.text = "\(pending)"
                self.pendingStatusLabel.text = "Pending (\(pending))"

                self.inProgressLabel.text = "\(inProgress)"
                self.inProgressStatusLabel.text = "In Progress (\(inProgress))"

                self.completedLabel.text = "\(completed)"
                self.completedStatusLabel.text = "Completed (\(completed))"

                // donut
                self.donutChartView.segments = [
                    .init(value: CGFloat(pending), color: .statusPending),
                    .init(value: CGFloat(inProgress), color: .statusInProgress),
                    .init(value: CGFloat(completed), color: .statusCompleted)
                ]
            }

            // Tech of the week (winner from completed requests)
            guard let (bestTechId, bestSolved) = completedByTechId.max(by: { $0.value < $1.value }) else {
                DispatchQueue.main.async {
                    self.techOfWeekNameLabel.text = "—"
                    self.techOfWeekSubtitleLabel.text = "No completed tasks yet"
                    self.techOfWeekRankLabel.text = "#1"
                }
                return
            }

            self.db.collection("technicians").document(bestTechId).getDocument { [weak self] doc, err in
                guard let self else { return }
                if let err = err {
                    print("❌ tech of week tech fetch error:", err)
                    return
                }

                let name = doc?.data()?["name"] as? String ?? "Unknown"

                DispatchQueue.main.async {
                    self.techOfWeekNameLabel.text = "🎉 \(name) 🎉"
                    self.techOfWeekSubtitleLabel.text = "\(bestSolved) tasks solved"
                    self.techOfWeekRankLabel.text = "#1"
                }
            }
        }
    }

    
    private var techOfWeekListener: ListenerRegistration?

    private func loadTechnicianOfTheWeek() {
        // Listen to completed requests so it updates live
        techOfWeekListener = db.collection("requests")
            .whereField("status", isEqualTo: "completed")
            .addSnapshotListener { [weak self] snap, err in
                guard let self else { return }
                if let err = err {
                    print("❌ Tech of week requests error:", err)
                    return
                }

                // Count completed per technicianId
                var counts: [String: Int] = [:]
                for doc in snap?.documents ?? [] {
                    let data = doc.data()
                    guard let techId = data["assignedTechnicianId"] as? String else { continue }
                    counts[techId, default: 0] += 1
                }

                // If nobody has completed anything yet
                guard let (bestTechId, bestSolved) = counts.max(by: { $0.value < $1.value }) else {
                    DispatchQueue.main.async {
                        self.techOfWeekNameLabel.text = "—"
                        self.techOfWeekSubtitleLabel.text = "No completed tasks yet"
                        self.techOfWeekRankLabel.text = "#1"
                    }
                    return
                }

                // Fetch technician name from technicians collection using the ID
                self.db.collection("technicians").document(bestTechId).getDocument { [weak self] doc, err in
                    guard let self else { return }
                    if let err = err {
                        print("❌ Tech of week tech fetch error:", err)
                        return
                    }

                    let name = doc?.data()?["name"] as? String ?? "Unknown"

                    DispatchQueue.main.async {
                        self.techOfWeekNameLabel.text = "🎉 \(name) 🎉"
                        self.techOfWeekSubtitleLabel.text = "\(bestSolved) tasks solved"
                        self.techOfWeekRankLabel.text = "#1"
                    }
                }
            }
    }
    
    deinit {
        techOfWeekListener?.remove()
        dashboardListener?.remove()
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
