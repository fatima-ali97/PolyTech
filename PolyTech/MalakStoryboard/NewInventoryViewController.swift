import UIKit
import FirebaseFirestore
import FirebaseAuth

class NewInventoryViewController: UIViewController {

    @IBOutlet weak var requestName: UITextField!
    @IBOutlet weak var itemName: UITextField!
    @IBOutlet weak var category: UITextField!
    @IBOutlet weak var quantity: UITextField!
    @IBOutlet weak var location: UITextField!
    @IBOutlet weak var reason: UITextField!
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
    
    @IBAction func Savebtn(_ sender: UIButton) {
        
        guard let requestNameText = requestName.text, !requestNameText.isEmpty,
              let itemNameText = itemName.text, !itemNameText.isEmpty,
              let quantityText = quantity.text, let quantity = Int(quantityText), quantity > 0 else {
            let alert = UIAlertController(title: "Error", message: "Please fill in the fields", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
            return
        }
        
        
        let categoryText = category.text ?? ""
        let locationText = location.text ?? ""
        let reasonText = reason.text ?? ""
        

        let data: [String: Any] = [
            "requestName": requestNameText,
            "itemName": itemNameText,
            "category": categoryText,
            "quantity": quantityText,
            "location": locationText,
            "reason": reasonText,
            "createdAt": Timestamp()
        ]

        database.collection("inventoryRequest").addDocument(data: data) { [weak self] error in
                guard let self = self else { return }
                if error == nil {
                    let alert = UIAlertController(title: "Success", message: "Inventory request saved successfully", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        self.navigationController?.popViewController(animated: true)
                    })
                    self.present(alert, animated: true)
                } else {
                    print("Error: \(error!.localizedDescription)")
                }


        }
    }
    

}
