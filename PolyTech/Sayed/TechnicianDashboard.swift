import UIKit
import FirebaseFirestore

class TechnicianDashboardViewController: UIViewController {

    @IBOutlet weak var totalRequestsCard: UIView!
    @IBOutlet weak var pendingCard: UIView!
    @IBOutlet weak var inProgressCard: UIView!
    @IBOutlet weak var completedCard: UIView!
    @IBOutlet weak var StatusCard: UIView!
    
    @IBOutlet weak var totalCountLabel: UILabel!
    @IBOutlet weak var pendingCountLabel: UILabel!
    @IBOutlet weak var inProgressCountLabel: UILabel!
    @IBOutlet weak var completedCountLabel: UILabel!
    
    @IBOutlet weak var completedLegendLabel: UILabel!
    @IBOutlet weak var inProgressLegendLabel: UILabel!
    @IBOutlet weak var pendingLegendLabel: UILabel!
    
    @IBOutlet weak var taskListButton: UIButton!
    @IBOutlet weak var donutChartView: DonutChartViewTwo!
    
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUIElements()
        fetchDashboardData()
    }
    
    func fetchDashboardData() {
            db.collection("tasks").addSnapshotListener { [weak self] (querySnapshot, error) in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching tasks: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                let total = documents.count
                let pending = documents.filter { ($0.data()["status"] as? String) == "Pending" }.count
                let inProgress = documents.filter { ($0.data()["status"] as? String) == "In Progress" }.count
                let completed = documents.filter { ($0.data()["status"] as? String) == "Completed" }.count

                DispatchQueue.main.async {
                    self?.updateDashboardUI(total: total, pending: pending, inProgress: inProgress, completed: completed)
                    self?.updateChartData(pending: pending, inProgress: inProgress, completed: completed)
                }
            }
        }
    
    func updateDashboardUI(total: Int, pending: Int, inProgress: Int, completed: Int) {
        totalCountLabel.text = "\(total)"
        pendingCountLabel.text = "\(pending)"
        inProgressCountLabel.text = "\(inProgress)"
        completedCountLabel.text = "\(completed)"
        
        completedLegendLabel.text = "Completed (\(completed))"
        inProgressLegendLabel.text = "In Progress (\(inProgress))"
        pendingLegendLabel.text = "Pending (\(pending))"
        }
    
    func updateChartData(pending: Int, inProgress: Int, completed: Int) {
            guard let chart = donutChartView else { return }
            
            let colorCompleted = UIColor(red: 0.00, green: 0.42, blue: 0.85, alpha: 1.0)
            let colorInProgress = UIColor(red: 0.35, green: 0.67, blue: 0.93, alpha: 1.0)
            let colorPending = UIColor(red: 0.56, green: 0.62, blue: 0.67, alpha: 1.0)

            chart.segments = [
                DonutChartViewTwo.Segment(value: CGFloat(completed), color: colorCompleted),
                DonutChartViewTwo.Segment(value: CGFloat(inProgress), color: colorInProgress),
                DonutChartViewTwo.Segment(value: CGFloat(pending), color: colorPending)
            ]
            
            chart.setNeedsDisplay()
        }
    
    func setupUIElements() {
            let cornerRadius: CGFloat = 12.0
            
            [totalRequestsCard, pendingCard, inProgressCard, completedCard, StatusCard].forEach { card in
                if let card = card {
                    applyCardStyling(to: card, cornerRadius: cornerRadius)
                }
            }
            
            taskListButton.layer.cornerRadius = 15.0
            taskListButton.backgroundColor = UIColor(named: "PrimaryDarkBlue") ?? .darkGray
            taskListButton.setTitleColor(.white, for: .normal)
        }
        
        func applyCardStyling(to view: UIView, cornerRadius: CGFloat) {
            view.layer.cornerRadius = cornerRadius
            view.layer.masksToBounds = false
            view.layer.shadowColor = UIColor.black.cgColor
            view.layer.shadowOpacity = 0.1
            view.layer.shadowOffset = CGSize(width: 0, height: 2)
            view.layer.shadowRadius = 4.0
            view.backgroundColor = .white
        }

    @IBAction func taskListButtonTapped(_ sender: UIButton) {
    }
}
