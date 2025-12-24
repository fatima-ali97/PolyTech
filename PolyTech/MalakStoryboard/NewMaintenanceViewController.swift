import UIKit
import FirebaseFirestore
import FirebaseAuth


class NewMaintenanceViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var isEditMode = false
    var documentId: String?
    var existingData: [String: Any]?
    
    @IBOutlet weak var requestName: UITextField!
    @IBOutlet weak var category: UITextField!
    @IBOutlet weak var location: UITextField!
    @IBOutlet weak var urgency: UITextField!
    @IBOutlet weak var imageUpload: UITextField!
    @IBOutlet weak var Backbtn: UIImageView!
    @IBOutlet weak var savebtn: UIButton!
    @IBOutlet weak var pageTitle: UILabel!
    
    let database = Firestore.firestore()
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Backbtn.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backTapped))
        Backbtn.addGestureRecognizer(tapGesture)
        
        if isEditMode {
            pageTitle.text = "Edit Maintenance Request"
            savebtn.setTitle("Edit", for: .normal)
            showFields()
        } else {
            pageTitle.text = "New Maintenance Request"
            savebtn.setTitle("Save", for: .normal)
        }
    }

    
    func showFields() {
        guard let data = existingData else { return }
        
        requestName.text = data["requestName"] as? String
        category.text = data["category"] as? String
        location.text = data["location"] as? String
        urgency.text = data["urgency"] as? String
        
        requestName.isEnabled = false
    }

    
    
    @objc func backTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func Savebtn(_ sender: UIButton) {
        guard let requestNameText = requestName.text, !requestNameText.isEmpty,
              let categoryText = category.text, !categoryText.isEmpty,
              let locationText = location.text, !locationText.isEmpty else {
            let alert = UIAlertController(title: "Error", message: "Please fill in the fields", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
            return
        }
        
        let urgencyText = urgency.text ?? ""
        
        let data: [String: Any] = [
            "requestName": requestNameText,
            "category": categoryText,
            "location": locationText,
            "urgency": urgencyText,
            "updatedAt": Timestamp()
        ]
        
        if isEditMode, let documentId = documentId {
            database.collection("maintenanceRequest")
                .document(documentId)
                .updateData(data) { [weak self] error in
                    self?.handleResult(error: error, successMessage: "Maintenance request updated successfully")
                }
        } else {
            var newData = data
            newData["createdAt"] = Timestamp()
            database.collection("maintenanceRequest").addDocument(data: newData) { [weak self] error in
                self?.handleResult(error: error, successMessage: "Maintenance request saved successfully")
            }
        }
    }
    
    func handleResult(error: Error?, successMessage: String) {
        if let error = error {
            let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        } else {
            let alert = UIAlertController(title: "Success", message: successMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                self.navigationController?.popViewController(animated: true)
            })
            present(alert, animated: true)
        }
    }

}
