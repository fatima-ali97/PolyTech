import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

class InventoryViewController: UIViewController {
    
    let db = Firestore.firestore()
    var selectedItem: InventoryItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Button Actions
    
    @IBAction func viewButtonTapped(_ sender: UIButton) {
        fetchUserInventoryDetails()
    }
    
    @IBAction func editButtonTapped(_ sender: UIButton) {
        print("EDIT BUTTON TAPPED")
        
        guard let item = selectedItem else {
            showAlert(title: "Error", message: "Please view inventory first")
            return
        }
        
        openEditInventoryPage(with: item)
    }
    
    @IBAction func deleteButtonTapped(_ sender: UIButton) {
        showAlert(title: "Success", message: "Request is removed successfully.")
    }
    
    // MARK: - Firebase Functions
    
    func fetchUserInventoryDetails() {
        let userIDs = [
            "7fg0EVpMQUPHR9kgBPEv7mFRgLt1",
            "njeKzS3LdubCZC8tAgrPmGlQtgh1v",
            "uHdeNxV47CZUp6SwM3s1X1GAP3t1",
            "zvyu1FR9kfabqzzb4uHRop3hbgb2"
        ]
        
        db.collection("Inventory")
            .whereField("userId", in: userIDs)
            .getDocuments { snapshot, error in
                if let error = error {
                    self.showAlert(title: "Firebase Error", message: error.localizedDescription)
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    self.showAlert(title: "No Data", message: "No inventory found for these users.")
                    return
                }
                
                // For simplicity, show the first document
                let doc = documents[0]
                let data = doc.data()
                
                // Create InventoryItem object and store in selectedItem
                let item = InventoryItem(
                    documentId: doc.documentID,
                    requestName: data["requestName"] as? String ?? "",
                    itemName: data["itemName"] as? String ?? "",
                    category: data["category"] as? String ?? "",
                    quantity: data["quantity"] as? Int ?? 0,
                    location: data["location"] as? String ?? "",
                    reason: data["reason"] as? String ?? ""
                )
                
                self.selectedItem = item
                self.showInventoryDetailsPopup(data: data)
            }
    }
    
    func showInventoryDetailsPopup(data: [String: Any]) {
        let requestName = data["requestName"] as? String ?? "N/A"
        let itemName = data["itemName"] as? String ?? "N/A"
        let category = data["category"] as? String ?? "N/A"
        let location = data["location"] as? String ?? "N/A"
        
        let message = """
        Request Name: \(requestName)
        Item Name: \(itemName)
        Category: \(category)
        Location: \(location)
        """
        
        let alert = UIAlertController(title: "Inventory Details", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Navigation
    
    func openEditInventoryPage(with item: InventoryItem) {
        let storyboard = UIStoryboard(name: "MalakStoryboard", bundle: nil)
        
        guard let vc = storyboard.instantiateViewController(
            withIdentifier: "NewInventory"
        ) as? NewInventoryViewController else {
            return
        }
        
        vc.isEditMode = true
        vc.documentId = item.documentId
        vc.existingData = [
            "requestName": item.requestName,
            "itemName": item.itemName,
            "category": item.category,
            "quantity": item.quantity,
            "location": item.location,
            "reason": item.reason
        ]
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - Alert
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
