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
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var notesTextView: UITextView!
    @IBOutlet var starButtons: [UIButton]!
    
    private var rating = 0 {
        didSet { updateSubmitButtonState() }
    }
    
    private let placeholderText = "Add a note..."
    
    private let db = Firestore.firestore()

    var requestId: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateStars()
        updateSubmitButtonState()
        
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

            // success UI
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
