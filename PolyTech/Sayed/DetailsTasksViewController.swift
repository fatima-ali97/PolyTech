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
    @IBOutlet weak var acceptedDateLabel: UILabel!
    @IBOutlet weak var AddressLabel: UILabel!
    @IBOutlet weak var voicePlayerContainer: UIView? // Add this to your storyboard
    
    // Voice player
    private var voicePlayerView: VoicePlayerView?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTextViewUI()
        setupVoicePlayer()
        
        if let currentTask = task {
            updateUI(with: currentTask)
            loadVoiceNote(for: currentTask)
        } else {
            setErrorMessage()
        }
        
        setupSegmentedControlAppearance()
    }
    
    // MARK: - Voice Player Setup
    
    private func setupVoicePlayer() {
        // Check if container exists
        guard let container = voicePlayerContainer else {
            print("⚠️ Voice player container not available")
            return
        }
        
        // Create voice player view
        let playerView = VoicePlayerView()
        playerView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(playerView)
        
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: container.topAnchor),
            playerView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            playerView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        voicePlayerView = playerView
        
        // Hide initially until we know if there's a voice note
        container.isHidden = true
        
        // Set error callback
        playerView.onError = { [weak self] errorMessage in
            self?.showAlert("Voice Note Error", message: errorMessage)
        }
    }
    
    private func loadVoiceNote(for task: TaskRequest) {
        let docID = task.documentID  // Use it directly
        
        // Fetch the complete document to get voiceUrl
        db.collection("maintenanceRequest").document(docID).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Error fetching document: \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists,
                  let data = document.data() else {
                print("ℹ️ Document does not exist")
                self.voicePlayerContainer?.isHidden = true
                return
            }
            
            // Check if voiceUrl exists and is a String
            if let voiceUrlString = data["voiceUrl"] as? String, !voiceUrlString.isEmpty {
                print("✅ Voice note found: \(voiceUrlString)")
                self.voicePlayerContainer?.isHidden = false
                self.voicePlayerView?.configure(with: voiceUrlString)
            } else {
                print("ℹ️ No voice note available for this task")
                self.voicePlayerContainer?.isHidden = true
            }
        }
    }
    func updateUI(with task: TaskRequest) {
        clientLabel.text = "User: \(task.fullName)"
        taskIDLabel.text = "Task ID: \(task.id)"
        let formattedCategory = task.category.replacingOccurrences(of: "_", with: " ")
        descriptionLabel.text = formattedCategory
        acceptedDateLabel.text = "Accepted on: \(task.acceptedDate)"
        AddressLabel.text = "\(task.address)"
        notesTextView.text = task.note
        switch task.status {
        case "pending":
            statusSegmentedControl.selectedSegmentIndex = 0
        case "in progress", "in_progress":
            statusSegmentedControl.selectedSegmentIndex = 1
        case "completed":
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
        var newStatus = "in_progress"
        
        if selectedIndex == 0 { newStatus = "pending" }
        else if selectedIndex == 2 { newStatus = "completed" }
        
        let newNote = notesTextView.text ?? ""

        db.collection("maintenanceRequest").document(docID).updateData([
                    "status": newStatus,
                    "note": newNote,
                    "updatedAt": FieldValue.serverTimestamp()
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
    
    private func showAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
