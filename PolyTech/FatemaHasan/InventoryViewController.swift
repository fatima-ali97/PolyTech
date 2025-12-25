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
        if sender.tag == 0 {
            showAlert(title: "Error", message: "Button tag is not set. Cannot load inventory item.")
            return
        }
        let documentId = "item\(sender.tag)"
        fetchInventoryDetails(documentId: documentId)
    }

    @IBAction func editButtonTapped(_ sender: UIButton) {
        openEditInventoryPage()
    }

    @IBAction func deleteButtonTapped(_ sender: UIButton) {
        showAlert(title: "Success", message: "Request is removed successfully.")
    }

    func fetchInventoryDetails(documentId: String) {
        let docRef = db.collection("Inventory").document(documentId)

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

    func openEditInventoryPage() {
        let storyboard = UIStoryboard(name: "MalakStoryboard", bundle: nil)

        guard let editInventoryVC = storyboard.instantiateViewController(
            withIdentifier: "NewInventory"
        ) as? NewInventoryViewController else {
            print("NewInventoryViewController not found")
            return
        }

        if let navController = navigationController {
            navController.pushViewController(editInventoryVC, animated: true)
        } else {
            present(editInventoryVC, animated: true)
        }
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
