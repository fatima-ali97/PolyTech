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
}
