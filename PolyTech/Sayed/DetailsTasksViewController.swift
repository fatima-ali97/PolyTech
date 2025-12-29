//
//  DetailsTasksViewController.swift
//  PolyTech
//
//  Created by BP-19-130-11 on 15/12/2025.
//

import UIKit
import FirebaseFirestore

class DetailsTasksViewController: UIViewController {
    
    var task: TaskModel?
    let db = Firestore.firestore()
    
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
        
        let normalAttributes = [NSAttributedString.Key.foregroundColor: UIColor.lightGray]
        statusSegmentedControl.setTitleTextAttributes(normalAttributes, for: .normal)
        
        let selectedAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        statusSegmentedControl.setTitleTextAttributes(selectedAttributes, for: .selected)
    }

    func updateUI(with task: TaskModel) {
        clientLabel.text = "Client: \(task.client)"
        taskIDLabel.text = "Task ID: \(task.id)"
        descriptionLabel.text = task.description ?? "No Description"
        dueDateLabel.text = "Scheduled for \(task.dueDate)"
        AddressLabel.text = task.Address ?? "No Address"
        
        notesTextView.text = task.note ?? ""
        
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
        saveChangesToFirebase()
    }
    
    func saveChangesToFirebase() {
            guard let taskId = task?.id else { return }
            
            let selectedIndex = statusSegmentedControl.selectedSegmentIndex
            var newStatus = TaskFilter.pending.rawValue
            
            if selectedIndex == 1 { newStatus = TaskFilter.inProgress.rawValue }
            else if selectedIndex == 2 { newStatus = TaskFilter.completed.rawValue }
            
            let newNote = notesTextView.text ?? ""

            db.collection("tasks").whereField("id", isEqualTo: taskId).getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    return
                }

                guard let document = snapshot?.documents.first else {
                    print("No document found with ID: \(taskId)")
                    return
                }

                document.reference.updateData([
                    "status": newStatus,
                    "note": newNote
                ]) { err in
                    if let err = err {
                        print("Error updating document: \(err)")
                    } else {
                        print("✅ Document successfully updated")
                        self.showSuccessAlert()
                    }
                }
            }
        }

    func showSuccessAlert() {
        let alert = UIAlertController(
            title: "Success",
            message: "Changes have been saved successfully to Firebase",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
