import UIKit
import FirebaseFirestore
import Cloudinary

class NewMaintenanceViewController: UIViewController {
    
   
    let cloudName: String =  "dwvlnmbtv"

    var cloudinary: CLDCloudinary!
    
    var isEditMode = false
    var documentId: String?
    var existingData: [String: Any]?

    @IBOutlet weak var requestName: UITextField!
    @IBOutlet weak var category: UITextField!
    @IBOutlet weak var location: UITextField!
    @IBOutlet weak var urgency: UITextField!
    @IBOutlet weak var savebtn: UIButton!
    @IBOutlet weak var pageTitle: UILabel!
    @IBOutlet weak var categoryDropDown: UIImageView!
    @IBOutlet weak var urgencyDropDown: UIImageView!
    @IBOutlet weak var Backbtn: UIImageView!
    @IBOutlet weak var uploadImage: UIImageView!
    
    let database = Firestore.firestore()

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
        setupBackBtn()
        setupPickers()
        initCloudinary()
        setupDropdownTap()
        configureEditMode()
        //uploadImage()
    }
    
    
    private func initCloudinary() {
            let config = CLDConfiguration(cloudName: cloudName, secure: true)
            cloudinary = CLDCloudinary(configuration: config)
        }

    private func configureEditMode() {
        if isEditMode {
            pageTitle.text = "Edit Maintenance Request"
            savebtn.setTitle("Edit", for: .normal)
            populateFields()
        } else {
            pageTitle.text = "New Maintenance Request"
            savebtn.setTitle("Save", for: .normal)
        }
    }

    private func populateFields() {
        guard let data = existingData else { return }

        requestName.text = data["requestName"] as? String
        requestName.isEnabled = false
        location.text = data["location"] as? String

        if let categoryRaw = data["category"] as? String,
           let cat = MaintenanceCategory(rawValue: categoryRaw) {
            selectedCategory = cat
            category.text = cat.displayName
        }

        if let urgencyRaw = data["urgency"] as? String,
           let urg = UrgencyLevel(rawValue: urgencyRaw) {
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

        if isEditMode, let documentId = documentId {
            database.collection("maintenanceRequest")
                .document(documentId)
                .updateData(data) { [weak self] error in
                    self?.handleResult(error: error,
                                       successMessage: "Maintenance request updated successfully")
                }
        } else {
            data["createdAt"] = Timestamp()
            database.collection("maintenanceRequest")
                .addDocument(data: data) { [weak self] error in
                    self?.handleResult(error: error,
                                       successMessage: "Maintenance request saved successfully")
                }
        }
    }


    private func setupBackBtn() {

        Backbtn.isUserInteractionEnabled = true

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backBtnTapped))
        Backbtn.addGestureRecognizer(tapGesture)
    }
    
    @objc func backBtnTapped() {

        let storyboard = UIStoryboard(name: "Maintenance", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "MaintenanceViewController") as? MaintenanceViewController else {
            print("MaintenanceViewController not found in storyboard")
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
            UITapGestureRecognizer(target: self,
                                   action: #selector(openCategoryPicker))
        )

        urgencyDropDown.addGestureRecognizer(
            UITapGestureRecognizer(target: self,
                                   action: #selector(openUrgencyPicker))
        )
    }

    @objc private func openCategoryPicker() {
        category.becomeFirstResponder()
    }

    @objc private func openUrgencyPicker() {
        urgency.becomeFirstResponder()
    }

    //NEW - Upload function
        private func uploadImage() {
            guard let data = UIImage(named: "cloudinary_logo")?.pngData() else {
                return
            }
            cloudinary.createUploader().upload(data: data, uploadPreset: uploadPreset) { response, error in
                DispatchQueue.main.async {
                    guard let url = response?.secureUrl else {
                        return
                    }
                    self.ivUploadedImage.cldSetImage(url, cloudinary: self.cloudinary)
                }
            }
        }
    private func handleResult(error: Error?, successMessage: String) {
        if let error = error {
            showAlert(error.localizedDescription)
        } else {
        let alert = UIAlertController(title: "Success",
                                          message: successMessage,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                self.navigationController?.popViewController(animated: true)
            })
            present(alert, animated: true)
        }
    }

    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Error",
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension NewMaintenanceViewController: UIPickerViewDelegate, UIPickerViewDataSource {

    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }

    func pickerView(_ pickerView: UIPickerView,
                    numberOfRowsInComponent component: Int) -> Int {
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
}
