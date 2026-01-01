import UIKit
import FirebaseFirestore
import FirebaseAuth

class NewInventoryViewController: UIViewController {
    var itemToEdit: Inventory?
    var isEditMode = false
    var documentId: String?
    var existingData: [String: Any]?
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPickers()
        setupDropdownTap()
        setupQuantityField()
        configureEditMode()
        
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = nil

        //for back navigation
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

    private func populateFields() {
        guard let data = existingData else { return }
        
        requestName.text = data["requestName"] as? String
        requestName.isEnabled = false
        
        itemName.text = data["itemName"] as? String
        itemName.isEnabled = false

        quantity.text = "\(data["quantity"] as? Int ?? 0)"
        location.text = data["location"] as? String
        reason.text = data["reason"] as? String

        if let categoryRaw = data["category"] as? String,
           let cat = InventoryCategory(rawValue: categoryRaw) {
            selectedCategory = cat
            category.text = cat.displayName
        }
    }

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
            updateRequest(documentId: documentId, data: data)
        } else {
            newRequest(data: data)
        }
    }

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
    

    func newRequest(data: [String: Any]) {
        var newData = data
        newData["createdAt"] = Timestamp()
        
        // Add the current user's ID
        if let userId = Auth.auth().currentUser?.uid {
            newData["userId"] = userId
        }
        
        database.collection("inventoryRequest").addDocument(data: newData) { [weak self] error in
            self?.handleResult(error: error, successMessage: "Inventory request created successfully ✅")
        }
    }

    
    func updateRequest(documentId: String, data: [String: Any]) {
        database.collection("inventoryRequest")
            .document(documentId)
            .updateData(data) { [weak self] error in
                self?.handleResult(error: error, successMessage: "Inventory request updated successfully ✅")
            }
    }
    
    private func handleResult(error: Error?, successMessage: String) {
        if let error = error {
            showAlert("Error: \(error.localizedDescription)")
        } else {
            let alert = UIAlertController(title: "Success", message: successMessage, preferredStyle: .alert)
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
}

extension NewInventoryViewController: UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
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
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == quantity {

            let allowedCharacters = CharacterSet.decimalDigits
            let characterSet = CharacterSet(charactersIn: string)
            return allowedCharacters.isSuperset(of: characterSet)
        }
        return true
    }
}
