//
//  TasksViewController.swift
//  PolyTech
//
//  Created by BP-36-212-02 on 14/12/2025.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

enum TaskFilter: String, CaseIterable {
    case all = "all"
    case pending = "pending"
    case inProgress = "in_progress"
    case completed = "completed"
}

protocol TaskCellDelegate: AnyObject {
    func didTapViewDetails(on cell: TaskTableViewCell)
    func didTapStatusButton(on cell: TaskTableViewCell)
}

class TasksViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var filterStackView: UIStackView!
    @IBOutlet weak var noTasksLabel: UILabel!
    
    @IBOutlet weak var btnAll: UIButton!
    @IBOutlet weak var btnPending: UIButton!
    @IBOutlet weak var btnInProgress: UIButton!
    @IBOutlet weak var btnCompleted: UIButton!
    
    let db = Firestore.firestore()
    var allTasksFromFirebase: [TaskRequest] = []
    var tasks: [TaskRequest] = []
    var currentFilter: TaskFilter = .all

    override func viewDidLoad() {
        super.viewDidLoad()
        fetchTasksFromFirebase()
        
        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self

        filterTasks(by: .all)
        updateFilterButtonsUI(selectedButton: btnAll)
    }

    func filterTasks(by filter: TaskFilter) {
        self.currentFilter = filter
        
        let filteredResults: [TaskRequest]
        if filter == .all {
            filteredResults = allTasksFromFirebase
        } else {
            filteredResults = allTasksFromFirebase.filter { $0.status.lowercased() == filter.rawValue }
        }

        self.tasks = filteredResults.sorted(by: { $0.createdAt > $1.createdAt })
        updateNoTasksLabel()
        tableView.reloadData()
    }

    func updateFilterButtonsUI(selectedButton: UIButton?) {
        let buttons = [btnAll, btnPending, btnInProgress, btnCompleted]
        buttons.forEach { button in
            button?.alpha = (button == selectedButton) ? 1.0 : 0.7
        }
    }

    @IBAction func filterButtonTapped(_ sender: UIButton) {
        let selectedFilter: TaskFilter
        
        if sender == btnAll {
            selectedFilter = .all
        } else if sender == btnPending {
            selectedFilter = .pending
        } else if sender == btnInProgress {
            selectedFilter = .inProgress
        } else if sender == btnCompleted {
            selectedFilter = .completed
        } else {
            selectedFilter = .all
        }

        searchBar.text = ""
        filterTasks(by: selectedFilter)
        updateFilterButtonsUI(selectedButton: sender)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath) as? TaskTableViewCell else {
            return UITableViewCell()
        }

        let task = tasks[indexPath.row]
        cell.taskIdLabel.text = "ID: \(task.id)"
        cell.clientLabel.text = "User: \(task.fullName)"
        cell.dueDateLabel.text = "Due: \(task.createdAt)"
        
        if task.technicianID == "" {
            cell.statusBtn.setTitle("Accept Request", for: .normal)
            cell.statusBtn.backgroundColor = .systemGreen
        } else {
            let cleanStatus = task.status.replacingOccurrences(of: "_", with: " ").capitalized
            cell.statusBtn.setTitle(cleanStatus, for: .normal)
            cell.statusBtn.backgroundColor = .systemBlue
        }
        
        cell.delegate = self
        return cell
    }

    func fetchTasksFromFirebase() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }

        db.collection("maintenanceRequest")
            .addSnapshotListener { [weak self] (querySnapshot, _) in
                guard let self = self, let docs = querySnapshot?.documents else { return }

                self.allTasksFromFirebase = docs.compactMap { document in
                    let data = document.data()
                    let techID = data["technicianID"] as? String ?? ""
                    let status = data["status"] as? String ?? ""
                    let declinedBy = data["declinedBy"] as? [String] ?? []

                    let isAvailable = (status == "pending" && techID == "") && !declinedBy.contains(currentUserID)
                    let isMine = (techID == currentUserID)

                    if isAvailable || isMine {
                        return TaskRequest(docID: document.documentID, dictionary: data)
                    }
                    return nil
                }
                
                self.fetchFullNamesAndReload()
            }
    }
    
    func fetchFullNamesAndReload() {
        let group = DispatchGroup()
        
        for index in 0..<self.allTasksFromFirebase.count {
            let uid = self.allTasksFromFirebase[index].userId
            if uid.isEmpty { continue }
            
            group.enter()
            self.db.collection("users").document(uid).getDocument { (snap, _) in
                if let name = snap?.data()?["fullName"] as? String {
                    self.allTasksFromFirebase[index].fullName = name
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            self.filterTasks(by: self.currentFilter)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func updateNoTasksLabel() {
        noTasksLabel?.alpha = tasks.isEmpty ? 1.0 : 0.0
    }
}

// MARK: - TaskCellDelegate Implementation
extension TasksViewController: TaskCellDelegate {
    
    func didTapViewDetails(on cell: TaskTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let task = tasks[indexPath.row]
        
        if task.technicianID == "" {
            let alert = UIAlertController(title: "Access Denied",
                                          message: "Please accept the request first to view its full details.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
            return
        }
        
        let storyboard = UIStoryboard(name: "Technician", bundle: nil)
        guard let detailsVC = storyboard.instantiateViewController(withIdentifier: "DetailsVC") as? DetailsTasksViewController else { return }
        
        detailsVC.task = task
        navigationController?.pushViewController(detailsVC, animated: true)
    }

    func didTapStatusButton(on cell: TaskTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let task = tasks[indexPath.row]
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }

        if task.technicianID == "" {
            db.collection("maintenanceRequest").document(task.documentID).updateData([
                "technicianID": currentUserID,
                "status": "in_progress",
                "acceptedDate": "03/01/2026",
                "updatedAt": FieldValue.serverTimestamp()
            ]) { error in
                if let error = error {
                    print("❌ Error accepting task: \(error.localizedDescription)")
                } else {
                    print("✅ Task successfully accepted!")
                }
            }
        } else {
            print("Task is already accepted, current status: \(task.status)")
        }
    }
}
