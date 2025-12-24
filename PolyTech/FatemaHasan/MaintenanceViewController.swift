import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

class MaintenanceViewController: UIViewController {
    
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func viewButtonTapped(_ sender: UIButton) {
        let documentId = "item\(sender.tag)"
        fetchMaintenanceDetails(documentId: documentId)
    }
    
    @IBAction func editButtonTapped(_ sender: UIButton) {
        openNewMaintenancePage()
    }
    
    @IBAction func deleteButtonTapped(_ sender: UIButton) {
        showAlert(title: "Success", message: "Request is removed successfully.")
    }
    
    func fetchMaintenanceDetails(documentId: String) {
        let docRef = db.collection("Maintenance").document(documentId)
        docRef.getDocument { snapshot, error in
            if let error = error {
                print("Error fetching maintenance: \(error.localizedDescription)")
                return
            }
            
            guard let data = snapshot?.data() else {
                print("No maintenance data found for \(documentId)")
                return
            }
            
            DispatchQueue.main.async {
                self.showMaintenanceDetailsPopup(data: data)
            }
        }
    }
    
    func showMaintenanceDetailsPopup(data: [String: Any]) {
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
        
        let alert = UIAlertController(title: "Maintenance Details", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func openNewMaintenancePage() {
        let storyboard = UIStoryboard(name: "MalakStoryboard", bundle: nil)
        guard let newMaintenanceVC = storyboard.instantiateViewController(withIdentifier: "NewMaintenance") as? NewMaintenanceViewController else {
            print("NewMaintenanceViewController not found in MalakStoryboard")
            return
        }
        
        if let nav = self.navigationController {
            nav.pushViewController(newMaintenanceVC, animated: true)
        } else {
            present(newMaintenanceVC, animated: true)
        }
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
