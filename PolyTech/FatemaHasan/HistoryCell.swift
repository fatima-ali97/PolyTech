import UIKit

class HistoryCell: UITableViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var requestLabel: UILabel!
    @IBOutlet weak var detailsButton: UIButton!
    @IBOutlet weak var feedbackButton: UIButton!

    var onDetailsTapped: (() -> Void)?
    var onFeedbackTapped: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        containerView.layer.cornerRadius = 12
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.1
        containerView.layer.shadowRadius = 4
        containerView.layer.shadowOffset = .zero
    }

    @IBAction func detailsPressed(_ sender: UIButton) {
        onDetailsTapped?()
    }

    @IBAction func feedbackPressed(_ sender: UIButton) {
        onFeedbackTapped?()
    }
}
