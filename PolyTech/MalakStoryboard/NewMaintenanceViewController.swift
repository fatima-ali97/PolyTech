import UIKit
import FirebaseFirestore
import Cloudinary
import AVFoundation

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
    var uploadedVoiceUrl: String?
    var recordedVoiceURL: URL? // Local voice recording

    // UI Elements
    @IBOutlet weak var requestName: UITextField!
    @IBOutlet weak var category: UITextField!
    @IBOutlet weak var location: UITextField!
    @IBOutlet weak var urgency: UITextField!
    @IBOutlet weak var savebtn: UIButton!
    @IBOutlet weak var pageTitle: UILabel!
    @IBOutlet weak var categoryDropDown: UIImageView!
    @IBOutlet weak var urgencyDropDown: UIImageView!
    @IBOutlet weak var uploadImage: UIImageView!
    //@IBOutlet weak var backBtn: UIImageView!
    @IBOutlet weak var recordVoiceButton: UIButton! // Add this button to your storyboard

    // Picker setup
    private let categoryPicker = UIPickerView()
    private let urgencyPicker = UIPickerView()
    private var selectedCategory: MaintenanceCategory?
    private var selectedUrgency: UrgencyLevel?

    // Maintenance categories
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

    // Urgency levels
    enum UrgencyLevel: String, CaseIterable {
        case low, medium, high
        var displayName: String { rawValue.capitalized }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initCloudinary()
        setupPickers()
        setupDropdownTap()
        setupBackBtnButton()
        setupImageTap()
        setupVoiceButton()
        configureEditMode()
        
        // 🔔 Request notification permissions
                PushNotificationManager.shared.requestAuthorization { granted in
                    if granted {
                        print("✅ Notification permissions granted")
                    } else {
                        print("⚠️ Notification permissions not granted")
                    }
                }
    }

    // Initialize Cloudinary
    private func initCloudinary() {
        let config = CLDConfiguration(cloudName: cloudName, secure: true)
        cloudinary = CLDCloudinary(configuration: config)
    }

    // MARK: - Voice Recording Setup
    
    private func setupVoiceButton() {
        // Configure the button appearance
        var config = UIButton.Configuration.filled()
        config.title = recordedVoiceURL == nil ? "Record Voice Note (Optional)" : "Voice Note Recorded ✓"
        config.image = UIImage(systemName: recordedVoiceURL == nil ? "mic.fill" : "checkmark.circle.fill")
        config.imagePlacement = .leading
        config.imagePadding = 8
        config.baseBackgroundColor = recordedVoiceURL == nil ? .systemBlue : .systemGreen
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)
        
        recordVoiceButton.configuration = config
        recordVoiceButton.addTarget(self, action: #selector(recordVoiceButtonTapped), for: .touchUpInside)
    }
    
    @objc private func recordVoiceButtonTapped() {
        // Create and present the voice recording page
        let voiceRecordingVC = VoiceRecordingViewController()
        
        // Set callback to receive the recorded audio
        voiceRecordingVC.onRecordingComplete = { [weak self] audioURL in
            guard let self = self else { return }
            self.recordedVoiceURL = audioURL
            self.updateVoiceButton()
            print("✅ Voice recording received: \(audioURL)")
        }
        
        // Present as modal
        voiceRecordingVC.modalPresentationStyle = .fullScreen
        present(voiceRecordingVC, animated: true)
    }
    
    private func updateVoiceButton() {
        var config = recordVoiceButton.configuration
        if recordedVoiceURL != nil {
            config?.title = "Voice Note Recorded ✓"
            config?.image = UIImage(systemName: "checkmark.circle.fill")
            config?.baseBackgroundColor = .systemGreen
        } else {
            config?.title = "Record Voice Note (Optional)"
            config?.image = UIImage(systemName: "mic.fill")
            config?.baseBackgroundColor = .systemBlue
        }
        recordVoiceButton.configuration = config
    }
    
    // MARK: - Cloudinary Upload for Voice
    
    private func uploadVoiceToCloudinary(completion: @escaping (Bool) -> Void) {
        guard let voiceURL = recordedVoiceURL else {
            completion(true) // No voice recording, continue
            return
        }
        
        // Read the audio file data
        guard let voiceData = try? Data(contentsOf: voiceURL) else {
            showAlert("Failed to read voice recording")
            completion(false)
            return
        }
        
        savebtn.isEnabled = false
        savebtn.setTitle("Uploading voice...", for: .normal)
        
        // Upload parameters for raw audio files
        let params = CLDUploadRequestParams()
        params.setResourceType(.raw) // Use 'raw' for audio files
        
        cloudinary.createUploader().upload(
            data: voiceData,
            uploadPreset: uploadPreset,
            params: params,
            completionHandler: { [weak self] result, error in
                
                guard let self = self else { return }
                
                self.savebtn.isEnabled = true
                self.savebtn.setTitle(self.isEditMode ? "Update" : "Save", for: .normal)
                
                if let error = error {
                    print("❌ Cloudinary voice upload error:", error.localizedDescription)
                    self.showAlert("Failed to upload voice note. Please try again.")
                    completion(false)
                    return
                }
                
                guard let secureUrl = result?.secureUrl else {
                    self.showAlert("Failed to get voice URL from Cloudinary")
                    completion(false)
                    return
                }
                
                print("✅ Voice uploaded to Cloudinary: \(secureUrl)")
                self.uploadedVoiceUrl = secureUrl
                completion(true)
            }
        )
    }

    // Enable tap to upload image
    private func setupImageTap() {
        uploadImage.isUserInteractionEnabled = true
        uploadImage.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(selectImage))
        )
    }

    // Select image from photo library
    @objc private func selectImage() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }

    // Upload image to Cloudinary
    private func uploadImageToCloudinary(imageData: Data, completion: @escaping (Bool) -> Void) {
        savebtn.isEnabled = false
        savebtn.setTitle("Uploading image...", for: .normal)

        cloudinary.createUploader().upload(
            data: imageData,
            uploadPreset: uploadPreset,
            completionHandler: { [weak self] result, error in

                guard let self = self else { return }
                
                self.savebtn.isEnabled = true
                self.savebtn.setTitle(self.isEditMode ? "Update" : "Save", for: .normal)

                if let error = error {
                    print("❌ Cloudinary image upload error:", error.localizedDescription)
                    self.showAlert("Failed to upload image. Please try again.")
                    completion(false)
                    return
                }

                guard let secureUrl = result?.secureUrl else {
                    completion(false)
                    return
                }
                
                print("✅ Image uploaded to Cloudinary: \(secureUrl)")
                self.uploadedImageUrl = secureUrl
                completion(true)
            }
        )
    }

    // Configure edit mode
    private func configureEditMode() {
           if let request = requestToEdit {
               print("✏️ Edit mode activated for request: \(request.requestName)")
               isEditMode = true
               documentId = request.id
               pageTitle.text = "Edit Maintenance Request"
               savebtn.setTitle("Update", for: .normal)
               populateFieldsFromRequest(request)
           } else {
               print("➕ New request mode")
               isEditMode = false
               pageTitle.text = "New Maintenance Request"
               savebtn.setTitle("Save", for: .normal)
           }
       }
    private func populateFieldsFromRequest(_ request: MaintenanceRequestModel) {
           print("📝 Populating fields with request data")
           
           requestName.text = request.requestName
           requestName.isEnabled = false
           requestName.backgroundColor = UIColor.systemGray6
           
           location.text = request.location
           
           // Set category
           if let cat = MaintenanceCategory(rawValue: request.category) {
               selectedCategory = cat
               category.text = cat.displayName
               print("✅ Category set: \(cat.displayName)")
           }
           
           // Set urgency
           if let urg = UrgencyLevel(rawValue: request.urgency.rawValue) {
               selectedUrgency = urg
               urgency.text = urg.displayName
               print("✅ Urgency set: \(urg.displayName)")
           }
           
           // Load image if exists
           if let imageUrl = request.imageUrl {
               uploadedImageUrl = imageUrl
               loadImage(from: imageUrl)
               print("✅ Loading existing image")
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
    // Populate fields for editing
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

        if let imageUrl = data["imageUrl"] as? String {
            uploadedImageUrl = imageUrl
        }
        
        if let voiceUrl = data["voiceUrl"] as? String {
            uploadedVoiceUrl = voiceUrl
            updateVoiceButton()
        }
    }

    @IBAction func Savebtn(_ sender: UIButton) {
        guard
            let requestNameText = requestName.text, !requestNameText.isEmpty,
            let locationText = location.text, !locationText.isEmpty,
            let categoryEnum = selectedCategory,
            let urgencyEnum = selectedUrgency
        else {
            showAlert("Please fill in all required fields")
            return
        }

        // First upload voice if exists
        uploadVoiceToCloudinary { [weak self] success in
            guard let self = self, success else { return }
            
            // Then save to Firestore
            var data: [String: Any] = [
                "requestName": requestNameText,
                "category": categoryEnum.rawValue,
                "location": locationText,
                "urgency": urgencyEnum.rawValue,
                "updatedAt": Timestamp()
            ]

            if let imageUrl = self.uploadedImageUrl {
                data["imageUrl"] = imageUrl
            }
            
            if let voiceUrl = self.uploadedVoiceUrl {
                data["voiceUrl"] = voiceUrl
                print("💾 Saving voiceUrl to Firebase: \(voiceUrl)")
            }

            if self.isEditMode, let documentId = self.documentId {
                self.database.collection("maintenanceRequest")
                    .document(documentId)
                    .updateData(data, completion: handleUpdateResult)
            } else {
                //create new request
                data["createdAt"] = Timestamp()
                data["status"] = "pending"  // 🔔 Add initial status
                
                
                if let userId = UserDefaults.standard.string(forKey: "userId") {
                               data["userId"] = userId
                }
//                self.database.collection("maintenanceRequest")
//                    .addDocument(data: data, completion: self.handleResult)
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
    }
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
        
    private func setupBackBtnButton() {
        //backBtn.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backBtnTapped))
        //backBtn.addGestureRecognizer(tapGesture)
    }
    
    @objc func backBtnTapped() {
        // Clean up voice recording if exists and not uploaded
        if let voiceURL = recordedVoiceURL, uploadedVoiceUrl == nil {
            try? FileManager.default.removeItem(at: voiceURL)
        }
        
        let storyboard = UIStoryboard(name: "HomePage", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "HomeViewController") as? HomeViewController else {
            print("HomeViewController not found in storyboard")
            return
        }
        
        navigationController?.pushViewController(vc, animated: true)
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

        let alert = UIAlertController(
            title: "Success",
            message: "Maintenance request saved successfully",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.navigationController?.popViewController(animated: true)
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
        uploadImageToCloudinary(imageData: data) { _ in }
    }
}
