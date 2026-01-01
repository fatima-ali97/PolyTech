import UIKit
import FirebaseFirestore

class MaintenanceViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var maintenanceRequests: [MaintenanceRequestModel] = []
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupAddButton()
        loadMaintenanceRequests()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        listener?.remove()
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(MaintenanceTableViewCell.self, forCellReuseIdentifier: "MaintenanceCell")
        tableView.separatorStyle = .none
    }
    
    private func loadMaintenanceRequests() {
        listener = db.collection("maintenanceRequest")
            .whereField("userId", isEqualTo: UserDefaults.standard.string(forKey: "userId") ?? "")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("❌ Error: \(error.localizedDescription)")
                    return
                }
                self.maintenanceRequests = snapshot?.documents.compactMap {
                    MaintenanceRequestModel(dictionary: $0.data(), id: $0.documentID)
                } ?? []
                self.maintenanceRequests.sort { $0.createdAt.dateValue() > $1.createdAt.dateValue() }
                DispatchQueue.main.async { self.tableView.reloadData() }
            }
    }
    private func setupAddButton() {
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(navigateToNewMaintenance)
        )
        navigationItem.rightBarButtonItem = addButton
    }
    @objc private func navigateToNewMaintenance() {
        let storyboard = UIStoryboard(name: "NewMaintenance", bundle: nil)
        guard let vc = storyboard.instantiateViewController(
            withIdentifier: "NewMaintenanceViewController"
        ) as? NewMaintenanceViewController else {
            print("❌ Could not find NewMaintenanceViewController")
            return
        }
        navigationController?.pushViewController(vc, animated: true)
    }

}

// MARK: - TableView
extension MaintenanceViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return maintenanceRequests.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "MaintenanceCell",
            for: indexPath
        ) as? MaintenanceTableViewCell else { return UITableViewCell() }
        
        let item = maintenanceRequests[indexPath.row]
        
        cell.configure(with: item,
                       viewCallback: { [weak self] in self?.showDetails(item) },
                       editCallback: { [weak self] in self?.navigateToEdit(item) })
        return cell
    }
    
    private func showDetails(_ item: MaintenanceRequestModel) {
        var message = """
        Request: \(item.requestName)
        Location: \(item.location)
        Category: \(item.category.capitalized)
        Urgency: \(item.urgency.rawValue.capitalized)
        Created: \(item.formattedDate)
        """
        if let imageUrl = item.imageUrl {
            message += "\nImage: \(imageUrl)"
        }
        
        let alert = UIAlertController(title: "Maintenance Details", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func navigateToEdit(_ item: MaintenanceRequestModel) {
        let storyboard = UIStoryboard(name: "NewMaintenance", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "NewMaintenanceViewController")
                as? NewMaintenanceViewController else { return }
        vc.requestToEdit = item
        navigationController?.pushViewController(vc, animated: true)
    }
}
