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
    case all = "All"
    case pending = "Pending"
    case inProgress = "In Progress"
    case completed = "Completed"
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
    
    let db = Firestore.firestore()
    var allTasksFromFirebase: [TaskRequest] = []

    var tasks: [TaskRequest] = []
    var currentFilter: TaskFilter = .all

    override func viewDidLoad() {
        super.viewDidLoad()
        fetchTasksFromFirebase()
        
        guard let tableView = tableView,
              let searchBar = searchBar,
              let filterStackView = filterStackView else {
            return
        }

        tableView.dataSource = self
        tableView.delegate = self
        
        searchBar.delegate = self

        if let searchTextField = searchBar.value(forKey: "searchField") as? UITextField {
            searchTextField.inputAssistantItem.leadingBarButtonGroups = []
            searchTextField.inputAssistantItem.trailingBarButtonGroups = []
        }

        filterTasks(by: .all)

        if let allButton = filterStackView.arrangedSubviews.first(where: { ($0 as? UIButton)?.titleLabel?.text == "All" }) as? UIButton {
            updateFilterButtonsUI(selectedButton: allButton)
        }
    }

    func updateFilterButtonsUI(selectedButton: UIButton) {
        for view in filterStackView.arrangedSubviews {
            if let button = view as? UIButton {
                if button == selectedButton {
                    button.alpha = 1.0
                } else {
                    button.alpha = 0.7
                }
            }
        }
    }

    func filterTasks(by filter: TaskFilter) {
        self.currentFilter = filter
        
        var filteredResults: [TaskRequest] = []
        
        switch filter {
        case .all:
            filteredResults = allTasksFromFirebase
        default:
            filteredResults = allTasksFromFirebase.filter { $0.status == filter.rawValue }
        }

        self.tasks = filteredResults.sorted(by: { $0.dueDate > $1.dueDate })
        
        updateNoTasksLabel()
        tableView.reloadData()
    }




    @IBAction func filterButtonTapped(_ sender: UIButton) {
        guard let buttonTitle = sender.titleLabel?.text,
              let selectedFilter = TaskFilter(rawValue: buttonTitle) else {
            return
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
        cell.clientLabel.text = "Client: \(task.client)"
        cell.dueDateLabel.text = "Due: \(task.dueDate)"
        cell.statusBtn.setTitle(task.status, for: .normal)

        cell.delegate = self

        return cell
    }
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filterTasks(by: currentFilter)
            return
        }

        let lowercasedSearchText = searchText.lowercased()

        tasks = allTasksFromFirebase.filter { task in
            let matchesSearchText = task.client.lowercased().contains(lowercasedSearchText) ||
                task.id.lowercased().contains(lowercasedSearchText) ||
                task.status.lowercased().contains(lowercasedSearchText)

            if currentFilter == .all {
                return matchesSearchText
            } else {
                return matchesSearchText && task.status == currentFilter.rawValue
            }
        }
        
        updateNoTasksLabel()
        tableView.reloadData()
    }

    
    func updateNoTasksLabel() {
        if tasks.isEmpty {
            noTasksLabel.alpha = 1.0
        } else {
            noTasksLabel.alpha = 0.0
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}


extension TasksViewController: TaskCellDelegate {
    
    func didTapViewDetails(on cell: TaskTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let task = tasks[indexPath.row]
        print("Details tapped for Task ID: \(task.id) - Attempting transition to DetailsTasksViewController")
        
        let storyboard = UIStoryboard(name: "Technician", bundle: nil)
        
        guard let detailsVC = storyboard.instantiateViewController(withIdentifier: "DetailsVC") as? DetailsTasksViewController else {
            print("Error: Could not instantiate DetailsTasksViewController. Check Storyboard ID.")
            return
        }
        
        detailsVC.task = task
        
        navigationController?.pushViewController(detailsVC, animated: true)
    }
    func didTapStatusButton(on cell: TaskTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let task = tasks[indexPath.row]
    }
    
    func fetchTasksFromFirebase() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }

        db.collection("TasksRequests")
            .whereField("technicianID", isEqualTo: currentUserID)
            .addSnapshotListener { (querySnapshot, error) in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    return
                }

                self.allTasksFromFirebase = querySnapshot?.documents.compactMap { document in
                    return TaskRequest(docID: document.documentID, dictionary: document.data())
                } ?? []
                
                self.filterTasks(by: self.currentFilter)
            }
    }
    
}
