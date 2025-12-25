import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

class InventoryViewController: UIViewController {
    
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func viewButtonTapped(_ sender: UIButton) {
        let documentId = "item\(sender.tag)"
        fetchInventoryDetails(documentId: documentId)
    }
    
    @IBAction func editButtonTapped(_ sender: UIButton) {
        openNewInventoryPage()
    }
    
    @IBAction func deleteButtonTapped(_ sender: UIButton) {
        showAlert(title: "Success", message: "Request is removed successfully.")
    }
    
    func fetchInventoryDetails(documentId: String) {
        let docRef = db.collection("Inventory").document(documentId)
        docRef.getDocument { snapshot, error in
            if let error = error {
                print("Error fetching inventory: \(error.localizedDescription)")
                return
            }
            
            guard let data = snapshot?.data() else {
                print("No inventory data found for \(documentId)")
                return
            }
            
            DispatchQueue.main.async {
                self.showInventoryDetailsPopup(data: data)
            }
        }
    }
    
    func showInventoryDetailsPopup(data: [String: Any]) {
        let requestName = data["requestName"] as? String ?? "N/A"
        let itemName = data["itemName"] as? String ?? "N/A"
        let category = data["category"] as? String ?? "N/A"
        let location = data["location"] as? String ?? "N/A"
        let reason = data["reason"] as? String ?? "N/A"
        
        let message = """
        Request Name: \(requestName)
        Item Name: \(itemName)
        Category: \(category)
        Location: \(location)
        Reason: \(reason)
        """
        
        let alert = UIAlertController(title: "Inventory Details", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func openNewInventoryPage() {
        let storyboard = UIStoryboard(name: "MalakStoryboard", bundle: nil)
        guard let newInventoryVC = storyboard.instantiateViewController(withIdentifier: "NewInventory") as? NewInventoryViewController else {
            print("NewInventoryViewController not found in MalakStoryboard")
            return
        }
        
        if let nav = self.navigationController {
            nav.pushViewController(newInventoryVC, animated: true)
        } else {
            present(newInventoryVC, animated: true)
        }
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
