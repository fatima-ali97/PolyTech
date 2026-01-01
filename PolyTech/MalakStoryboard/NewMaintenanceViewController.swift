import UIKit
import FirebaseFirestore
import Cloudinary

class NewMaintenanceViewController: UIViewController {
    var requestToEdit: MaintenanceRequestModel?
    var item: MaintenanceRequestModel?
    
 
    let cloudName: String = "dwvlnmbtv"
    let uploadPreset = "Polytech_Cloudinary"
    var cloudinary: CLDCloudinary!

 
    let database = Firestore.firestore()


    var isEditMode = false
    var documentId: String?
    var existingData: [String: Any]?
    var uploadedImageUrl: String?


    @IBOutlet weak var requestName: UITextField!
    @IBOutlet weak var category: UITextField!
    @IBOutlet weak var location: UITextField!
    @IBOutlet weak var urgency: UITextField!
    @IBOutlet weak var savebtn: UIButton!
    @IBOutlet weak var pageTitle: UILabel!
    @IBOutlet weak var categoryDropDown: UIImageView!
    @IBOutlet weak var urgencyDropDown: UIImageView!
    @IBOutlet weak var uploadImage: UIImageView!


    private let categoryPicker = UIPickerView()
    private let urgencyPicker = UIPickerView()
    private var selectedCategory: MaintenanceCategory?
    private var selectedUrgency: UrgencyLevel?

 
    enum MaintenanceCategory: String, CaseIterable {
        case osUpdate = "os_update"
        case classroomEquipment = "classroom_equipment"
        case softwareIssue = "software_issue"
        case airConditioner = "air_conditioner"
        case pcHardware = "pc_hardware"
        case serverDowntime = "server_downtime"

        var displayName: String {
            switch self {
            case .osUpdate: return "OS Update"
            case .classroomEquipment: return "Classroom Equipment"
            case .softwareIssue: return "Software Issue"
            case .airConditioner: return "Air Conditioner"
            case .pcHardware: return "PC Hardware"
            case .serverDowntime: return "Server Downtime"
            }
        }
    }


    enum UrgencyLevel: String, CaseIterable {
        case low, medium, high
        var displayName: String { rawValue.capitalized }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        initCloudinary()
        setupPickers()
        setupDropdownTap()
        setupImageTap()
        configureEditMode()

 
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(goBack)
        )
        backButton.tintColor = .background   // change color if needed
        navigationItem.leftBarButtonItem = backButton
    }

    @objc private func goBack() {
        navigationController?.popViewController(animated: true)
    }

    private func initCloudinary() {
        let config = CLDConfiguration(cloudName: cloudName, secure: true)
        cloudinary = CLDCloudinary(configuration: config)
    }

    private func setupImageTap() {
        uploadImage.isUserInteractionEnabled = true
        uploadImage.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(selectImage))
        )
    }

    @objc private func selectImage() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }


    private func uploadToCloudinary(imageData: Data) {
        savebtn.isEnabled = false

        cloudinary.createUploader().upload(
            data: imageData,
            uploadPreset: uploadPreset,
            completionHandler: { [weak self] result, error in

                self?.savebtn.isEnabled = true

                if let error = error {
                    print("Cloudinary error:", error.localizedDescription)
                    return
                }

                guard let secureUrl = result?.secureUrl else { return }
                self?.uploadedImageUrl = secureUrl
            }
        )
    }

    private func configureEditMode() {

        if let request = requestToEdit {
            isEditMode = true
            documentId = request.id
            pageTitle.text = "Edit Maintenance Request"
            savebtn.setTitle("Update", for: .normal)
            populateFieldsFromRequest(request)
        } else {
            isEditMode = false
            pageTitle.text = "New Maintenance Request"
            savebtn.setTitle("Save", for: .normal)
        }
    }

    private func populateFieldsFromRequest(_ request: MaintenanceRequestModel) {
        requestName.text = request.requestName
        requestName.isEnabled = false
        
        location.text = request.location

        if let cat = MaintenanceCategory(rawValue: request.category) {
            selectedCategory = cat
            category.text = cat.displayName
        }
        
 
        if let urg = UrgencyLevel(rawValue: request.urgency.rawValue) {
            selectedUrgency = urg
            urgency.text = urg.displayName
        }

        if let imageUrl = request.imageUrl {
            uploadedImageUrl = imageUrl

            loadImage(from: imageUrl)
        }
    }

    private func loadImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let data = data, error == nil,
                  let image = UIImage(data: data) else { return }
            
            DispatchQueue.main.async {
                self?.uploadImage.image = image
            }
        }.resume()
    }

    private func populateFields() {
        guard let data = existingData else { return }

        requestName.text = data["requestName"] as? String
        location.text = data["location"] as? String

        if let raw = data["category"] as? String,
           let cat = MaintenanceCategory(rawValue: raw) {
            selectedCategory = cat
            category.text = cat.displayName
        }

        if let raw = data["urgency"] as? String,
           let urg = UrgencyLevel(rawValue: raw) {
            selectedUrgency = urg
            urgency.text = urg.displayName
        }
    }

    @IBAction func Savebtn(_ sender: UIButton) {
        guard
            let requestNameText = requestName.text, !requestNameText.isEmpty,
            let locationText = location.text, !locationText.isEmpty,
            let categoryEnum = selectedCategory,
            let urgencyEnum = selectedUrgency
        else {
            showAlert("Please fill in all fields")
            return
        }

        var data: [String: Any] = [
            "requestName": requestNameText,
            "category": categoryEnum.rawValue,
            "location": locationText,
            "urgency": urgencyEnum.rawValue,
            "updatedAt": Timestamp()
        ]

        if let imageUrl = uploadedImageUrl {
            data["imageUrl"] = imageUrl
        }

        if isEditMode, let documentId = documentId {
            database.collection("maintenanceRequest")
                .document(documentId)
                .updateData(data, completion: handleResult)
        } else {
            data["createdAt"] = Timestamp()

            if let userId = UserDefaults.standard.string(forKey: "userId") {
                data["userId"] = userId
            }
            database.collection("maintenanceRequest")
                .addDocument(data: data, completion: handleResult)
        }
    }

    private func setupPickers() {
        categoryPicker.delegate = self
        categoryPicker.dataSource = self
        categoryPicker.tag = 1
        category.inputView = categoryPicker

        urgencyPicker.delegate = self
        urgencyPicker.dataSource = self
        urgencyPicker.tag = 2
        urgency.inputView = urgencyPicker
    }

    private func setupDropdownTap() {
        categoryDropDown.isUserInteractionEnabled = true
        urgencyDropDown.isUserInteractionEnabled = true

        categoryDropDown.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(openCategoryPicker))
        )

        urgencyDropDown.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(openUrgencyPicker))
        )
    }

    @objc private func openCategoryPicker() {
        category.becomeFirstResponder()
    }

    @objc private func openUrgencyPicker() {
        urgency.becomeFirstResponder()
    }

    private func handleResult(_ error: Error?) {
        if let error = error {
            showAlert(error.localizedDescription)
            return
        }

        let successMessage = isEditMode
            ? "Maintenance request updated successfully ✅"
            : "Maintenance request created successfully ✅"
        
        let alert = UIAlertController(
            title: "Success",
            message: successMessage,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
 
            if self.presentingViewController != nil {
                self.dismiss(animated: true)
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        })

        present(alert, animated: true)
    }

    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension NewMaintenanceViewController:
    UIPickerViewDelegate,
    UIPickerViewDataSource,
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate {

    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        pickerView.tag == 1
            ? MaintenanceCategory.allCases.count
            : UrgencyLevel.allCases.count
    }

    func pickerView(_ pickerView: UIPickerView,
                    titleForRow row: Int,
                    forComponent component: Int) -> String? {
        pickerView.tag == 1
            ? MaintenanceCategory.allCases[row].displayName
            : UrgencyLevel.allCases[row].displayName
    }

    func pickerView(_ pickerView: UIPickerView,
                    didSelectRow row: Int,
                    inComponent component: Int) {
        if pickerView.tag == 1 {
            let cat = MaintenanceCategory.allCases[row]
            selectedCategory = cat
            category.text = cat.displayName
        } else {
            let urg = UrgencyLevel.allCases[row]
            selectedUrgency = urg
            urgency.text = urg.displayName
        }
    }

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        picker.dismiss(animated: true)

        guard let image = info[.originalImage] as? UIImage,
              let data = image.jpegData(compressionQuality: 0.8) else { return }

        uploadImage.image = image
        uploadToCloudinary(imageData: data)
    }
}
