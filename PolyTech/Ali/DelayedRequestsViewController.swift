//
//  DelayedRequestsViewController.swift
//  PolyTech
//
//  Created by BP-36-212-04 on 31/12/2025.
//

import UIKit
import FirebaseFirestore

final class DelayedRequestsViewController: UIViewController {

    struct DelayedRequest {
        let id: String
        let title: String
    }
    
    struct TechnicianItem {
        let id: String
        let name: String
    }

    @IBOutlet weak var tableView: UITableView!

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var delayedRequests: [DelayedRequest] = []

    private let delayedAfterDays: Int = 3
    
    private var technicians: [TechnicianItem] = []
    private var techListener: ListenerRegistration?

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self

        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 110

        loadDelayedRequests()
        loadTechnicians()
    }

    deinit {
        listener?.remove()
        techListener?.remove()
    }

    private func loadDelayedRequests() {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -delayedAfterDays, to: Date())!
        let cutoffTimestamp = Timestamp(date: cutoffDate)

        listener = db.collection("requests")
            .whereField("createdAt", isLessThanOrEqualTo: cutoffTimestamp)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error = error {
                    print("❌ delayed requests error:", error)
                    return
                }

                guard let docs = snapshot?.documents else {
                    self.delayedRequests = []
                    self.tableView.reloadData()
                    return
                }

                self.delayedRequests = docs.compactMap { doc in
                    let data = doc.data()

                    guard let title = data["requestName"] as? String else { return nil }

                    if let status = data["status"] as? String,
                       status.lowercased() == "completed" {
                        return nil
                    }

                    return DelayedRequest(id: doc.documentID, title: title)
                }

                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
    }
    
    private func loadTechnicians() {
        techListener = db.collection("technicians")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error = error {
                    print("❌ technicians load error:", error)
                    return
                }

                let docs = snapshot?.documents ?? []
                self.technicians = docs.compactMap { doc in
                    let data = doc.data()
                    guard let name = data["name"] as? String else { return nil }
                    return TechnicianItem(id: doc.documentID, name: name)
                }

                self.technicians.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
    }
    
    private func assign(requestId: String, technician: TechnicianItem) {
        let updates: [String: Any] = [
            "assignedTechnicianId": technician.id,
            "assignedTechnicianName": technician.name,
            "status": "in_progress",
            "updatedAt": FieldValue.serverTimestamp()
        ]

        db.collection("requests").document(requestId).updateData(updates) { error in
            if let error = error {
                print("❌ Failed to reassign:", error)
            } else {
                print("✅ Reassigned request \(requestId) to \(technician.name)")
            }
        }
    }
}

extension DelayedRequestsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return delayedRequests.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

            guard let cell = tableView.dequeueReusableCell(withIdentifier: "DelayedRequestCell", for: indexPath) as? DelayedRequestCell else {
                return UITableViewCell()
            }

        let request = delayedRequests[indexPath.row]
        cell.titleLabel.text = request.title

        // Make it a menu button
        cell.reassignButton.showsMenuAsPrimaryAction = true

        // Build menu actions from technicians
        let actions = technicians.map { tech in
            UIAction(title: tech.name) { [weak self] _ in
                self?.assign(requestId: request.id, technician: tech)
            }
        }

        cell.reassignButton.menu = UIMenu(title: "Re-assign to", children: actions)


            return cell
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
