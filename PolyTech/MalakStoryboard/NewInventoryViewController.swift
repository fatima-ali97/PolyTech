import UIKit
import FirebaseFirestore
import FirebaseAuth


class NewInventoryViewController: UIViewController {

    var isEditMode = false
    var documentId: String?
    var existingData: [String: Any]?
    
    @IBOutlet weak var requestName: UITextField!
    @IBOutlet weak var itemName: UITextField!
    @IBOutlet weak var category: UITextField!
    @IBOutlet weak var quantity: UITextField!
    @IBOutlet weak var location: UITextField!
    @IBOutlet weak var reason: UITextField!
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
            pageTitle.text = "Edit Inventory Request"
            savebtn.setTitle("Edit", for: .normal)
            showFields()
        } else {
            pageTitle.text = "New Inventory Request"
            savebtn.setTitle("Save", for: .normal)
        }
    }
    
    func showFields() {
        guard let data = existingData else { return }

        requestName.text = data["requestName"] as? String
        itemName.text = data["itemName"] as? String
        category.text = data["category"] as? String
        location.text = data["location"] as? String
        reason.text = data["reason"] as? String

        if let quantityNum = data["quantity"] as? Int {
            quantity.text = "\(quantityNum)"
        }
    }

    
    
    @objc func backTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func Savebtn(_ sender: UIButton) {

        guard let requestNameText = requestName.text, !requestNameText.isEmpty,
              let itemNameText = itemName.text, !itemNameText.isEmpty,
              let quantityText = quantity.text,
              let quantityValue = Int(quantityText), quantityValue > 0 else {

            let alert = UIAlertController(
                title: "Error",
                message: "Please fill in the fields correctly",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        let data: [String: Any] = [
            "requestName": requestNameText,
            "itemName": itemNameText,
            "category": category.text ?? "",
            "quantity": quantityValue,
            "location": location.text ?? "",
            "reason": reason.text ?? "",
            "updatedAt": Timestamp()
        ]

        if isEditMode, let documentId = documentId {
            updateRequest(documentId: documentId, data: data)
        } else {
            newRequest(data: data)
        }
    }

    
    func newRequest(data: [String: Any]) {
        var newData = data
        newData["createdAt"] = Timestamp()

        database.collection("inventoryRequest").addDocument(data: newData) { [weak self] error in
            self?.handleInventoryResult(
                error: error,
                successMessage: "Inventory request created successfully"
            )
        }
    }

    
    func updateRequest(documentId: String, data: [String: Any]) {
        database.collection("inventoryRequest")
            .document(documentId)
            .updateData(data) { [weak self] error in
                self?.handleInventoryResult(
                    error: error,
                    successMessage: "Inventory request updated successfully"
                )
            }
    }

    func handleInventoryResult(error: Error?, successMessage: String) {
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
    


