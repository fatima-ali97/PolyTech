//
//  AdminDashboardViewController.swift
//  PolyTech
//
//  Created by BP-19-130-05 on 15/12/2025.
//

import UIKit
import FirebaseFirestore

class AdminDashboardViewController: UIViewController {

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
