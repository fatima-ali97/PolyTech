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
    @IBOutlet weak var itemName: UITextField!
    @IBOutlet weak var category: UITextField!
    @IBOutlet weak var quantity: UITextField!
    @IBOutlet weak var location: UITextField!
    @IBOutlet weak var reason: UITextField!
    @IBOutlet weak var savebtn: UIButton!
    @IBOutlet weak var pageTitle: UILabel!
    @IBOutlet weak var categoryDropDown: UIImageView!
    @IBOutlet weak var inventoryNameDropDown: UIImageView!
    
    let database = Firestore.firestore()
    private var selectedCategory: InventoryCategory?
    private var selectedInventoryItem: String?
    private let categoryPicker = UIPickerView()
    private let inventoryItemPicker = UIPickerView()
    
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
    
    enum InventoryItem: String, CaseIterable {
        case desktopPC = "Desktop PC"
        case iMac = "iMac"
        case keyboard = "Keyboard"
        case mouse = "Mouse"
        case headphones = "Headphones"
        case printer = "Printer"
        case desk = "Desk"
        case chair = "Chair"
        case other = "Other..."
        
        var displayName: String {
            return self.rawValue
        }
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPickers()
        setupDropdownTaps()
        setupQuantityField()
        configureEditMode()
        setupNavigationBackButton()
        
        // Dismiss keyboard when tapping outside
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        // 🔔 Request notification permissions
        PushNotificationManager.shared.requestAuthorization { granted in
            if granted {
                print("✅ Notification permissions granted")
            } else {
                print("⚠️ Notification permissions not granted")
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Ensure keyboard is dismissed when view appears
        view.endEditing(true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Clean up keyboard when leaving view
        view.endEditing(true)
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
        // Force all text fields to resign first responder
        itemName.resignFirstResponder()
        category.resignFirstResponder()
        quantity.resignFirstResponder()
        location.resignFirstResponder()
        reason.resignFirstResponder()
        
        // Also call view.endEditing as a fallback
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
        itemName.text = item.itemName
        selectedInventoryItem = item.itemName
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
        // Category Picker
        categoryPicker.delegate = self
        categoryPicker.dataSource = self
        categoryPicker.tag = 1
        category.inputView = categoryPicker
        
        let categoryToolbar = UIToolbar()
        categoryToolbar.sizeToFit()
        let categoryDone = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissCategoryPicker))
        let categoryFlex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        categoryToolbar.items = [categoryFlex, categoryDone]
        category.inputAccessoryView = categoryToolbar
        
        // Inventory Item Picker
        inventoryItemPicker.delegate = self
        inventoryItemPicker.dataSource = self
        inventoryItemPicker.tag = 2
        itemName.inputView = inventoryItemPicker
        
        let itemToolbar = UIToolbar()
        itemToolbar.sizeToFit()
        let itemDone = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissItemPicker))
        let itemFlex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        itemToolbar.items = [itemFlex, itemDone]
        itemName.inputAccessoryView = itemToolbar
    }
    
    @objc private func dismissCategoryPicker() {
        category.resignFirstResponder()
    }
    
    @objc private func dismissItemPicker() {
        itemName.resignFirstResponder()
    }
    
    private func setupDropdownTaps() {
        categoryDropDown.isUserInteractionEnabled = true
        categoryDropDown.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(openCategoryPicker))
        )
        
        inventoryNameDropDown.isUserInteractionEnabled = true
        inventoryNameDropDown.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(openInventoryItemPicker))
        )
    }
    
    @objc private func openCategoryPicker() {
        category.becomeFirstResponder()
    }
    
    @objc private func openInventoryItemPicker() {
        itemName.becomeFirstResponder()
    }
    
    private func showOtherItemAlert() {
        let alert = UIAlertController(
            title: "Other Inventory Item",
            message: "Please enter the inventory item you want to request:",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "Enter item name"
            textField.autocapitalizationType = .words
        }
        
        let confirmAction = UIAlertAction(title: "Done", style: .default) { [weak self] _ in
            guard let self = self,
                  let textField = alert.textFields?.first,
                  let customItem = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !customItem.isEmpty else {
                return
            }
            
            self.selectedInventoryItem = customItem
            self.itemName.text = customItem
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            if self?.selectedInventoryItem == nil {
                self?.itemName.text = ""
            }
        }
        
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    // MARK: - Save Action
    
    @IBAction func saveBtn(_ sender: UIButton) {
        resetFieldBorders()
        
        guard validateFields() else { return }
        
        let data: [String: Any] = [
            "itemName": itemName.text!.trimmingCharacters(in: .whitespacesAndNewlines),
            "category": selectedCategory!.rawValue,
            "quantity": Int(quantity.text!)!,
            "location": location.text!.trimmingCharacters(in: .whitespacesAndNewlines),
            "reason": reason.text!.trimmingCharacters(in: .whitespacesAndNewlines),
            "updatedAt": Timestamp()
        ]
        
        if isEditMode, let documentId = documentId {
            updateRequest(documentId: documentId, data: data)
        } else {
            checkStockAndCreateRequest(data: data)
        }
    }
    
    // MARK: - Stock Management
    
    private func checkStockAndCreateRequest(data: [String: Any]) {
        guard let itemNameText = data["itemName"] as? String,
              let requestedQuantity = data["quantity"] as? Int else {
            return
        }
        
        // Show loading indicator
        let loadingAlert = UIAlertController(title: nil, message: "Checking stock availability...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()
        loadingAlert.view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: loadingAlert.view.centerXAnchor),
            loadingIndicator.bottomAnchor.constraint(equalTo: loadingAlert.view.bottomAnchor, constant: -20)
        ])
        present(loadingAlert, animated: true)
        
        // Query inventory stock
        database.collection("inventoryStock")
            .whereField("itemName", isEqualTo: itemNameText)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                loadingAlert.dismiss(animated: true) {
                    if let error = error {
                        self.showAlert("Error checking stock: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents, !documents.isEmpty else {
                        self.showStockAlert(
                            title: "Item Not in Stock",
                            message: "The item '\(itemNameText)' is not available in the inventory. Please contact the administrator."
                        )
                        return
                    }
                    
                    let document = documents[0]
                    let stockDocumentId = document.documentID
                    let currentStock = document.data()["quantity"] as? Int ?? 0
                    
                    if currentStock < requestedQuantity {
                        self.showStockAlert(
                            title: "Insufficient Stock",
                            message: "Only \(currentStock) unit(s) of '\(itemNameText)' available. You requested \(requestedQuantity) unit(s)."
                        )
                    } else {
                        // Sufficient stock, proceed with request and decrease stock
                        self.createRequestAndUpdateStock(
                            data: data,
                            stockDocumentId: stockDocumentId,
                            currentStock: currentStock,
                            requestedQuantity: requestedQuantity
                        )
                    }
                }
            }
    }
    
    private func createRequestAndUpdateStock(data: [String: Any], stockDocumentId: String, currentStock: Int, requestedQuantity: Int) {
        let newStock = currentStock - requestedQuantity
        
        // Update stock first
        database.collection("inventoryStock")
            .document(stockDocumentId)
            .updateData(["quantity": newStock]) { [weak self] error in
                guard let self = self else { return }
                
                if let error = error {
                    self.showAlert("Error updating stock: \(error.localizedDescription)")
                    return
                }
                
                print("✅ Stock updated: \(currentStock) -> \(newStock)")
                
                // Now create the request
                self.newRequest(data: data)
            }
    }
    
    private func showStockAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Validation
    
    private func validateFields() -> Bool {
        let fieldsToCheck: [(UITextField?, String)] = [
            (itemName, "Please select or enter an item name"),
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
        let fields: [UITextField?] = [itemName, category, quantity, location, reason]
        for field in fields {
            field?.layer.borderWidth = 0
        }
    }
    
    // MARK: - Database Operations
    
    func newRequest(data: [String: Any]) {
        var newData = data
        newData["createdAt"] = Timestamp()
        newData["status"] = "pending"
        
        if let userId = Auth.auth().currentUser?.uid {
            newData["userId"] = userId
        }
        
        let collectionRef = database.collection("inventoryRequest")
        
        // ✅ Create document reference first
        let docRef = collectionRef.document()
        let requestId = docRef.documentID
        
        // ✅ Write data
        docRef.setData(newData) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                loadingAlert.dismiss(animated: true) {
                    self.showAlert("Error saving request: \(error.localizedDescription)")
                }
                return
            }
            
            print("✅ Inventory request saved to Firestore")
            
            // 🤖 Auto-assign technician
            AutoAssignmentService.shared.autoAssignTechnician(
                requestId: requestId,
                requestType: "inventory",
                category: self.selectedCategory?.rawValue ?? "general",
                location: self.location.text ?? "",
                urgency: "normal"
            ) { success, errorMessage in
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
            }
            
            // 🔔 Push notification
            let itemNameText = self.itemName.text ?? "Inventory Item"
            let locationText = self.location.text ?? ""
            
            PushNotificationManager.shared.createNotificationForRequest(
                requestType: "Inventory",
                requestName: itemNameText,
                status: "submitted",
                location: locationText
            ) { success in
                if success {
                    print("✅ Push notification scheduled successfully")
                    
                    NotificationManager.shared.showSuccess(
                        title: "Request Submitted ✓",
                        message: "Your inventory request has been submitted successfully."
                    )
                } else {
                    print("⚠️ Failed to schedule push notification")
                }
                
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
        if pickerView.tag == 1 {
            return InventoryCategory.allCases.count
        } else if pickerView.tag == 2 {
            return InventoryItem.allCases.count
        }
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView.tag == 1 {
            return InventoryCategory.allCases[row].displayName
        } else if pickerView.tag == 2 {
            return InventoryItem.allCases[row].displayName
        }
        return nil
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView.tag == 1 {
            let cat = InventoryCategory.allCases[row]
            selectedCategory = cat
            category.text = cat.displayName
            category.resignFirstResponder()
        } else if pickerView.tag == 2 {
            let item = InventoryItem.allCases[row]
            
            if item == .other {
                itemName.resignFirstResponder()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    self?.showOtherItemAlert()
                }
            } else {
                selectedInventoryItem = item.displayName
                itemName.text = item.displayName
                itemName.resignFirstResponder()
            }
        }
    }
}

// MARK: - UITextField Delegate

extension NewInventoryViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == quantity {
            let allowedCharacters = CharacterSet.decimalDigits
            let characterSet = CharacterSet(charactersIn: string)
            return allowedCharacters.isSuperset(of: characterSet)
        }
        return true
    }
}
