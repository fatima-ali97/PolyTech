import UIKit
import FirebaseFirestore

class NewInventoryViewController: UIViewController {

    @IBOutlet weak var requestName: UITextField!
    @IBOutlet weak var itemName: UITextField!
    @IBOutlet weak var category: UITextField!
    @IBOutlet weak var quantity: UITextField!
    @IBOutlet weak var location: UITextField!
    @IBOutlet weak var reason: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    
    @IBAction func Savebtn(_ sender: UIButton) {
        let requestName = requestName.text ?? ""
        let itemName = itemName.text ?? ""
        let category = category.text ?? ""
        let quantity = quantity.text ?? ""
        let location
        
        
    }
    

}
