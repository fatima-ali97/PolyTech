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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Admin Dashboard"
        view.backgroundColor = .systemGroupedBackground
        
        let bell = UIBarButtonItem(
            image: UIImage(systemName: "bell"),
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
        
        loadDashboardCounts()
        
        startDonutListener()
        
        loadTechnicianOfTheWeek()
    }
    
    @objc private func didTapBell() {
        let alert = UIAlertController(title: "Notifications", message: "Tapped bell.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
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
    
    private func loadTechnicianOfTheWeek() {
        db.collection("technicians").getDocuments { [weak self] snapshot, error in
            guard let self else { return }
            
            if let error = error {
                print("❌ Technician of week error:", error)
                return
            }
            
            let docs = snapshot?.documents ?? []
            
            // build list
            let techs: [(name: String, solvedTasks: Int)] = docs.compactMap { doc in let data = doc.data()
                
                guard let name = data["name"] as? String else { return nil }
                
                
                // this is so that solvedTasks can come as Int or as NSNumber
                let solved = (data["solvedTasks"] as? NSNumber)?.intValue
                            ?? (data["solvedTasks"] as? Int)
                            ?? 0
                
                return (name: name, solvedTasks: solved)
            }
            
            // picking the best technician (aka technician of the week)
            guard let best = techs.max(by: { $0.solvedTasks < $1.solvedTasks }) else { return }
            
            DispatchQueue.main.async {
                self.techOfWeekNameLabel.text = "🎉 \(best.name) 🎉"
                self.techOfWeekSubtitleLabel.text = "\(best.solvedTasks) tasks solved"
                self.techOfWeekRankLabel.text = "#1"
            }
        }
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
