import UIKit

class TechnicianDashboardViewController: UIViewController {

    @IBOutlet weak var totalRequestsCard: UIView!
    @IBOutlet weak var pendingCard: UIView!
    @IBOutlet weak var inProgressCard: UIView!
    @IBOutlet weak var completedCard: UIView!
    @IBOutlet weak var StatusCard: UIView!
    @IBOutlet weak var taskListButton: UIButton!
    @IBOutlet weak var donutChartView: DonutChartViewTwo!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUIElements()
        
        setupChartData()
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
    
    func setupChartData() {
        guard let chart = donutChartView else { return }
        
        let colorCompleted = UIColor(red: 0.00, green: 0.42, blue: 0.85, alpha: 1.0)
        let colorInProgress = UIColor(red: 0.35, green: 0.67, blue: 0.93, alpha: 1.0)
        let colorPending = UIColor(red: 0.56, green: 0.62, blue: 0.67, alpha: 1.0)

        chart.segments = [
            DonutChartViewTwo.Segment(value: 749, color: colorCompleted),
            DonutChartViewTwo.Segment(value: 342, color: colorInProgress),
            DonutChartViewTwo.Segment(value: 156, color: colorPending)
        ]
        
        chart.backgroundColor = .clear
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
