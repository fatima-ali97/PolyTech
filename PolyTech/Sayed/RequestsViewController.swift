//
//  RequestsViewController.swift
//  PolyTech
//
//  Created by BP-36-212-01 on 31/12/2025.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class RequestsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    let db = Firestore.firestore()
    var requestsList: [TaskRequest] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        
        fetchRequestsFromFirebase()
    }

    func fetchRequestsFromFirebase() {
        db.collection("TasksRequests")
            .whereField("status", isEqualTo: "Pending")
            .addSnapshotListener { (querySnapshot, error) in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    return
                }

                self.requestsList = querySnapshot?.documents.compactMap { document in
                    return TaskRequest(docID: document.documentID, dictionary: document.data())
                } ?? []

                self.tableView.reloadData()
            }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return requestsList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RequestCell", for: indexPath)
        let request = requestsList[indexPath.row]
        
        if let cardView = cell.viewWithTag(200) {
            cardView.layer.borderColor = UIColor.systemGray4.cgColor
            cardView.layer.borderWidth = 1.0
            cardView.layer.cornerRadius = 15
        }

        if let titleLabel = cell.viewWithTag(101) as? UILabel {
            titleLabel.text = request.description
        }
        
        cell.selectionStyle = .none
        return cell
    }

    @IBAction func acceptTaskButtonPressed(_ sender: UIButton) {
        let buttonPosition = sender.convert(CGPoint.zero, to: self.tableView)
        guard let indexPath = self.tableView.indexPathForRow(at: buttonPosition) else { return }
        
        let selectedRequest = requestsList[indexPath.row]
        
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            print("Error: You must log in first")
            return
        }
        
        db.collection("TasksRequests").document(selectedRequest.documentID).updateData([
            "status": "In Progress",
            "technicianID": currentUserID,
            "acceptedDate": Timestamp()
        ]) { error in
            if let error = error {
                print("An error occurred during acceptance: \(error.localizedDescription)")
            } else {
                print("Success: Task accepted")
            }
        }
    }

    @IBAction func addRequestTask(_ sender: Any) {
        let alert = UIAlertController(title: "New Task", message: "All fields are required", preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = "Client Name"
            textField.textAlignment = .left
        }
        alert.addTextField { textField in
            textField.placeholder = "Task ID (Numbers only)"
            textField.keyboardType = .numberPad
            textField.textAlignment = .left
        }
        alert.addTextField { textField in
            textField.placeholder = "Description"
            textField.textAlignment = .left
        }
        alert.addTextField { textField in
            textField.placeholder = "Address"
            textField.textAlignment = .left
        }

        let addAction = UIAlertAction(title: "Add", style: .default) { _ in
            let client = alert.textFields?[0].text ?? ""
            let taskIDString = alert.textFields?[1].text ?? ""
            let desc = alert.textFields?[2].text ?? ""
            let addr = alert.textFields?[3].text ?? ""

            if client.isEmpty || taskIDString.isEmpty || desc.isEmpty || addr.isEmpty {
                self.showErrorAlert(message: "All fields are required. Please fill in everything.")
                return
            }

            if CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: taskIDString)) {
                self.saveTaskToFirestore(client: client, customID: taskIDString, desc: desc, addr: addr)
            } else {
                self.showErrorAlert(message: "Task ID must contain numbers only.")
            }
        }

        alert.addAction(addAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    func showErrorAlert(message: String) {
        let errorAlert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
        present(errorAlert, animated: true)
    }
    
    func saveTaskToFirestore(client: String, customID: String, desc: String, addr: String) {
        let newTaskData: [String: Any] = [
            "client": client,
            "id": customID,
            "description": desc,
            "Address": addr,
            "status": "Pending",
            "createdAt": FieldValue.serverTimestamp(),
            "note": ""
        ]

        db.collection("TasksRequests").addDocument(data: newTaskData) { error in
            if let error = error {
                print("Firestore Error: \(error.localizedDescription)")
            } else {
                print("Successfully added task with server timestamp")
            }
        }
    }
}
