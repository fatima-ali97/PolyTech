import UIKit
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

class NewMaintenanceViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationBarDelegate {
    
    @IBOutlet weak var requestName: UITextField!
    @IBOutlet weak var category: UITextField!
    @IBOutlet weak var location: UITextField!
    @IBOutlet weak var urgency: UITextField!
    @IBOutlet weak var imageUpload: UITextField!
    @IBOutlet weak var Backbtn: UIImageView!
    
    let database = Firestore.firestore()
    let storage = Storage.storage()
    
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
              let categoryText = category.text, !categoryText.isEmpty,
              let locationText = location.text, !locationText.isEmpty else {
            let alert = UIAlertController(title: "Error", message: "Please fill in the fields", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
            return
        }
        
        let urgencyText = urgency.text ?? ""
        
        let data: [String: Any] = [
            "requestName": requestNameText,
            "category": categoryText,
            "location": locationText,
            "urgency": urgencyText,
            "createdAt": Timestamp()
        ]
        
        database.collection("maintenanceRequest").addDocument(data: data) { [weak self] error in
            guard let self = self else { return }

            if error == nil {
                let alert = UIAlertController(
                    title: "Success",
                    message: "Maintenance request saved successfully",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                    self.navigationController?.popViewController(animated: true)
                })
                self.present(alert, animated: true)
            } else {
                print("Error: \(error!.localizedDescription)")
            }
        }

        
        
        
        
        
    }}
