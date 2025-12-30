import UIKit
import FirebaseFirestore
import FirebaseAuth

class ReturnInventoryViewController: UIViewController {

    var isEditMode = false
    var documentId: String?
    var existingData: [String: Any]?
    
    @IBOutlet weak var itemName: UITextField!
    @IBOutlet weak var category: UITextField!
    @IBOutlet weak var quantity: UITextField!
    @IBOutlet weak var reason: UITextField!
    @IBOutlet weak var condition: UITextField!
    @IBOutlet weak var returnbtn: UIButton!
    @IBOutlet weak var pageTitle: UILabel!
    @IBOutlet weak var backBtn: UIImageView!
    
 
    let database = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isEditMode {
            pageTitle.text = "Edit Return Inventory"
            returnbtn.setTitle("Edit", for: .normal)
            showFields()
        } else {
            pageTitle.text = "New Return Inventory"
            returnbtn.setTitle("Save", for: .normal)
        }
        setupBackBtnButton()
    }
    
    
    private func setupBackBtnButton() {

        backBtn.isUserInteractionEnabled = true

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backBtnTapped))
        backBtn.addGestureRecognizer(tapGesture)
    }
    
    @objc func backBtnTapped() {

        let storyboard = UIStoryboard(name: "HomePage", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "HomeViewController") as? HomeViewController else {
            print("HomeViewController not found in storyboard")
            return
        }
        
        navigationController?.pushViewController(vc, animated: true)
    }

    func showFields() {
        guard let data = existingData else { return }
        
        itemName.text = data["itemName"] as? String
        category.text = data["category"] as? String
        reason.text = data["reason"] as? String
        condition.text = data["condition"] as? String
        
        if let quantityValue = data["quantity"] as? Int {
            quantity.text = "\(quantityValue)"
        }
    }
    

    @IBAction func Returnbtn(_ sender: UIButton) {
        guard
            let itemNameText = itemName.text, !itemNameText.isEmpty,
            let categoryText = category.text, !categoryText.isEmpty,
            let quantityText = quantity.text, let quantityValue = Int(quantityText),
            let reasonText = reason.text, !reasonText.isEmpty,
            let conditionText = condition.text, !conditionText.isEmpty
        else {
            let alert = UIAlertController(
                title: "Error",
                message: "Please fill in all fields correctly",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        var data: [String: Any] = [
            "itemName": itemNameText,
            "category": categoryText,
            "quantity": quantityValue,
            "reason": reasonText,
            "condition": conditionText
        ]
        
        if isEditMode, let documentId = documentId {
            data["updatedAt"] = Timestamp()
            
            database.collection("returnInventoryRequest")
                .document(documentId)
                .updateData(data) { [weak self] error in
                    self?.handleResult(error: error, successMessage: "Return inventory updated successfully")
                }
        } else {
            data["createdAt"] = Timestamp()
            
            database.collection("returnInventoryRequest")
                .addDocument(data: data) { [weak self] error in
                    self?.handleResult(error: error, successMessage: "Return inventory saved successfully")
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
