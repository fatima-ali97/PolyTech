import UIKit
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

class NewMaintenanceViewController: UIViewController, UIImagePickerControllerDelegate {

    @IBOutlet weak var requestName: UITextField!
    @IBOutlet weak var category: UITextField!
    @IBOutlet weak var location: UITextField!
    @IBOutlet weak var urgency: UITextField!
    @IBOutlet weak var imageUpload: UITextField!
    
    let database = Firestore.firestore()
    let storage = Storage.storage()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func Savebtn(_ sender: UIButton) {
        
    }
    
    let category = category.text ?? ""
    let location = location.text ?? ""
    let urgency = urgency.text ?? ""

    let data: [String: Any] = [
        "requestName": requestName,
        "category": category,
        "location": location,
        "urgency": urgency,
        "createdAt": Timestamp()
    ]
    
    database.collection("maintenanceRequest").addDocument(data: data) { [weak self] error in
            guard let self = self else { return }
            if error == nil {
                let alert = UIAlertController(title: "Success", message: "Maintenance request saved successfully", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                    self.navigationController?.popViewController(animated: true)
                })
                self.present(alert, animated: true)
            } else {
                print("Error: \(error!.localizedDescription)")
            }


    }
}
