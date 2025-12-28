import UIKit
import FirebaseFirestore
import FirebaseAuth

class HistoryViewController: UIViewController,
                             UITableViewDelegate,
                             UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!

    let db = Firestore.firestore()
    var historyList: [HistoryItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        fetchHistory()
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
    }

    
    private func fetchHistory() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        db.collection("inventoryRequest")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in

                if let error = error {
                    print("Error fetching history:", error.localizedDescription)
                    return
                }

                self.historyList = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    return HistoryItem(
                        id: doc.documentID,
                        requestName: data["requestName"] as? String ?? "N/A",
                        itemName: data["itemName"] as? String ?? "N/A",
                        category: data["category"] as? String ?? "N/A",
                        quantity: data["quantity"] as? Int ?? 0,
                        location: data["location"] as? String ?? "N/A",
                        reason: data["reason"] as? String ?? "N/A"
                    )
                } ?? []

                self.tableView.reloadData()
            }
    }


    private func showDetails(item: HistoryItem) {
        let message = """
        Request Name: \(item.requestName)
        Item Name: \(item.itemName)
        Category: \(item.category)
        Quantity: \(item.quantity)
        Location: \(item.location)
        Reason: \(item.reason)
        """

        let alert = UIAlertController(
            title: "Request Details",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc func openFeedbackPage() {
        let storyboard = UIStoryboard(name: "Ali", bundle: nil)
        let vc = storyboard.instantiateViewController(
            withIdentifier: "ServiceFeedbackViewController"
        )
        navigationController?.pushViewController(vc, animated: true)
    }
  
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        historyList.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "HistoryCell",
            for: indexPath
        ) as! HistoryCell

        let item = historyList[indexPath.row]
        cell.requestLabel.text = item.requestName

        cell.onDetailsTapped = { [weak self] in
            self?.showDetails(item: item)
        }

        cell.onFeedbackTapped = { [weak self] in
            self?.openFeedbackPage()
        }

        return cell
    }

    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        140
    }
}
