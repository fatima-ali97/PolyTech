//
//  TechniciansViewController.swift
//  PolyTech
//
//  Created by BP-36-212-02 on 18/12/2025.
//

import UIKit

class TechniciansViewController: UITableViewController {
    
    enum Availability {
        case available
        case busy
    }
    
    struct Technician {
        let name: String
        let availability: Availability
        let tasks: Int
        let hours: String
    }
    
    private var technicians: [Technician] = [
        .init(name: "Ali Fadhel", availability: .available, tasks: 142, hours: "6:00 - 12:00"),
        .init(name: "Fatema Hasan", availability: .busy, tasks: 98, hours: "12:00 - 18:00"),
        .init(name: "Fatima Ali", availability: .busy, tasks: 187, hours: "18:00 - 24:00")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 160
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
            cell.statusLabel.text = "busy"
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
}
