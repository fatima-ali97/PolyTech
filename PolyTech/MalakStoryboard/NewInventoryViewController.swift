import UIKit
import FirebaseFirestore
import FirebaseAuth

class NewInventoryViewController: UIViewController {
    
    // MARK: - Properties
    var itemToEdit: Inventory?
    var isEditMode = false
    var documentId: String?
    var existingData: [String: Any]?
    
    // MARK: - IBOutlets
    @IBOutlet weak var requestName: UITextField!
    @IBOutlet weak var itemName: UITextField!
    @IBOutlet weak var category: UITextField!
    @IBOutlet weak var quantity: UITextField!
    @IBOutlet weak var location: UITextField!
    @IBOutlet weak var reason: UITextField!
    @IBOutlet weak var savebtn: UIButton!
    @IBOutlet weak var pageTitle: UILabel!
    @IBOutlet weak var categoryDropDown: UIImageView!
    
    let database = Firestore.firestore()
    private var selectedCategory: InventoryCategory?
    private let categoryPicker = UIPickerView()
    
    // MARK: - Enums
    
    enum InventoryCategory: String, CaseIterable {
        case electronics = "electronics"
        case laboratory = "laboratory"
        case classroom = "classroom"
        
        var displayName: String {
            switch self {
            case .electronics: return "Electronics"
            case .laboratory: return "Laboratory"
            case .classroom: return "Classroom"
            }
        }
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPickers()
        setupDropdownTap()
        setupQuantityField()
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
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = nil
        
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
    
    private func setupQuantityField() {
        quantity.delegate = self
        quantity.keyboardType = .numberPad
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))
        
        toolbar.items = [flexSpace, doneButton]
        quantity.inputAccessoryView = toolbar
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func configureEditMode() {
        if let item = itemToEdit {
            isEditMode = true
            documentId = item.id
            pageTitle.text = "Edit Inventory Request"
            savebtn.setTitle("Update", for: .normal)
            populateFieldsFromItem(item)
        } else {
            isEditMode = false
            pageTitle.text = "New Inventory Request"
            savebtn.setTitle("Save", for: .normal)
        }
    }
    
    private func populateFieldsFromItem(_ item: Inventory) {
        requestName.text = item.requestName
        requestName.isEnabled = false
        
        itemName.text = item.itemName
        itemName.isEnabled = false
        
        quantity.text = "\(item.quantity)"
        location.text = item.location
        reason.text = item.reason
        
        if let cat = InventoryCategory(rawValue: item.category) {
            selectedCategory = cat
            category.text = cat.displayName
        }
    }
    
    private func setupPickers() {
        categoryPicker.delegate = self
        categoryPicker.dataSource = self
        category.inputView = categoryPicker
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [flexSpace, doneButton]
        category.inputAccessoryView = toolbar
    }
    
    private func setupDropdownTap() {
        categoryDropDown.isUserInteractionEnabled = true
        categoryDropDown.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(openCategoryPicker))
        )
    }
    
    @objc private func openCategoryPicker() {
        category.becomeFirstResponder()
    }
    
    // MARK: - Save Action
    
    @IBAction func saveBtn(_ sender: UIButton) {
        resetFieldBorders()
        
        guard validateFields() else { return }
        
        let data: [String: Any] = [
            "requestName": requestName.text!.trimmingCharacters(in: .whitespacesAndNewlines),
            "itemName": itemName.text!.trimmingCharacters(in: .whitespacesAndNewlines),
            "category": selectedCategory!.rawValue,
            "quantity": Int(quantity.text!)!,
            "location": location.text!.trimmingCharacters(in: .whitespacesAndNewlines),
            "reason": reason.text!.trimmingCharacters(in: .whitespacesAndNewlines),
            "updatedAt": Timestamp()
        ]
        
        if isEditMode, let documentId = documentId {
            // UPDATE existing request (no push notification)
            updateRequest(documentId: documentId, data: data)
        } else {
            // CREATE new request (with push notification)
            newRequest(data: data)
        }
    }
    
    // MARK: - Validation
    
    private func validateFields() -> Bool {
        let fieldsToCheck: [(UITextField?, String)] = [
            (requestName, "Please enter the request name"),
            (itemName, "Please enter the item name"),
            (quantity, "Please enter a valid quantity"),
            (location, "Please enter the location"),
            (reason, "Please enter a reason"),
            (category, "Please select a category")
        ]
        
        for (field, message) in fieldsToCheck {
            if field == category && selectedCategory == nil {
                markFieldAsInvalid(category)
                showAlert(message)
                return false
            }
            
            if let textField = field,
               textField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
                markFieldAsInvalid(textField)
                showAlert(message)
                return false
            }
            
            if field == quantity,
               let text = quantity.text,
               (Int(text) ?? 0) <= 0 {
                markFieldAsInvalid(quantity)
                showAlert("Please enter a quantity greater than 0")
                return false
            }
        }
        
        return true
    }
    
    private func markFieldAsInvalid(_ textField: UITextField) {
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.red.cgColor
        textField.layer.cornerRadius = 5
    }
    
    private func resetFieldBorders() {
        let fields: [UITextField?] = [requestName, itemName, category, quantity, location, reason]
        for field in fields {
            field?.layer.borderWidth = 0
        }
    }
    
    // MARK: - Database Operations
    
    func newRequest(data: [String: Any]) {
        var newData = data
        newData["createdAt"] = Timestamp()
        newData["status"] = "pending"  // 🔔 Add initial status
        
        // Add the current user's ID
        if let userId = Auth.auth().currentUser?.uid {
            newData["userId"] = userId
        }
        
        let requestNameText = requestName.text ?? "Inventory Item"
        let locationText = location.text ?? ""
        
        // Save to Firestore
        database.collection("inventoryRequest").addDocument(data: newData) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                self.showAlert("Error: \(error.localizedDescription)")
                return
            }
            
            print("✅ Inventory request saved to Firestore")
            
            // 🔔 Create notification and schedule push notification
            PushNotificationManager.shared.createNotificationForRequest(
                requestType: "Inventory",
                requestName: requestNameText,
                status: "submitted",
                location: locationText
            ) { success in
                if success {
                    print("✅ Push notification scheduled successfully")
                    
                    // Show in-app notification banner
                    NotificationManager.shared.showSuccess(
                        title: "Request Submitted ✓",
                        message: "Your inventory request has been submitted successfully."
                    )
                } else {
                    print("⚠️ Failed to schedule push notification")
                }
                
                // Show success alert and navigate back
                let alert = UIAlertController(
                    title: "Success",
                    message: "Inventory request created successfully ✅\n\nYou will receive a notification shortly.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                    self.navigationController?.popViewController(animated: true)
                })
                self.present(alert, animated: true)
            }
        }
    }
    
    func updateRequest(documentId: String, data: [String: Any]) {
        database.collection("inventoryRequest")
            .document(documentId)
            .updateData(data) { [weak self] error in
                self?.handleUpdateResult(error: error)
            }
    }
    
    // MARK: - Result Handlers
    
    private func handleUpdateResult(error: Error?) {
        if let error = error {
            showAlert("Error: \(error.localizedDescription)")
        } else {
            let alert = UIAlertController(
                title: "Success",
                message: "Inventory request updated successfully ✅",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                self.navigationController?.popViewController(animated: true)
            })
            present(alert, animated: true)
        }
    }
    
    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIPickerView Delegate & DataSource

extension NewInventoryViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return InventoryCategory.allCases.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return InventoryCategory.allCases[row].displayName
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let cat = InventoryCategory.allCases[row]
        selectedCategory = cat
        category.text = cat.displayName
        category.resignFirstResponder()
    }
}

// MARK: - UITextField Delegate

extension NewInventoryViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == quantity {
            // Allow only numeric characters
            let allowedCharacters = CharacterSet.decimalDigits
            let characterSet = CharacterSet(charactersIn: string)
            return allowedCharacters.isSuperset(of: characterSet)
        }
        return true
    }
}
