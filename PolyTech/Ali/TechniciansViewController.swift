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
        let name: String
        let availability: Availability
        let tasks: Int
        let hours: String
    }
    
    private var technicians: [Technician] = []
    
    var requestIdToReassign: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 160
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 120, right: 0)
        tableView.scrollIndicatorInsets = tableView.contentInset
        
        startTechniciansListener()
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
            cell.statusPillView.backgroundColor = .systemBlue
            cell.dotView.backgroundColor = .systemBlue

        case .busy:
            cell.statusLabel.text = "Busy"
            cell.statusPillView.backgroundColor = .systemRed
            cell.dotView.backgroundColor = .systemRed

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
        listener = db.collection("technicians").addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }
            
            if let error = error {
                print("❌ technicians listener error:", error)
                return
            }
            
            let docs = snapshot?.documents ?? []
            print("✅ technicians docs:", docs.count)
            
            self.technicians = docs.compactMap { doc in
                let data = doc.data()
                print("DOC", doc.documentID, data)
                
                guard
                    let name = data["name"] as? String,
                    let availabilityRaw = data["availability"] as? String,
                    let availability = Availability(rawValue: availabilityRaw),
                    let tasks = data["tasks"] as? Int,
                    let hours = data["hours"] as? String
                else {
                    print("⚠️ Skipping doc \(doc.documentID) due to missing/wrong fields")
                    return nil
                }
                
                return Technician(name: name, availability: availability, tasks: tasks, hours: hours)
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
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
            let startYesterday = cal.date(byAdding: .day, value: -1, to: start)!
            return (now >= startYesterday && now <= end)
        }

        return (now >= start && now <= end)
    }

    
    deinit {
        listener?.remove()
    }
}
