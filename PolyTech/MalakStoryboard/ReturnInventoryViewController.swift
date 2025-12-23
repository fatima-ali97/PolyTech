import UIKit
import FirebaseFirestore
import FirebaseAuth

class ReturnInventoryViewController: UIViewController {
    
    @IBOutlet weak var itemName: UITextField!
    @IBOutlet weak var category: UITextField!
    @IBOutlet weak var quantity: UITextField!
    @IBOutlet weak var reason: UITextField!
    @IBOutlet weak var condition: UITextField!
    @IBOutlet weak var Backbtn: UIImageView!
    
    let database = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        Backbtn.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backTapped))
        Backbtn.addGestureRecognizer(tapGesture)
    }
    
    @objc func backTapped() {
        navigationController?.popViewController(animated: true)
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
    
    let data: [String: Any] = [
        "itemName": itemNameText,
        "category": categoryText,
        "quantity": quantityValue,
        "reason": reasonText,
        "condition": conditionText,
        "createdAt": Timestamp()
    ]
    
        database.collection("returnInventoryRequest").addDocument(data: data) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                let alert = UIAlertController(
                    title: "Error",
                    message: error.localizedDescription,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            } else {
                let alert = UIAlertController(
                    title: "Success",
                    message: "Return Inventory saved successfully",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                    self.navigationController?.popViewController(animated: true)
                })
                self.present(alert, animated: true)
            }}
    }
}
