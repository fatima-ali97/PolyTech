//
//  TechniciansViewController.swift
//  PolyTech
//
//  Created by BP-36-212-02 on 18/12/2025.
//

import UIKit

class TechniciansViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
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
        Technician(name: "Ali Fadhel", availability: .available, tasks: 142, hours: "6:00 - 12:00"),
        Technician(name: "Fatema Hasan", availability: .busy, tasks: 98, hours: "12:00 - 18:00"),
        Technician(name: "Fatima Ali", availability: .busy, tasks: 187, hours: "18:00 - 24:00")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 170
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

extension TechniciansViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        technicians.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
        
    }
}
