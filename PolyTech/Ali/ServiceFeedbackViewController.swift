//
//  ServiceFeedbackViewController.swift
//  PolyTech
//
//  Created by BP-36-212-02 on 18/12/2025.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class ServiceFeedbackViewController: UIViewController, UITextViewDelegate {
    var requestId: String?
    var requestType: String?
    @IBOutlet weak var technicianNameLabel: UILabel!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var notesTextView: UITextView!
    @IBOutlet var starButtons: [UIButton]!
    
    private var loadedTechnicianId: String?
    
    private var rating = 0 {
        didSet { updateSubmitButtonState() }
    }
    
    private let placeholderText = "Add a note..."
    
    private let db = Firestore.firestore()

    //var requestId: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateStars()
        updateSubmitButtonState()
        loadRequestInfo()
        
        notesTextView.layer.cornerRadius = 12
        notesTextView.layer.borderWidth = 1
        notesTextView.layer.borderColor = UIColor.systemGray.cgColor
        notesTextView.layer.masksToBounds = true
        
        notesTextView.textContainerInset = UIEdgeInsets(
            top: 12, left: 12, bottom: 12, right: 12)
        
        notesTextView.font = UIFont.preferredFont(forTextStyle: .body)
        
        notesTextView.text = placeholderText
        notesTextView.textColor = .secondaryLabel
        
        notesTextView.isEditable = true
        notesTextView.isSelectable = true
        notesTextView.isUserInteractionEnabled = true
        
        notesTextView.delegate = self
    }
    
    @IBAction func starTapped(_ sender: UIButton) {
            rating = sender.tag
            updateStars()
        }
    
    private func updateStars() {
            for button in starButtons {
                if button.tag <= rating {
                    button.setImage(UIImage(systemName: "star.fill"), for: .normal)
                } else {
                    button.setImage(UIImage(systemName: "star"), for: .normal)
                }
            }
        }
    
    private func updateSubmitButtonState() {
        let enabled = rating > 0
        submitButton.isEnabled = enabled
        
        if enabled {
            submitButton.backgroundColor = UIColor.systemBlue
            submitButton.setTitleColor(.white, for: .normal)
            submitButton.alpha = 1
        } else {
            submitButton.backgroundColor = UIColor.systemGray4
            submitButton.setTitleColor(.systemGray, for: .normal)
            submitButton.alpha = 1
        }
        
        submitButton.layer.cornerRadius = 12
        
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == placeholderText {
            textView.text = ""
            textView.textColor = .label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = placeholderText
            textView.textColor = .secondaryLabel
        }
    }
    
    private func loadTechnicianForRequest() {
        guard let requestId = requestId else {
            technicianNameLabel.text = "—"
            return
        }

        db.collection("maintenanceRequest").document(requestId).getDocument { [weak self] snap, error in
            guard let self else { return }

            if let error = error {
                print("Failed to fetch request: \(error)")
                self.technicianNameLabel.text = "—"
                return
            }

            guard let data = snap?.data() else {
                self.technicianNameLabel.text = "—"
                return
            }

            // If you stored technicianName directly on the request, use it (fastest)
            if let techName = data["technicianName"] as? String, !techName.isEmpty {
                self.technicianNameLabel.text = techName
                return
            }

            // Otherwise, fetch technician doc by technicianId
            guard let techId = data["technicianId"] as? String, !techId.isEmpty else {
                self.technicianNameLabel.text = "—"
                return
            }

            self.db.collection("technicians").document(techId).getDocument { [weak self] techSnap, error in
                guard let self else { return }

                if let error = error {
                    print("Failed to fetch technician: \(error)")
                    self.technicianNameLabel.text = "—"
                    return
                }

                let techData = techSnap?.data()
                let name = (techData?["name"] as? String) ?? "—"
                self.technicianNameLabel.text = name
            }
        }
    }
    
    private func loadRequestInfo() {
        guard let requestId = requestId else { return }

        db.collection("maintenanceRequest").document(requestId).getDocument { [weak self] snap, error in
            guard let self else { return }

            if let error = error {
                print("Failed to load request: \(error)")
                return
            }

            guard let data = snap?.data() else { return }

            // Pull technicianId from whichever field your request uses
            let techId =
                (data["technicianId"] as? String) ??
                (data["assignedTechnicianId"] as? String) ??
                ""

            self.loadedTechnicianId = techId.isEmpty ? nil : techId
        }
    }
    
    @IBAction func submitTapped(_ sender: UIButton) {
        guard let requestId = requestId, !requestId.isEmpty else {
            print("Missing requestId")
            return
        }
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User not logged in")
            return
        }
        guard rating > 0 else { return }

        let rawNotes = notesTextView.text ?? ""
        let notes = (rawNotes == placeholderText) ? "" : rawNotes.trimmingCharacters(in: .whitespacesAndNewlines)

        sender.isEnabled = false

        let data: [String: Any] = [
            "requestId": requestId,
            "userId": userId,
            "technicianId": loadedTechnicianId ?? "",
            "rating": rating,
            "notes": notes,
            "createdAt": FieldValue.serverTimestamp()
        ]

        db.collection("serviceFeedback").addDocument(data: data) { [weak self] error in
            guard let self else { return }
            sender.isEnabled = true

            if let error = error {
                print("Failed to submit feedback: \(error)")
                return
            }
            
            let requestRef = db.collection("maintenanceRequest").document(requestId)

            requestRef.updateData([
                "feedbackSubmitted": true,
                "feedbackSubmittedAt": FieldValue.serverTimestamp()
            ])

            let alert = UIAlertController(title: "Thank you!",
                                          message: "Your feedback was submitted.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                self.dismiss(animated: true)
            })
            self.present(alert, animated: true)
        }
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
