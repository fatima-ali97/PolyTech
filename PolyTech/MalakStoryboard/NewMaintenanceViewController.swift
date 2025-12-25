//import UIKit
//import FirebaseFirestore
//
//
//
//class NewMaintenanceViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
//    
//    var isEditMode = false
//    var documentId: String?
//    var existingData: [String: Any]?
//    
//    @IBOutlet weak var requestName: UITextField!
//    @IBOutlet weak var category: UITextField!
//    @IBOutlet weak var location: UITextField!
//    @IBOutlet weak var urgency: UITextField!
//    @IBOutlet weak var imageUpload: UITextField!
//    @IBOutlet weak var Backbtn: UIImageView!
//    @IBOutlet weak var savebtn: UIButton!
//    @IBOutlet weak var pageTitle: UILabel!
//    @IBOutlet weak var categoryDropDown: UIImageView!
//    @IBOutlet weak var urgencyDropDown: UIImageView!
//    
//    let database = Firestore.firestore()
//  
//    
//    private let categoryPicker = UIPickerView()
//    private let urgencyPicker = UIPickerView()
//    private var selectedCategory: MaintenanceCategory?
//    private var selectedUrgency: UrgencyLevel?
//    private var selectedImage: UIImage?
//    
//    enum MaintenanceCategory: String, CaseIterable {
//        case osUpdate = "os_update"
//        case classroomEquipment = "classroom_equipment"
//        case softwareIssue = "software_issue"
//        case airConditioner = "air_conditioner"
//        case pcHardware = "pc_hardware"
//        case serverDowntime = "server_downtime"
//        
//        var displayName: String {
//            switch self {
//            case .osUpdate: return "OS Update"
//            case .classroomEquipment: return "Classroom Equipment"
//            case .softwareIssue: return "Software Issue"
//            case .airConditioner: return "Air Conditioner"
//            case .pcHardware: return "PC Hardware"
//            case .serverDowntime: return "Server Downtime"
//            }
//        }
//    }
//    
//    enum UrgencyLevel: String, CaseIterable {
//        case low
//        case medium
//        case high
//        
//        var displayName: String {
//            rawValue.capitalized
//        }
//    }
//    
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        setupBackBtn()
//        setupPickers()
//        setupDropdownTap()
//        setupImagePicker()
//        
//        if isEditMode {
//            pageTitle.text = "Edit Maintenance Request"
//            savebtn.setTitle("Edit", for: .normal)
//            showFields()
//        } else {
//            pageTitle.text = "New Maintenance Request"
//            savebtn.setTitle("Save", for: .normal)
//        }
//    }
//    
//    private func setupBackBtn() {
//        Backbtn.isUserInteractionEnabled = true
//        Backbtn.addGestureRecognizer(
//            UITapGestureRecognizer(target: self, action: #selector(backTapped))
//        )
//    }
//    
//    private func setupPickers() {
//        categoryPicker.delegate = self
//        categoryPicker.dataSource = self
//        categoryPicker.tag = 1
//        category.inputView = categoryPicker
//        
//        urgencyPicker.delegate = self
//        urgencyPicker.dataSource = self
//        urgencyPicker.tag = 2
//        urgency.inputView = urgencyPicker
//    }
//    
//    private func setupDropdownTap() {
//        categoryDropDown.isUserInteractionEnabled = true
//        urgencyDropDown.isUserInteractionEnabled = true
//        
//        categoryDropDown.addGestureRecognizer(
//            UITapGestureRecognizer(target: self, action: #selector(openCategoryPicker))
//        )
//        
//        urgencyDropDown.addGestureRecognizer(
//            UITapGestureRecognizer(target: self, action: #selector(openUrgencyPicker))
//        )
//    }
//    
//    private func showFields() {
//        guard let data = existingData else { return }
//        
//        requestName.text = data["requestName"] as? String
//        location.text = data["location"] as? String
//        requestName.isEnabled = false
//        
//        if let categoryRaw = data["category"] as? String,
//           let cat = MaintenanceCategory(rawValue: categoryRaw) {
//            selectedCategory = cat
//            category.text = cat.displayName
//        }
//        
//        if let urgencyRaw = data["urgency"] as? String,
//           let urg = UrgencyLevel(rawValue: urgencyRaw) {
//            selectedUrgency = urg
//            urgency.text = urg.displayName
//        }
//        
//        if data["imageUrl"] != nil {
//            imageUpload.text = "Image uploaded successfully"
//        }
//    }
//    
//    private func setupImagePicker() {
//        imageUpload.isUserInteractionEnabled = true
//        imageUpload.placeholder = "Upload Image"
//        
//        let tap = UITapGestureRecognizer(target: self, action: #selector(openImagePicker))
//        imageUpload.addGestureRecognizer(tap)
//    }
//    
//    @objc func backTapped() {
//        navigationController?.popViewController(animated: true)
//    }
//    
//    @objc private func openCategoryPicker() {
//        category.becomeFirstResponder()
//    }
//    
//    @objc private func openUrgencyPicker() {
//        urgency.becomeFirstResponder()
//    }
//    
//    @objc private func openImagePicker() {
//        let picker = UIImagePickerController()
//        picker.delegate = self
//        picker.sourceType = .photoLibrary
//        picker.allowsEditing = true
//        present(picker, animated: true)
//    }
//    
//    func imagePickerController(_ picker: UIImagePickerController,
//                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//        
//        if let image = info[.editedImage] as? UIImage ??
//            info[.originalImage] as? UIImage {
//            selectedImage = image
//            imageUpload.text = "Image Has Been Selected"
//        }
//        picker.dismiss(animated: true)
//    }
//    
//    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//        picker.dismiss(animated: true)
//    }
//    
//    
//    @IBAction func Savebtn(_ sender: UIButton) {
//        guard
//            let requestNameText = requestName.text, !requestNameText.isEmpty,
//            let locationText = location.text, !locationText.isEmpty,
//            let categoryEnum = selectedCategory,
//            let urgencyEnum = selectedUrgency
//        else {
//            showAlert("Please fill in all fields")
//            return
//        }
//        
//        uploadImage { [weak self] imageUrl in
//            guard let self = self else { return }
//            
//            var data: [String: Any] = [
//                "requestName": requestNameText,
//                "category": categoryEnum.rawValue,
//                "location": locationText,
//                "urgency": urgencyEnum.rawValue,
//                "updatedAt": Timestamp()
//            ]
//            
//            if let imageUrl = imageUrl {
//                data["imageUrl"] = imageUrl
//            }
//            
//            if isEditMode, let documentId = documentId {
//                database.collection("maintenanceRequest")
//                    .document(documentId)
//                    .updateData(data) { [weak self] error in
//                        self?.handleResult(error: error, successMessage: "Maintenance request updated successfully")
//                    }
//            } else {
//                var newData = data
//                newData["createdAt"] = Timestamp()
//                database.collection("maintenanceRequest").addDocument(data: newData) { [weak self] error in
//                    self?.handleResult(error: error, successMessage: "Maintenance request saved successfully")
//                }
//            }
//        }
//        
//        
//        
//        
//    }
//    
//    func uploadImage(completion: @escaping (String?) -> Void) {
//        
//        guard let image = selectedImage,
//              let imageData = image.jpegData(compressionQuality: 0.7) else {
//            completion(nil)
//            return
//        }
//        
//        let imageId = UUID().uuidString
//        //let ref = storage.reference()
//         //   .child("maintenance_images/\(imageId).jpg")
//        
//       // ref.putData(imageData, metadata: nil) { _, error in
//          //  if error != nil {
//            //   completion(nil)
//             // return
//            //}
//            
//          //  ref.downloadURL { url, _ in
//           //     completion(url?.absoluteString)
//          //  }
//        }
//    }
//    
//    
//    func handleResult(error: Error?, successMessage: String) {
//        if let error = error {
//            let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: "OK", style: .default))
//            present(alert, animated: true)
//        } else {
//            let alert = UIAlertController(title: "Success", message: successMessage, preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
//                self.navigationController?.popViewController(animated: true)
//            })
//            present(alert, animated: true)
//        }
//    }
//    
//    func showAlert(_ message: String) {
//        let alert = UIAlertController(
//            title: "Error",
//            message: message,
//            preferredStyle: .alert
//        )
//        alert.addAction(UIAlertAction(title: "OK", style: .default))
//        present(alert, animated: true)
//    }
//    
//    
//}
//
//extension NewMaintenanceViewController: UIPickerViewDelegate, UIPickerViewDataSource {
//    
//    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
//    
//    func pickerView(_ pickerView: UIPickerView,
//                    numberOfRowsInComponent component: Int) -> Int {
//        pickerView.tag == 1
//        ? MaintenanceCategory.allCases.count
//        : UrgencyLevel.allCases.count
//    }
//    
//    func pickerView(_ pickerView: UIPickerView,
//                    titleForRow row: Int,
//                    forComponent component: Int) -> String? {
//        pickerView.tag == 1
//        ? MaintenanceCategory.allCases[row].displayName
//        : UrgencyLevel.allCases[row].displayName
//    }
//    
//    func pickerView(_ pickerView: UIPickerView,
//                    didSelectRow row: Int,
//                    inComponent component: Int) {
//        
//        if pickerView.tag == 1 {
//            let cat = MaintenanceCategory.allCases[row]
//            selectedCategory = cat
//            category.text = cat.displayName
//        } else {
//            let urg = UrgencyLevel.allCases[row]
//            selectedUrgency = urg
//            urgency.text = urg.displayName
//        }
//    }
//}
