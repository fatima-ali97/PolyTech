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
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }

        db.collection("maintenanceRequest")
            .whereField("status", isEqualTo: "Pending")
            .addSnapshotListener { (querySnapshot, error) in
                if let error = error {
                    print("Error fetching tasks: \(error.localizedDescription)")
                    return
                }

                self.requestsList = querySnapshot?.documents.compactMap { document in
                    let data = document.data()
                    let declinedBy = data["declinedBy"] as? [String] ?? []
                    
                    if declinedBy.contains(currentUserID) {
                        return nil
                    }
                    
                    return TaskRequest(docID: document.documentID, dictionary: data)
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
        
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        db.collection("maintenanceRequest").document(selectedRequest.documentID).updateData([
            "status": "In Progress",
            "technicianID": currentUserID,
            "acceptedDate": Timestamp()
        ]) { error in
            if error == nil { print("Success: Task accepted") }
        }
    }

    @IBAction func addRequestTask(_ sender: Any) {
        let alert = UIAlertController(title: "New Task", message: "All fields are required", preferredStyle: .alert)

        alert.addTextField { $0.placeholder = "Client Name" }
        alert.addTextField { $0.placeholder = "Task ID (Numbers)"; $0.keyboardType = .numberPad }
        alert.addTextField { $0.placeholder = "Description" }
        alert.addTextField { $0.placeholder = "Address" }

        let addAction = UIAlertAction(title: "Add", style: .default) { _ in
            let client = alert.textFields?[0].text ?? ""
            let taskID = alert.textFields?[1].text ?? ""
            let desc = alert.textFields?[2].text ?? ""
            let addr = alert.textFields?[3].text ?? ""

            if client.isEmpty || taskID.isEmpty || desc.isEmpty || addr.isEmpty {
                self.showErrorAlert(message: "All fields are required.")
                return
            }
            self.saveTaskToFirestore(client: client, customID: taskID, desc: desc, addr: addr)
        }

        alert.addAction(addAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    func saveTaskToFirestore(client: String, customID: String, desc: String, addr: String) {
        let newTaskData: [String: Any] = [
            "userId": client,
            "id": customID,
            "requestName": desc,
            "location": addr,
            "status": "Pending",
            "technicianID": "",
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
            "urgency": "high",
            "declinedBy": [],
            "note": ""
        ]

        db.collection("maintenanceRequest").addDocument(data: newTaskData) { error in
            if let error = error {
                print("❌ Firestore Error: \(error.localizedDescription)")
            } else {
                print("✅ Task successfully saved to maintenanceRequest")
            }
        }
    }

    @IBAction func declineTaskButtonPressed(_ sender: UIButton) {
        let buttonPosition = sender.convert(CGPoint.zero, to: self.tableView)
        guard let indexPath = self.tableView.indexPathForRow(at: buttonPosition) else { return }
        let selectedRequest = requestsList[indexPath.row]
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }

        let docRef = db.collection("maintenanceRequest").document(selectedRequest.documentID)

        docRef.updateData([
            "declinedBy": FieldValue.arrayUnion([currentUserID])
        ]) { error in
            if error == nil {
                self.checkDeclineThreshold(documentID: selectedRequest.documentID)
            }
        }
    }
    
    func checkDeclineThreshold(documentID: String) {
        self.db.collection("maintenanceRequest").document(documentID).getDocument { (doc, err) in
            if let data = doc?.data(), let declinedBy = data["declinedBy"] as? [String] {
                if declinedBy.count >= 3 {
                    self.moveTaskToGlobalRequests(documentID: documentID, data: data)
                }
            }
        }
    }

    func moveTaskToGlobalRequests(documentID: String, data: [String: Any]) {
        var updatedData = data
        updatedData["status"] = "Rejected"
        updatedData["rejected"] = true
        updatedData["movedAt"] = FieldValue.serverTimestamp()
        if let desc = data["description"] as? String { updatedData["requestName"] = desc }

        db.collection("requests").document(documentID).setData(updatedData) { error in
            if error == nil {
                self.db.collection("maintenanceRequest").document(documentID).updateData([
                    "status": "Rejected",
                    "rejected": true
                ])
            }
        }
    }

    func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
