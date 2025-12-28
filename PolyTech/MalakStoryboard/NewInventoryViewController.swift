import UIKit
import FirebaseFirestore
import FirebaseAuth

class NewInventoryViewController: UIViewController {

    var isEditMode = false
    var documentId: String?
    var existingData: [String: Any]?

    @IBOutlet weak var requestName: UITextField!
    @IBOutlet weak var itemName: UITextField!
    @IBOutlet weak var category: UITextField!
    @IBOutlet weak var quantity: UITextField!
    @IBOutlet weak var location: UITextField!
    @IBOutlet weak var reason: UITextField!
    @IBOutlet weak var Backbtn: UIImageView!
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
        setupBackBtn()
        setupPickers()
        setupDropdownTap()
        configureEditMode()
        quantity.delegate = self
        quantity.keyboardType = .numberPad
    }

    private func configureEditMode() {
        if isEditMode {
            pageTitle.text = "Edit Inventory Request"
            savebtn.setTitle("Edit", for: .normal)
            populateFields()
        } else {
            pageTitle.text = "New Inventory Request"
            savebtn.setTitle("Save", for: .normal)
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
        // Reset all borders first
        resetFieldBorders()
        
        // Collect all fields in a tuple: (field, error message)
        let fieldsToCheck: [(UITextField?, String)] = [
            (requestName, "Please enter the request name"),
            (itemName, "Please enter the item name"),
            (quantity, "Please enter a valid quantity"),
            (location, "Please enter the location"),
            (reason, "Please enter a reason"),
            (category, "Please select a category")
        ]
        
        var hasError = false
        
        for (field, message) in fieldsToCheck {
            if field == category && selectedCategory == nil {
                // Special check for category
                markFieldAsInvalid(category)
                showAlert(message)
                hasError = true
                break
            } else if let textField = field, (textField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) {
                markFieldAsInvalid(textField)
                showAlert(message)
                hasError = true
                break
            } else if field == quantity, let text = quantity.text, (Int(text) ?? 0) <= 0 {
                markFieldAsInvalid(quantity)
                showAlert("Please enter a valid quantity")
                hasError = true
                break
            }
        }
        
        guard !hasError else { return }
        
        // All fields are valid, prepare data
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
    

    private func setupBackBtn() {

        Backbtn.isUserInteractionEnabled = true

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backBtnTapped))
        Backbtn.addGestureRecognizer(tapGesture)
    }
    
    @objc func backBtnTapped() {

        let storyboard = UIStoryboard(name: "Inventory", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "InventoryViewController") as? InventoryViewController else {
            print("InventoryViewController not found in storyboard")
            return
        }
        
        navigationController?.pushViewController(vc, animated: true)
    }



    func newRequest(data: [String: Any]) {
        var newData = data
        newData["createdAt"] = Timestamp()

        database.collection("inventoryRequest").addDocument(data: newData) { [weak self] error in
            self?.handleResult(error: error, successMessage: "Inventory request created successfully")
        }
    }

    func updateRequest(documentId: String, data: [String: Any]) {
        database.collection("inventoryRequest")
            .document(documentId)
            .updateData(data) { [weak self] error in
                self?.handleResult(error: error, successMessage: "Inventory request updated successfully")
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

    private func setupPickers() {
        categoryPicker.delegate = self
        categoryPicker.dataSource = self
        category.inputView = categoryPicker
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
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        InventoryCategory.allCases.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        InventoryCategory.allCases[row].displayName
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let cat = InventoryCategory.allCases[row]
        selectedCategory = cat
        category.text = cat.displayName
        category.resignFirstResponder()
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
           if textField == quantity {
               // Only allow digits
               let allowedCharacters = CharacterSet.decimalDigits
               let characterSet = CharacterSet(charactersIn: string)
               return allowedCharacters.isSuperset(of: characterSet)
           }
           return true
       }
}
