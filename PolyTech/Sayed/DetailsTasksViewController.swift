//
//  DetailsTasksViewController.swift
//  PolyTech
//
//  Created by BP-19-130-11 on 15/12/2025.
//

import UIKit
import FirebaseFirestore

class DetailsTasksViewController: UIViewController {
    
    var task: TaskRequest?
    let db = Firestore.firestore()
    
    @IBOutlet weak var clientLabel: UILabel!
    @IBOutlet weak var taskIDLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var statusSegmentedControl: UISegmentedControl!
    @IBOutlet weak var notesTextView: UITextView!
    @IBOutlet weak var dueDateLabel: UILabel!
    @IBOutlet weak var AddressLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTextViewUI()
        
        if let currentTask = task {
            updateUI(with: currentTask)
        } else {
            setErrorMessage()
        }
        
        setupSegmentedControlAppearance()
    }

    func updateUI(with task: TaskRequest) {
        clientLabel.text = "Client: \(task.client)"
        taskIDLabel.text = "Task ID: \(task.id)"
        descriptionLabel.text = task.description
        dueDateLabel.text = "Scheduled for \(task.dueDate)"
        AddressLabel.text = "Address: \(task.address)"
        notesTextView.text = task.note
        switch task.status {
        case "Pending":
            statusSegmentedControl.selectedSegmentIndex = 0
        case "In Progress":
            statusSegmentedControl.selectedSegmentIndex = 1
        case "Completed":
            statusSegmentedControl.selectedSegmentIndex = 2
        default:
            statusSegmentedControl.selectedSegmentIndex = 1
        }
    }

    @IBAction func updateStatusTapped(_ sender: UIButton) {
        saveChangesToFirebase()
    }
    
    func saveChangesToFirebase() {
        guard let docID = task?.documentID else { return }
        
        let selectedIndex = statusSegmentedControl.selectedSegmentIndex
        var newStatus = "In Progress"
        
        if selectedIndex == 0 { newStatus = "Pending" }
        else if selectedIndex == 2 { newStatus = "Completed" }
        
        let newNote = notesTextView.text ?? ""

        db.collection("TasksRequests").document(docID).updateData([
                "status": newStatus,
                "note": newNote
            ]) { error in
            if let error = error {
                print("Error updating document: \(error.localizedDescription)")
            } else {
                print("Success: Task updated to \(newStatus)")
                self.showSuccessAlert()
            }
        }
    }

    func setupTextViewUI() {
        notesTextView.layer.borderWidth = 1.0
        notesTextView.layer.borderColor = UIColor.lightGray.cgColor
        notesTextView.layer.cornerRadius = 8.0
    }
    
    func setErrorMessage() {
        clientLabel.text = "Error: Data missing"
    }
    
    func setupSegmentedControlAppearance() {
        statusSegmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.lightGray], for: .normal)
        statusSegmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
    }

    func showSuccessAlert() {
        let alert = UIAlertController(title: "Success", message: "Changes saved", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
}
