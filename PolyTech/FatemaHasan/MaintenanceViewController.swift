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
        if sender.tag == 0 {
            showAlert(title: "Error", message: "Button tag is not set. Cannot load maintenance item.")
            return
        }
        let documentId = "item\(sender.tag)"
        fetchMaintenanceDetails(documentId: documentId)
    }

    @IBAction func editButtonTapped(_ sender: UIButton) {
        openEditMaintenancePage()
    }

    @IBAction func deleteButtonTapped(_ sender: UIButton) {
        showAlert(title: "Success", message: "Request is removed successfully.")
    }

    func fetchMaintenanceDetails(documentId: String) {
        let docRef = db.collection("Maintenance").document(documentId)

        docRef.getDocument { snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.showAlert(title: "Firebase Error", message: error.localizedDescription)
                    return
                }

                guard let snapshot = snapshot, snapshot.exists, let data = snapshot.data() else {
                    self.showAlert(title: "Not Found", message: "Document '\(documentId)' does not exist.")
                    return
                }

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

    func openEditMaintenancePage() {
        let storyboard = UIStoryboard(name: "MalakStoryboard", bundle: nil)

        guard let editMaintenanceVC = storyboard.instantiateViewController(
            withIdentifier: "NewMaintenance"
        ) as? NewInventoryViewController else {
            print("NewMaintenanceViewController not found")
            return
        }

        if let navController = navigationController {
            navController.pushViewController(editMaintenanceVC, animated: true)
        } else {
            present(editMaintenanceVC, animated: true)
        }
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
