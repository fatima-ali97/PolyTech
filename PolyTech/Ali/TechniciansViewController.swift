//
//  TechniciansViewController.swift
//  PolyTech
//
//  Created by BP-36-212-02 on 18/12/2025.
//

import UIKit
import FirebaseFirestore

class TechniciansViewController: UITableViewController {
    
    private let db = Firestore.firestore()
    
    enum Availability: String {
        case available
        case busy
        case unavailable
    }
    
    struct Technician {
        let id: String
        let name: String
        let availability: Availability
        let tasks: Int
        let solvedTasks: Int
        let hours: String
    }
    
    private var technicians: [Technician] = []
    
    var requestIdToReassign: String?
    
    private var techListener: ListenerRegistration?
    private var requestsListener: ListenerRegistration?

    private var techBase: [(id: String, name: String, availability: Availability, hours: String)] = []
    private var activeCounts: [String: Int] = [:]
    private var solvedCounts: [String: Int] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 160
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 120, right: 0)
        tableView.scrollIndicatorInsets = tableView.contentInset
        
        startTechniciansListener()
        startRequestsCountsListener()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        technicians.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TechnicianCardCell", for: indexPath) as? TechnicianCardCell else {
            return UITableViewCell()
        }
        
        let tech = technicians[indexPath.row]
        
        cell.nameLabel.text = tech.name
        cell.tasksValueLabel.text = "\(tech.tasks)"
        cell.hoursValueLabel.text = tech.hours
        
        let withinHours = isNowWithinHours(tech.hours)
        let displayAvailability: Availability = withinHours ? tech.availability : .unavailable

        switch displayAvailability {
        case .available:
            cell.statusLabel.text = "Available"
            cell.statusPillView.backgroundColor = .accent
            cell.dotView.backgroundColor = .accent

        case .busy:
            cell.statusLabel.text = "Busy"
            cell.statusPillView.backgroundColor = .error
            cell.dotView.backgroundColor = .error

        case .unavailable:
            cell.statusLabel.text = "Unavailable"
            cell.statusPillView.backgroundColor = .systemGray
            cell.dotView.backgroundColor = .systemGray
        }

        
        return cell
        
        /*
         // MARK: - Navigation
         
         // In a storyboard-based application, you will often want to do a little preparation before navigation
         override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         // Get the new view controller using segue.destination.
         // Pass the selected object to the new view controller.
         }
         */
        
    }
    
    private var listener: ListenerRegistration?
    
    private func startTechniciansListener() {
        techListener = db.collection("technicians").addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }
            if let error = error { print(error); return }

            self.techBase = (snapshot?.documents ?? []).compactMap { doc in
                let data = doc.data()
                guard
                    let name = data["name"] as? String,
                    let availabilityRaw = data["availability"] as? String,
                    let availability = Availability(rawValue: availabilityRaw),
                    let hours = data["hours"] as? String
                else { return nil }

                return (id: doc.documentID, name: name, availability: availability, hours: hours)
            }

            self.rebuildTechnicians()
        }
    }
    
    private func startRequestsCountsListener() {
        requestsListener = db.collection("maintenanceRequest").addSnapshotListener { [weak self] snap, err in
            guard let self else { return }
            if let err = err { print(err); return }

            var active: [String: Int] = [:]
            var solved: [String: Int] = [:]

            for doc in snap?.documents ?? [] {
                let data = doc.data()
                guard
                    let techId = data["technicianId"] as? String,
                    let status = data["status"] as? String
                else { continue }

                if status == "completed" {
                    solved[techId, default: 0] += 1
                } else if status == "pending" || status == "in_progress" {
                    active[techId, default: 0] += 1
                }
            }

            self.activeCounts = active
            self.solvedCounts = solved
            self.rebuildTechnicians()
        }
    }
    
    private func rebuildTechnicians() {
        self.technicians = techBase.map { t in
            Technician(
                id: t.id,
                name: t.name,
                availability: t.availability,
                tasks: activeCounts[t.id, default: 0],
                solvedTasks: solvedCounts[t.id, default: 0],
                hours: t.hours
            )
        }

        DispatchQueue.main.async { self.tableView.reloadData() }
    }
    
    private func isNowWithinHours(_ hoursString: String, now: Date = Date()) -> Bool {
        let s = hoursString.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.isEmpty { return false }

        let lower = s.lowercased()
        
        if lower.contains("24/7") || lower.contains("247") || lower.contains("24x7") || lower.contains("24-7") {
            return true
        }
        
        if lower.contains("closed") || lower.contains("off") { return false }

        let normalized = s
            .replacingOccurrences(of: "–", with: "-")
            .replacingOccurrences(of: "—", with: "-")
            .replacingOccurrences(of: "to", with: "-")
            .replacingOccurrences(of: " ", with: "")

        let parts = normalized.split(separator: "-", omittingEmptySubsequences: true)
        guard parts.count == 2 else { return false }

        let startStr = String(parts[0])
        let endStr   = String(parts[1])

        let formats = ["HH:mm", "H:mm", "h:mma", "hh:mma", "h:mm a", "hh:mm a", "ha", "h a"]

        func parseTimeToday(_ timeStr: String) -> Date? {
            let cal = Calendar.current
            let day = cal.dateComponents([.year, .month, .day], from: now)

            for f in formats {
                let df = DateFormatter()
                df.locale = Locale(identifier: "en_US_POSIX")
                df.dateFormat = f

                if let t = df.date(from: timeStr) {
                    let tc = cal.dateComponents([.hour, .minute], from: t)
                    var comps = DateComponents()
                    comps.year = day.year
                    comps.month = day.month
                    comps.day = day.day
                    comps.hour = tc.hour
                    comps.minute = tc.minute
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

        let end = (endSameDay >= start) ? endSameDay : cal.date(byAdding: .day, value: 1, to: endSameDay)!

        if endSameDay < start {
            let endTomorrow = cal.date(byAdding: .day, value: 1, to: endSameDay)!

            if now >= start {
                return now <= endTomorrow
            } else {
                return now <= endSameDay
            }
        }

        return (now >= start && now <= end)
    }

    
    deinit {
        listener?.remove()
        techListener?.remove()
        requestsListener?.remove()
    }
}
