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
        // ✅ REMOVED: No toolbar/done button for quantity field
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
            // UPDATE existing request (no stock change, no push notification)
            updateRequest(documentId: documentId, data: data)
        } else {
            // CREATE new request (decrease stock and send push notification)
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
        // Show loading indicator
        let loadingAlert = UIAlertController(title: nil, message: "Creating request...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()
        loadingAlert.view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: loadingAlert.view.centerXAnchor),
            loadingIndicator.bottomAnchor.constraint(equalTo: loadingAlert.view.bottomAnchor, constant: -20)
        ])
        present(loadingAlert, animated: true)

        var newData = data
        newData["createdAt"] = Timestamp()
        newData["status"] = "pending"

        if let userId = Auth.auth().currentUser?.uid {
            newData["userId"] = userId
        }

        let collectionRef = database.collection("inventoryRequest")
        let docRef = collectionRef.document()
        let requestId = docRef.documentID
        
        let itemNameText = newData["itemName"] as! String
        let requestQuantity = newData["quantity"] as! Int

        // ✅ Step 1: Write the request to Firestore
        docRef.setData(newData) { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                loadingAlert.dismiss(animated: true) {
                    self.showAlert("Error saving request: \(error.localizedDescription)")
                }
                return
            }

            print("✅ Inventory request saved to Firestore")

            // ✅ Step 2: Decrease inventory stock
            self.decreaseInventoryStock(itemName: itemNameText, requestQuantity: requestQuantity) { success in
                
                if !success {
                    print("⚠️ Stock decrease failed, but request was saved")
                }

                // 🤖 Step 3: Auto-assign technician
                AutoAssignmentService.shared.autoAssignTechnician(
                    requestId: requestId,
                    requestType: "inventory",
                    category: self.selectedCategory?.rawValue ?? "general",
                    location: self.location.text ?? "",
                    urgency: "normal"
                ) { success, errorMessage in
                    if !success {
                        print("⚠️ Auto-assign failed: \(errorMessage ?? "unknown error")")
                    }
                }

                // 🔔 Step 4: Push notification
                PushNotificationManager.shared.createNotificationForRequest(
                    requestType: "Inventory",
                    requestName: self.requestName.text ?? "",
                    status: "submitted",
                    location: self.location.text ?? ""
                ) { _ in
                    loadingAlert.dismiss(animated: true) {
                        self.showSuccessAndPop(message: success ? "Request created and stock updated ✅" : "Request created but stock update failed ⚠️")
                    }
                }
            }
        }
    }
    
    // MARK: - Stock Management
    
    private func decreaseInventoryStock(itemName: String, requestQuantity: Int, completion: @escaping (Bool) -> Void) {
        // Query inventory stock
        database.collection("inventoryStock")
            .whereField("itemName", isEqualTo: itemName)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else {
                    completion(false)
                    return
                }
                
                if let error = error {
                    print("❌ Error querying inventory stock: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                if let documents = snapshot?.documents, !documents.isEmpty {
                    // Item exists in stock, decrease it
                    let document = documents[0]
                    let stockDocumentId = document.documentID
                    let currentStock = document.data()["quantity"] as? Int ?? 0
                    
                    if currentStock < requestQuantity {
                        print("⚠️ Insufficient stock: current=\(currentStock), requested=\(requestQuantity)")
                        // Still allow the request but log warning
                    }
                    
                    let newStock = max(0, currentStock - requestQuantity) // Don't go below 0
                    
                    self.database.collection("inventoryStock")
                        .document(stockDocumentId)
                        .updateData(["quantity": newStock]) { error in
                            if let error = error {
                                print("❌ Error updating stock: \(error.localizedDescription)")
                                completion(false)
                            } else {
                                print("✅ Stock decreased: \(currentStock) -> \(newStock)")
                                completion(true)
                            }
                        }
                } else {
                    // Item doesn't exist in stock - create with negative quantity or just warn
                    print("⚠️ Item '\(itemName)' not found in stock. Cannot decrease.")
                    completion(false)
                }
            }
    }

    private func showSuccessAndPop(message: String = "Request Saved") {
        let alert = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.navigationController?.popViewController(animated: true)
        })
        self.present(alert, animated: true)
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
