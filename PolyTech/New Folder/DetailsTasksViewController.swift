//
//  DetailsTasksViewController.swift
//  PolyTech
//
//  Created by BP-19-130-11 on 15/12/2025.
//

import UIKit

class DetailsTasksViewController: UIViewController {
    
    var task: TaskModel?

    @IBOutlet weak var clientLabel: UILabel!
    @IBOutlet weak var taskIDLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var statusSegmentedControl:UISegmentedControl!
    @IBOutlet weak var notesTextField: UITextField!
    @IBOutlet weak var dueDateLabel: UILabel!
    @IBOutlet weak var AddressLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        if let currentTask = task {
            updateUI(with: currentTask)
        } else {
            clientLabel.text = "Error: Task data missing"
            taskIDLabel.text = "Error: Task data missing"
            descriptionLabel.text = "Error: Task data missing"
            dueDateLabel.text = "Error: Task data missing"
            AddressLabel.text = "Error: Task data missing"
        }
    }

    func updateUI(with task: TaskModel) {
        clientLabel.text = "Client: \(task.client)"
        taskIDLabel.text = "Task ID: \(task.id)"
        descriptionLabel.text = task.description ?? "No Description"
        dueDateLabel.text = "Scheduled for \(task.dueDate)"
        AddressLabel.text = task.Address ?? "No Address"
        
        if let statusIndex = TaskFilter.allCases
            .dropFirst()
            .firstIndex(where: { $0.rawValue == task.status }) {
            if statusIndex < statusSegmentedControl.numberOfSegments {
                statusSegmentedControl.selectedSegmentIndex = statusIndex
            }
        } else {
            statusSegmentedControl.selectedSegmentIndex = UISegmentedControl.noSegment
        }
    }


    @IBAction func updateStatusTapped(_ sender: UIButton) {
        print("Status update button tapped.")
    }

    @IBAction func updateNoteTapped(_ sender: UIButton) {
        let newNote = notesTextField.text ?? ""
        print("New note saved: \(newNote)")
    }
}
