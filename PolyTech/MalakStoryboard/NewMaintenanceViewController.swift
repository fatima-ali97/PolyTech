import UIKit
import FirebaseFirestore
import FirebaseAuth
import Cloudinary

class NewMaintenanceViewController: UIViewController {
    
    // MARK: - Properties
    var requestToEdit: MaintenanceRequestModel?
    var item: MaintenanceRequestModel?
    
    // Cloudinary setup
    let cloudName: String = "dwvlnmbtv"
    let uploadPreset = "Polytech_Cloudinary"
    var cloudinary: CLDCloudinary!
    
    // Firestore database connection
    let database = Firestore.firestore()
    
    // Edit mode management
    var isEditMode = false
    var documentId: String?
    var existingData: [String: Any]?
    var uploadedImageUrl: String?
    
    // MARK: - IBOutlets
    @IBOutlet weak var requestName: UITextField!
    @IBOutlet weak var category: UITextField!
    @IBOutlet weak var location: UITextField!
    @IBOutlet weak var urgency: UITextField!
    @IBOutlet weak var savebtn: UIButton!
    @IBOutlet weak var pageTitle: UILabel!
    @IBOutlet weak var categoryDropDown: UIImageView!
    @IBOutlet weak var urgencyDropDown: UIImageView!
    @IBOutlet weak var uploadImage: UIImageView!
    
    // Picker setup
    private let categoryPicker = UIPickerView()
    private let urgencyPicker = UIPickerView()
    private var selectedCategory: MaintenanceCategory?
    private var selectedUrgency: UrgencyLevel?
    
    // MARK: - Enums
    
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
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initCloudinary()
        setupPickers()
        setupDropdownTap()
        setupImageTap()
        configureEditMode()
        setupNavigationBackButton()
        
        // 🔔 Request notification permissions
        PushNotificationManager.shared.requestAuthorization { granted in
            if granted {
                print("✅ Notification permissions granted")
            } else {
                print("⚠️ Notification permissions not granted")
            }
        }
    }
    
    // MARK: - Setup Methods
    
    private func setupNavigationBackButton() {
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(goBack)
        )
        backButton.tintColor = .background
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
                    print("❌ Cloudinary error:", error.localizedDescription)
                    return
                }
                
                guard let secureUrl = result?.secureUrl else { return }
                self?.uploadedImageUrl = secureUrl
                print("✅ Image uploaded to Cloudinary: \(secureUrl)")
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
    
    // MARK: - Save Action
    
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
            // UPDATE existing request
            database.collection("maintenanceRequest")
                .document(documentId)
                .updateData(data, completion: handleUpdateResult)
        } else {
            // CREATE new request
            data["createdAt"] = Timestamp()
            data["status"] = "pending"  // 🔔 Add initial status
            
            if let userId = UserDefaults.standard.string(forKey: "userId") {
                data["userId"] = userId
            }
            
            // 🔔 Save to Firestore and send push notification
            database.collection("maintenanceRequest")
                .addDocument(data: data) { [weak self] error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        self.showAlert(error.localizedDescription)
                        return
                    }
                    
                    print("✅ Maintenance request saved to Firestore")
                    
                    // 🔔 Create notification and schedule push notification
                    PushNotificationManager.shared.createNotificationForRequest(
                        requestType: "Maintenance",
                        requestName: requestNameText,
                        status: "submitted",
                        location: locationText
                    ) { success in
                        if success {
                            print("✅ Push notification scheduled successfully")
                            
                            // Show in-app notification banner
                            NotificationManager.shared.showSuccess(
                                title: "Request Submitted ✓",
                                message: "Your maintenance request has been submitted successfully."
                            )
                        } else {
                            print("⚠️ Failed to schedule push notification")
                        }
                        
                        // Show success alert and navigate back
                        let alert = UIAlertController(
                            title: "Success",
                            message: "Maintenance request created successfully ✅\n\nYou will receive a notification shortly.",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                            if self.presentingViewController != nil {
                                self.dismiss(animated: true)
                            } else {
                                self.navigationController?.popViewController(animated: true)
                            }
                        })
                        self.present(alert, animated: true)
                    }
                }
        }
    }
    
    // MARK: - Result Handlers
    
    private func handleUpdateResult(_ error: Error?) {
        if let error = error {
            showAlert(error.localizedDescription)
            return
        }
        
        let alert = UIAlertController(
            title: "Success",
            message: "Maintenance request updated successfully ✅",
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

// MARK: - UIPickerView Delegate & DataSource

extension NewMaintenanceViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerView.tag == 1
            ? MaintenanceCategory.allCases.count
            : UrgencyLevel.allCases.count
    }
    
    func pickerView(_ pickerView: UIPickerView,
                    titleForRow row: Int,
                    forComponent component: Int) -> String? {
        return pickerView.tag == 1
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
}

// MARK: - UIImagePickerController Delegate

extension NewMaintenanceViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true)
        
        guard let image = info[.originalImage] as? UIImage,
              let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        uploadImage.image = image
        uploadToCloudinary(imageData: data)
    }
}
