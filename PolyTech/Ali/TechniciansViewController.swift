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
    }
    
    struct Technician {
        let name: String
        let availability: Availability
        let tasks: Int
        let hours: String
    }
    
    private var technicians: [Technician] = []
    
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
        
        switch tech.availability {
        case .available:
            cell.statusLabel.text = "Available"
            cell.statusLabel.backgroundColor = UIColor.systemBlue
            cell.dotView.backgroundColor = UIColor.systemBlue
        case .busy:
            cell.statusLabel.text = "Busy"
            cell.statusLabel.backgroundColor = UIColor.systemRed
            cell.dotView.backgroundColor = UIColor.systemRed
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
    
    deinit {
        listener?.remove()
    }
}
