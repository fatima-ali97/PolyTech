//
//  TasksViewController.swift
//  PolyTech
//
//  Created by BP-36-212-02 on 14/12/2025.
//

import UIKit

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

    let allTasks: [TaskModel] = [
        TaskModel(id: "001", client: "Ali", dueDate: "2025-12-20", status: "Pending", description: "Install new HVAC system.", Address: "Compus A"),
        TaskModel(id: "002", client: "Mohammed", dueDate: "2025-12-25", status: "In Progress", description: "Install new HVAC system.", Address: "Compus A"),
        TaskModel(id: "003", client: "Layla", dueDate: "2025-12-28", status: "Completed", description: "Install new HVAC system.", Address: "Compus A"),
        TaskModel(id: "004", client: "Sara", dueDate: "2025-12-30", status: "Pending", description: "Install HVAC system.", Address: "Compus A")
    ]

    var tasks: [TaskModel] = []
    var currentFilter: TaskFilter = .all

    override func viewDidLoad() {
        super.viewDidLoad()

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

        switch filter {
        case .all:
            tasks = allTasks
        case .pending:
            tasks = allTasks.filter { $0.status == TaskFilter.pending.rawValue }
        case .inProgress:
            tasks = allTasks.filter { $0.status == TaskFilter.inProgress.rawValue }
        case .completed:
            tasks = allTasks.filter { $0.status == TaskFilter.completed.rawValue }
        }

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

        tasks = allTasks.filter { task in
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
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
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
        print("Status button tapped for Task ID: \(task.id) - Current Status: \(task.status)")
    }
}
