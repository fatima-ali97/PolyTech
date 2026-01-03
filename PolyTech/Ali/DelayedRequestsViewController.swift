//
//  DelayedRequestsViewController.swift
//  PolyTech
//
//  Created by BP-36-212-04 on 31/12/2025.
//

import UIKit
import FirebaseFirestore

final class DelayedRequestsViewController: UIViewController {

    enum Availability: String {
        case available
        case busy
        case unavailable
    }

    struct DelayedRequest {
        let id: String
        let title: String
    }

    struct TechnicianItem {
        let id: String
        let name: String
        let hours: String
    }

    @IBOutlet weak var tableView: UITableView!

    private let db = Firestore.firestore()
    private var delayedRequests: [DelayedRequest] = []

    private let delayedAfterDays: Int = 3

    private var technicians: [TechnicianItem] = []
    private var techListener: ListenerRegistration?

    private var delayedOldListener: ListenerRegistration?
    private var rejectedListener: ListenerRegistration?
    private var activeTasksListener: ListenerRegistration?

    private var oldMap: [String: DelayedRequest] = [:]
    private var rejectedMap: [String: DelayedRequest] = [:]
    private var activeCountByTechId: [String: Int] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self

        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 110

        loadDelayedRequests()
        loadTechnicians()
        startActiveTasksListener()
    }

    deinit {
        delayedOldListener?.remove()
        rejectedListener?.remove()
        techListener?.remove()
        activeTasksListener?.remove()
    }

    private func loadDelayedRequests() {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -delayedAfterDays, to: Date())!
        let cutoffTimestamp = Timestamp(date: cutoffDate)

        func rebuildList() {
            var merged = oldMap
            rejectedMap.forEach { merged[$0.key] = $0.value }

            delayedRequests = Array(merged.values).sorted {
                $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }

            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }

        delayedOldListener = db.collection("maintenanceRequest")
            .whereField("createdAt", isLessThanOrEqualTo: cutoffTimestamp)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("delayed old error:", error)
                    return
                }

                let docs = snapshot?.documents ?? []
                self.oldMap = Dictionary(uniqueKeysWithValues: docs.compactMap { doc in
                    let data = doc.data()

                    let status = (data["status"] as? String ?? "").lowercased()
                    if status == "completed" { return nil }

                    // Hide only those that were reassigned (so it disappears after you reassign)
                    if data["reassignedAt"] != nil { return nil }

                    guard let title = data["requestName"] as? String else { return nil }
                    return (doc.documentID, DelayedRequest(id: doc.documentID, title: title))
                })

                rebuildList()
            }

        rejectedListener = db.collection("maintenanceRequest")
            .whereField("status", isEqualTo: "rejected")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("rejected error:", error)
                    return
                }

                let docs = snapshot?.documents ?? []
                self.rejectedMap = Dictionary(uniqueKeysWithValues: docs.compactMap { doc in
                    let data = doc.data()
                    guard let title = data["requestName"] as? String else { return nil }
                    return (doc.documentID, DelayedRequest(id: doc.documentID, title: title))
                })

                rebuildList()
            }
    }

    private func loadTechnicians() {
        techListener = db.collection("technicians")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("technicians load error:", error)
                    return
                }

                let docs = snapshot?.documents ?? []
                self.technicians = docs.compactMap { doc in
                    let data = doc.data()
                    guard
                        let name = data["name"] as? String,
                        let hours = data["hours"] as? String
                    else { return nil }

                    return TechnicianItem(id: doc.documentID, name: name, hours: hours)
                }

                self.technicians.sort {
                    $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }

                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
    }

    private func startActiveTasksListener() {
        activeTasksListener?.remove()

        activeTasksListener = db.collection("maintenanceRequest")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("active tasks error:", error)
                    return
                }

                var map: [String: Int] = [:]

                for doc in snapshot?.documents ?? [] {
                    let data = doc.data()
                    guard let techId = data["technicianId"] as? String else { continue }

                    let status = (data["status"] as? String ?? "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .lowercased()
                        .replacingOccurrences(of: " ", with: "_")

                    if status == "pending" || status == "in_progress" {
                        map[techId, default: 0] += 1
                    }
                }

                self.activeCountByTechId = map

                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
    }

    private func assign(requestId: String, technician: TechnicianItem) {
        let updates: [String: Any] = [
            "technicianId": technician.id,
            "assignedTechnicianName": technician.name,
            "status": "in_progress",
            "updatedAt": FieldValue.serverTimestamp(),
            "reassignedAt": FieldValue.serverTimestamp()
        ]

        db.collection("maintenanceRequest").document(requestId).updateData(updates)
    }

    private func isNowWithinHours(_ hoursString: String, now: Date = Date()) -> Bool {
        let s = hoursString.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.isEmpty { return false }

        let lower = s.lowercased()

        if lower.contains("24/7") || lower.contains("247") || lower.contains("24x7") || lower.contains("24-7") {
            return true
        }

        if lower.contains("closed") || lower.contains("off") {
            return false
        }

        let normalized = s
            .replacingOccurrences(of: "–", with: "-")
            .replacingOccurrences(of: "—", with: "-")
            .replacingOccurrences(of: "to", with: "-")
            .replacingOccurrences(of: " ", with: "")

        let parts = normalized.split(separator: "-", omittingEmptySubsequences: true)
        guard parts.count == 2 else { return false }

        let startStr = String(parts[0])
        let endStr = String(parts[1])

        let formats = ["HH:mm", "H:mm", "h:mma", "hh:mma", "h:mm a", "hh:mm a", "ha", "h a"]

        func parseTimeToday(_ timeStr: String) -> Date? {
            let cal = Calendar.current
            let today = cal.dateComponents([.year, .month, .day], from: now)

            for format in formats {
                let df = DateFormatter()
                df.locale = Locale(identifier: "en_US_POSIX")
                df.dateFormat = format

                if let parsed = df.date(from: timeStr) {
                    let time = cal.dateComponents([.hour, .minute], from: parsed)
                    var comps = DateComponents()
                    comps.year = today.year
                    comps.month = today.month
                    comps.day = today.day
                    comps.hour = time.hour
                    comps.minute = time.minute
                    return cal.date(from: comps)
                }
            }
            return nil
        }

        guard let start = parseTimeToday(startStr),
              let endSameDay = parseTimeToday(endStr) else {
            return false
        }

        let cal = Calendar.current

        if endSameDay >= start {
            return now >= start && now <= endSameDay
        } else {
            let endTomorrow = cal.date(byAdding: .day, value: 1, to: endSameDay)!
            return now >= start || now <= endTomorrow
        }
    }
}

extension DelayedRequestsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        delayedRequests.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "DelayedRequestCell",
                for: indexPath
            ) as? DelayedRequestCell
        else {
            return UITableViewCell()
        }
        
        let request = delayedRequests[indexPath.row]
        cell.titleLabel.text = request.title
        cell.reassignButton.showsMenuAsPrimaryAction = true
        
        let availableTechs = technicians.filter { tech in
            let withinHours = isNowWithinHours(tech.hours)
            let hasActiveTasks = activeCountByTechId[tech.id, default: 0] > 0
            return withinHours && !hasActiveTasks
        }
        
        let actions: [UIAction]
        
        if availableTechs.isEmpty {
            actions = [
                UIAction(
                    title: "No available technicians",
                    attributes: [.disabled],
                    handler: { _ in }
                )
            ]
        } else {
            actions = availableTechs.map { tech in
                UIAction(title: tech.name) { [weak self] _ in
                    self?.assign(requestId: request.id, technician: tech)
                }
            }
        }
        
        cell.reassignButton.menu = UIMenu(title: "Reassign to", children: actions)
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
