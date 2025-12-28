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
    @IBOutlet weak var notesTextView: UITextView!
    @IBOutlet weak var dueDateLabel: UILabel!
    @IBOutlet weak var AddressLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTextViewUI()
        
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
        
        switch task.status {
        case TaskFilter.pending.rawValue:
            statusSegmentedControl.selectedSegmentIndex = 0 // pending
        case TaskFilter.inProgress.rawValue:
            statusSegmentedControl.selectedSegmentIndex = 1 // in progress
        case TaskFilter.completed.rawValue:
            statusSegmentedControl.selectedSegmentIndex = 2 // completed
        default:
            statusSegmentedControl.selectedSegmentIndex = UISegmentedControl.noSegment
        }
    }


    func setupTextViewUI() {
            notesTextView.layer.borderWidth = 1.0
            notesTextView.layer.borderColor = UIColor.lightGray.cgColor
            notesTextView.layer.cornerRadius = 8.0
            notesTextView.clipsToBounds = true
        }

    @IBAction func updateStatusTapped(_ sender: UIButton) {
        print("Status update button tapped.")
    }

    @IBAction func updateNoteTapped(_ sender: UIButton) {
        let newNote = notesTextView.text ?? ""
        print("New note saved: \(newNote)")
    }
}
