import UIKit

class OptionsPageViewController: UIViewController {

    @IBOutlet weak var newMaintenance: UIButton!
    
    @IBOutlet weak var returnInventory: UIButton!
    
    @IBOutlet weak var newInventory: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNewInventoryButton()

    }
    
    private func setupNewInventoryButton() {

        newInventory.isUserInteractionEnabled = true

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(newInventoryTapped))
        newInventory.addGestureRecognizer(tapGesture)
    }
    
    @objc func newInventoryTapped() {

        let storyboard = UIStoryboard(name: "NewInventory", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "NewInventoryViewController") as? NewInventoryViewController else {
            print("NewInventoryViewController not found in storyboard")
            return
        }
        
        navigationController?.pushViewController(vc, animated: true)
    }

}
