import UIKit
import FirebaseFirestore
import FirebaseAuth

class ReturnInventoryViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    var itemToEdit: Inventory?
    @IBOutlet weak var itemName: UITextField!
    @IBOutlet weak var category: UITextField!
    @IBOutlet weak var quantity: UITextField!
    @IBOutlet weak var reason: UITextField!
    @IBOutlet weak var condition: UITextField!
    @IBOutlet weak var returnbtn: UIButton!
    @IBOutlet weak var pageTitle: UILabel!
    @IBOutlet weak var categoryDropDown: UIImageView!
    @IBOutlet weak var inventoryNameDropDown: UIImageView!
    
    let database = Firestore.firestore()
    
    private var selectedCategory: InventoryCategory?
    private var selectedInventoryItem: String?
    private let categoryPicker = UIPickerView()
    private let inventoryItemPicker = UIPickerView()
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pageTitle.text = "New Return Inventory"
        returnbtn.setTitle("Save", for: .normal)
        
        quantity.delegate = self
        quantity.keyboardType = .numberPad
        
        setupPickers()
        setupDropdownTaps()

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
    
    private func setupPickers() {
        // Category Picker
        categoryPicker.delegate = self
        categoryPicker.dataSource = self
        category.inputView = categoryPicker
        
        let categoryToolbar = UIToolbar()
        categoryToolbar.sizeToFit()
        let categoryFlex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let categoryDone = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissCategoryPicker))
        categoryToolbar.items = [categoryFlex, categoryDone]
        category.inputAccessoryView = categoryToolbar
        
        // Inventory Item Picker
        inventoryItemPicker.delegate = self
        inventoryItemPicker.dataSource = self
        itemName.inputView = inventoryItemPicker
        
        let itemToolbar = UIToolbar()
        itemToolbar.sizeToFit()
        let itemFlex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let itemDone = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissItemPicker))
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
            message: "Please enter the inventory item you want to return:",
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

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == categoryPicker {
            return InventoryCategory.allCases.count
        } else if pickerView == inventoryItemPicker {
            return InventoryItem.allCases.count
        }
        return 0
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == categoryPicker {
            return InventoryCategory.allCases[row].displayName
        } else if pickerView == inventoryItemPicker {
            return InventoryItem.allCases[row].displayName
        }
        return nil
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == categoryPicker {
            let cat = InventoryCategory.allCases[row]
            selectedCategory = cat
            category.text = cat.displayName
        } else if pickerView == inventoryItemPicker {
            let item = InventoryItem.allCases[row]
            
            if item == .other {
                itemName.resignFirstResponder()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    self?.showOtherItemAlert()
                }
            } else {
                selectedInventoryItem = item.displayName
                itemName.text = item.displayName
            }
        }
    }

    @IBAction func Returnbtn(_ sender: UIButton) {
        guard
            let itemNameText = itemName.text?.trimmingCharacters(in: .whitespacesAndNewlines), !itemNameText.isEmpty,
            let _ = selectedCategory,
            let quantityText = quantity.text, let quantityValue = Int(quantityText),
            let reasonText = reason.text?.trimmingCharacters(in: .whitespacesAndNewlines), !reasonText.isEmpty,
            let conditionText = condition.text?.trimmingCharacters(in: .whitespacesAndNewlines), !conditionText.isEmpty
        else {
            let alert = UIAlertController(
                title: "Error",
                message: "Please fill in all fields correctly",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        let data: [String: Any] = [
            "itemName": itemNameText,
            "category": selectedCategory!.rawValue,
            "quantity": quantityValue,
            "reason": reasonText,
            "condition": conditionText,
            "createdAt": Timestamp()
        ]
        
        // Save return request and increase stock
        saveReturnAndUpdateStock(data: data, itemName: itemNameText, returnQuantity: quantityValue)
    }
    
    // MARK: - Stock Management
    
    private func saveReturnAndUpdateStock(data: [String: Any], itemName: String, returnQuantity: Int) {
        // Show loading indicator
        let loadingAlert = UIAlertController(title: nil, message: "Processing return...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()
        loadingAlert.view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: loadingAlert.view.centerXAnchor),
            loadingIndicator.bottomAnchor.constraint(equalTo: loadingAlert.view.bottomAnchor, constant: -20)
        ])
        present(loadingAlert, animated: true)
        
        // First, save the return request
        database.collection("returnInventoryRequest").addDocument(data: data) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                loadingAlert.dismiss(animated: true) {
                    self.showAlert("Error saving return request: \(error.localizedDescription)")
                }
                return
            }
            
            print("✅ Return request saved to Firestore")
            
            // Now update the stock
            self.updateInventoryStock(itemName: itemName, returnQuantity: returnQuantity) { success in
                loadingAlert.dismiss(animated: true) {
                    if success {
                        self.handleResult(error: nil, successMessage: "Return inventory saved successfully and stock updated ✅")
                    } else {
                        // Return was saved but stock update failed
                        self.showAlert("Return saved but stock update failed. Please contact administrator.")
                    }
                }
            }
        }
    }
    
    private func updateInventoryStock(itemName: String, returnQuantity: Int, completion: @escaping (Bool) -> Void) {
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
                    // Item exists in stock, update it
                    let document = documents[0]
                    let stockDocumentId = document.documentID
                    let currentStock = document.data()["quantity"] as? Int ?? 0
                    let newStock = currentStock + returnQuantity
                    
                    self.database.collection("inventoryStock")
                        .document(stockDocumentId)
                        .updateData(["quantity": newStock]) { error in
                            if let error = error {
                                print("❌ Error updating stock: \(error.localizedDescription)")
                                completion(false)
                            } else {
                                print("✅ Stock updated: \(currentStock) -> \(newStock)")
                                completion(true)
                            }
                        }
                } else {
                    // Item doesn't exist in stock, create new entry
                    self.createNewStockEntry(itemName: itemName, quantity: returnQuantity, completion: completion)
                }
            }
    }
    
    private func createNewStockEntry(itemName: String, quantity: Int, completion: @escaping (Bool) -> Void) {
        let stockData: [String: Any] = [
            "itemName": itemName,
            "quantity": quantity,
            "createdAt": Timestamp()
        ]
        
        database.collection("inventoryStock").addDocument(data: stockData) { error in
            if let error = error {
                print("❌ Error creating stock entry: \(error.localizedDescription)")
                completion(false)
            } else {
                print("✅ New stock entry created for '\(itemName)' with quantity: \(quantity)")
                completion(true)
            }
        }
    }
    
    func handleResult(error: Error?, successMessage: String) {
        if let error = error {
            let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
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
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == quantity {
            let allowedCharacters = CharacterSet.decimalDigits
            let characterSet = CharacterSet(charactersIn: string)
            return allowedCharacters.isSuperset(of: characterSet)
        }
        return true
    }
}
