import UIKit
import FirebaseFirestore

final class DelayedRequestsViewController: UIViewController {

    struct DelayedRequest {
        let id: String
        let title: String
        let daysDelayed: Int
        let location: String
    }
    
    struct TechnicianItem {
        let id: String
        let name: String
    }

    @IBOutlet weak var tableView: UITableView!

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var delayedRequests: [DelayedRequest] = []

    private let delayedAfterDays: Int = 3
    
    private var technicians: [TechnicianItem] = []
    private var techListener: ListenerRegistration?
    
    private var delayedOldListener: ListenerRegistration?
    private var rejectedListener: ListenerRegistration?

    private var oldMap: [String: DelayedRequest] = [:]
    private var rejectedMap: [String: DelayedRequest] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self

        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 110

        loadDelayedRequests()
        loadTechnicians()
        
        // 🔔 Start monitoring for delayed requests and send notifications
        DelayedRequestNotificationService.shared.startMonitoringDelayedRequests()
        
        // 🔔 Check for existing delayed requests immediately
        DelayedRequestNotificationService.shared.checkForDelayedRequests { [weak self] count in
            print("📊 Initial delayed requests check: \(count) requests found")
            if count > 0 {
                // Show a banner notification to admin
                DispatchQueue.main.async {
                    self?.showDelayedRequestsBanner(count: count)
                }
            }
        }
    }

    deinit {
        delayedOldListener?.remove()
        rejectedListener?.remove()
        techListener?.remove()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Don't stop monitoring - let it continue in background
    }
    
    // MARK: - Show Banner
    
    private func showDelayedRequestsBanner(count: Int) {
        let message = count == 1
            ? "There is 1 delayed request requiring attention"
            : "There are \(count) delayed requests requiring attention"
        
        NotificationManager.shared.showWarning(
            title: "Delayed Requests ⚠️",
            message: message
        )
    }

    // MARK: - Load Delayed Requests
    
    private func loadDelayedRequests() {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -delayedAfterDays, to: Date())!
        let cutoffTimestamp = Timestamp(date: cutoffDate)
        
        print("🔍 Loading delayed requests with cutoff date: \(cutoffDate)")

        func rebuildList() {
            var merged = oldMap
            rejectedMap.forEach { merged[$0.key] = $0.value }

            self.delayedRequests = Array(merged.values).sorted {
                // Sort by days delayed (most delayed first)
                if $0.daysDelayed != $1.daysDelayed {
                    return $0.daysDelayed > $1.daysDelayed
                }
                return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }

            print("📊 Total delayed requests to display: \(self.delayedRequests.count)")
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }

        // Listen for pending requests older than 3 days
        delayedOldListener?.remove()
        delayedOldListener = db.collection("maintenanceRequest")
            .whereField("status", isEqualTo: "pending")
            .whereField("createdAt", isLessThanOrEqualTo: cutoffTimestamp)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error = error {
                    print("❌ delayed(old) requests error:", error)
                    return
                }

                let docs = snapshot?.documents ?? []
                print("📊 Found \(docs.count) pending requests older than cutoff")
                
                self.oldMap = Dictionary(uniqueKeysWithValues: docs.compactMap { doc in
                    let data = doc.data()

                    guard let title = data["requestName"] as? String,
                          let createdAt = data["createdAt"] as? Timestamp else {
                        return nil
                    }
                    
                    let location = data["location"] as? String ?? "Unknown"
                    let daysDelayed = self.calculateDaysDelayed(from: createdAt.dateValue())
                    
                    // Only include if truly delayed (3+ days)
                    guard daysDelayed >= self.delayedAfterDays else {
                        return nil
                    }
                    
                    return (doc.documentID, DelayedRequest(
                        id: doc.documentID,
                        title: title,
                        daysDelayed: daysDelayed,
                        location: location
                    ))
                })

                rebuildList()
            }

        // Listen for rejected requests (regardless of age)
        rejectedListener?.remove()
        rejectedListener = db.collection("maintenanceRequest")
            .whereField("rejected", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error = error {
                    print("❌ rejected requests error:", error)
                    return
                }

                let docs = snapshot?.documents ?? []
                print("📊 Found \(docs.count) rejected requests")
                
                self.rejectedMap = Dictionary(uniqueKeysWithValues: docs.compactMap { doc in
                    let data = doc.data()

                    // Skip completed rejected requests
                    if let status = data["status"] as? String, status.lowercased() == "completed" {
                        return nil
                    }

                    guard let title = data["requestName"] as? String,
                          let createdAt = data["createdAt"] as? Timestamp else {
                        return nil
                    }
                    
                    let location = data["location"] as? String ?? "Unknown"
                    let daysDelayed = self.calculateDaysDelayed(from: createdAt.dateValue())
                    
                    return (doc.documentID, DelayedRequest(
                        id: doc.documentID,
                        title: title,
                        daysDelayed: daysDelayed,
                        location: location
                    ))
                })

                rebuildList()
            }
    }
    
    // MARK: - Calculate Days Delayed
    
    private func calculateDaysDelayed(from date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: date, to: Date())
        return components.day ?? 0
    }
    
    // MARK: - Load Technicians
    
    private func loadTechnicians() {
        techListener = db.collection("technicians")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error = error {
                    print("❌ technicians load error:", error)
                    return
                }

                let docs = snapshot?.documents ?? []
                self.technicians = docs.compactMap { doc in
                    let data = doc.data()
                    guard let name = data["name"] as? String else { return nil }
                    return TechnicianItem(id: doc.documentID, name: name)
                }

                self.technicians.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                
                print("👥 Loaded \(self.technicians.count) technicians")

                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
    }
    
    // MARK: - Assign Technician
    
    private func assign(requestId: String, technician: TechnicianItem) {
        // First get the request details
        db.collection("maintenanceRequest").document(requestId).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Failed to fetch request: \(error)")
                self.showError("Failed to assign technician")
                return
            }
            
            guard let data = document?.data(),
                  let requestName = data["requestName"] as? String,
                  let location = data["location"] as? String else {
                print("❌ Missing request data")
                self.showError("Failed to assign technician")
                return
            }
            
            let urgency = data["urgency"] as? String ?? "normal"
            let category = data["category"] as? String ?? "general"
            
            // Update the request with assignment
            let updates: [String: Any] = [
                "assignedTechnicianId": technician.id,
                "assignedTechnicianName": technician.name,
                "status": "in_progress",
                "updatedAt": FieldValue.serverTimestamp()
            ]
            
            self.db.collection("maintenanceRequest").document(requestId).updateData(updates) { error in
                if let error = error {
                    print("❌ Failed to reassign:", error)
                    self.showError("Failed to assign technician")
                } else {
                    print("✅ Reassigned request \(requestId) to \(technician.name)")
                    
                    // 🔔 Notify the technician about the assignment
                    TechnicianNotificationService.shared.notifyTechnicianAssignment(
                        technicianId: technician.id,
                        technicianName: technician.name,
                        requestId: requestId,
                        requestName: requestName,
                        location: location,
                        urgency: urgency,
                        category: category
                    )
                    
                    // Show success message
                    self.showSuccess("Request assigned to \(technician.name)")
                    
                    // 🔔 The student will automatically receive "Work Started 🔧" notification
                    // via RequestStatusNotificationService (status changed to in_progress)
                }
            }
        }
    }
    
    // MARK: - UI Helpers
    
    private func showSuccess(_ message: String) {
        let alert = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource & Delegate

extension DelayedRequestsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return delayedRequests.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DelayedRequestCell", for: indexPath) as? DelayedRequestCell else {
            return UITableViewCell()
        }

        let request = delayedRequests[indexPath.row]
        
        // Set title with days delayed info
        let daysText = request.daysDelayed == 1 ? "1 day" : "\(request.daysDelayed) days"
        cell.titleLabel.text = "\(request.title) • \(daysText) delayed"
        
        // Set location if you have a label for it
        // cell.locationLabel.text = request.location

        // Make reassign button a menu
        cell.reassignButton.showsMenuAsPrimaryAction = true

        // Build menu actions from technicians
        let actions = technicians.map { tech in
            UIAction(title: tech.name) { [weak self] _ in
                self?.assign(requestId: request.id, technician: tech)
            }
        }

        cell.reassignButton.menu = UIMenu(title: "Reassign to", children: actions)

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let request = delayedRequests[indexPath.row]
        
        // Show details alert
        let daysText = request.daysDelayed == 1 ? "1 day" : "\(request.daysDelayed) days"
        let alert = UIAlertController(
            title: request.title,
            message: "Location: \(request.location)\nDelayed: \(daysText)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
