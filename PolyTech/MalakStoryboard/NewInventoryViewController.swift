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
    
    let database = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    

    @IBAction func Savebtn(_ sender: UIButton) {
        
        let requestName = requestName.text ?? ""
        let itemName = itemName.text ?? ""
        let category = category.text ?? ""
        let quantityText = quantity.text ?? ""
        let quantity = Int(quantityText) ?? 0
        let location = location.text ?? ""
        let reason = reason.text ?? ""
        

        let data: [String: Any] = [
            "requestName": requestName,
            "itemName": itemName,
            "category": category,
            "quantity": quantity,
            "location": location,
            "reason": reason,
            "createdAt": Timestamp()
        ]
        
        
    }
    

}
