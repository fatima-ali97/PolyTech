import UIKit

class OptionsPageViewController: UIViewController {

    @IBOutlet weak var newMaintenance: UIButton!
    
    @IBOutlet weak var returnInventory: UIButton!
    
    @IBOutlet weak var newInventory: UIButton!
    
    @IBOutlet weak var backBtn: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNewInventoryButton()
        setupNewMaintenanceButton()
        setupReturnInventoryButton()
        setupBackBtnButton()
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
    
    private func setupNewMaintenanceButton() {

        newMaintenance.isUserInteractionEnabled = true

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(newMaintenanceTapped))
        newMaintenance.addGestureRecognizer(tapGesture)
    }
    
    @objc func newMaintenanceTapped() {

        let storyboard = UIStoryboard(name: "NewMaintenance", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "NewMaintenanceViewController") as? NewMaintenanceViewController else {
            print("NewMaintenanceViewController not found in storyboard")
            return
        }
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func setupReturnInventoryButton() {

        returnInventory.isUserInteractionEnabled = true

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(returnInventoryTapped))
        returnInventory.addGestureRecognizer(tapGesture)
    }
    
    @objc func returnInventoryTapped() {

        let storyboard = UIStoryboard(name: "ReturnInventory", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "ReturnInventoryViewController") as? ReturnInventoryViewController else {
            print("ReturnInventoryViewController not found in storyboard")
            return
        }
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func setupBackBtnButton() {

        backBtn.isUserInteractionEnabled = true

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backBtnTapped))
        backBtn.addGestureRecognizer(tapGesture)
    }
    
    @objc func backBtnTapped() {

        let storyboard = UIStoryboard(name: "HomePage", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "HomeViewController") as? HomeViewController else {
            print("HomeViewController not found in storyboard")
            return
        }
        
        navigationController?.pushViewController(vc, animated: true)
    }

}
