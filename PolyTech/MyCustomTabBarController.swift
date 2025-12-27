import UIKit

// MARK: - Tab Bar Controller Protocol
protocol TabBarControllerProtocol: UITabBarController {
    func didTapTabBarButton(_ index: Int)
}

extension TabBarControllerProtocol {
    func didTapTabBarButton(_ index: Int) {
        selectedIndex = index
    }
}

// MARK: - Custom Tab Bar Controller
class CustomTabBarController: UITabBarController, TabBarControllerProtocol {
    
    private var customTabBarView: TabBarView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewControllers()
        setupCustomTabBar()
    }
    
    private func setupViewControllers() {
        let homeVC = createNavControllerFromStoryboard(
            storyboardName: "Main", // add the HomePage storyboard
            title: "Home",
            image: UIImage(systemName: "house.fill")
        )
        
        let maintenanceVC = createNavControllerFromStoryboard(
            storyboardName: "Maintenance",
            title: "Maintenance",
            image: UIImage(systemName: "wrench.and.screwdriver.fill")
        )
        
        let inventoryVC = createNavControllerFromStoryboard(
            storyboardName: "InvStoryboard",
            title: "Inventory",
            image: UIImage(systemName: "shippingbox.fill")
        )
        
        let profileVC = createNavControllerFromStoryboard(
            storyboardName: "Profile",
            title: "Profile",
            image: UIImage(systemName: "person.fill")
        )
        
        viewControllers = [homeVC, maintenanceVC, inventoryVC, profileVC]
    }
    
    private func createNavControllerFromStoryboard(storyboardName: String, title: String, image: UIImage?) -> UINavigationController {
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        
        guard let viewController = storyboard.instantiateInitialViewController() else {
            fatalError("Cannot instantiate initial view controller from \(storyboardName) storyboard. Make sure 'Is Initial View Controller' is checked.")
        }
        
        if let navController = viewController as? UINavigationController {
            navController.tabBarItem.title = title
            navController.tabBarItem.image = image
            return navController
        } else {
            let navController = UINavigationController(rootViewController: viewController)
            navController.tabBarItem.title = title
            navController.tabBarItem.image = image
            return navController
        }
    }
    
    private func setupCustomTabBar() {
        tabBar.isHidden = true
        
        customTabBarView = TabBarView()
        customTabBarView.translatesAutoresizingMaskIntoConstraints = false
        customTabBarView.tabBarController = self
        view.addSubview(customTabBarView)
        
        NSLayoutConstraint.activate([
            customTabBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customTabBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customTabBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            customTabBarView.heightAnchor.constraint(equalToConstant: 83 + view.safeAreaInsets.bottom)
        ])
        
        if let items = viewControllers?.compactMap({ $0.tabBarItem }) {
            customTabBarView.setup(with: items)
        }
    }
}

// MARK: - Tab Bar View
class TabBarView: UIView {
    
    weak var tabBarController: TabBarControllerProtocol?
    
    private var buttons: [TabBarButton] = []
    private let movingLayer = CALayer()
    private let spacing: CGFloat = 8
    private let padding: CGFloat = 16
    private let selectedButtonWidth: CGFloat = 100
    private let buttonHeight: CGFloat = 48
    
    private let primaryColor = UIColor(red: 254/255, green: 152/255, blue: 155/255, alpha: 1.0)
    //private let backgroundColor = UIColor.systemBackground
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        self.backgroundColor = backgroundColor
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: -2)
        layer.shadowRadius = 8
        
        movingLayer.cornerRadius = buttonHeight / 2
        movingLayer.backgroundColor = primaryColor.cgColor
        layer.addSublayer(movingLayer)
    }
    
    func setup(with items: [UITabBarItem]) {
        buttons.forEach { $0.removeFromSuperview() }
        buttons.removeAll()
        
        for (index, item) in items.enumerated() {
            let button = TabBarButton()
            button.setup(with: item, index: index)
            button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
            addSubview(button)
            buttons.append(button)
        }
        
        selectButton(at: 0)
    }
    
    @objc private func buttonTapped(_ sender: TabBarButton) {
        guard let index = buttons.firstIndex(of: sender) else { return }
        selectButton(at: index)
        tabBarController?.didTapTabBarButton(index)
    }
    
    private func selectButton(at index: Int) {
        for (i, button) in buttons.enumerated() {
            button.isSelected = (i == index)
        }
        setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let selectedIndex = buttons.firstIndex(where: { $0.isSelected }) ?? 0
        let unselectedButtonCount = CGFloat(buttons.count - 1)
        let availableWidth = bounds.width - (2 * padding) - selectedButtonWidth - (CGFloat(buttons.count - 1) * spacing)
        let unselectedButtonWidth = availableWidth / unselectedButtonCount
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut) {
            var xPosition = self.padding
            
            for (index, button) in self.buttons.enumerated() {
                let width = button.isSelected ? self.selectedButtonWidth : unselectedButtonWidth
                let buttonFrame = CGRect(x: xPosition, y: 16, width: width, height: self.buttonHeight)
                button.frame = buttonFrame
                
                if button.isSelected {
                    self.movingLayer.frame = buttonFrame
                }
                
                xPosition += width + self.spacing
            }
        }
    }
}

// MARK: - Tab Bar Button
class TabBarButton: UIButton {
    
    private let iconImageView = UIImageView()
    private let customTitleLabel = UILabel()
    private var tabBarItem: UITabBarItem?
    
    override var isSelected: Bool {
        didSet {
            updateAppearance()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }
    
    private func setupButton() {
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconImageView)
        
        customTitleLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        customTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(customTitleLabel)
        
        NSLayoutConstraint.activate([
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            customTitleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            customTitleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            customTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -12)
        ])
    }
    
    func setup(with item: UITabBarItem, index: Int) {
        self.tabBarItem = item
        iconImageView.image = item.image?.withRenderingMode(.alwaysTemplate)
        customTitleLabel.text = item.title
        updateAppearance()
    }
    
    private func updateAppearance() {
        UIView.animate(withDuration: 0.3) {
            if self.isSelected {
                self.iconImageView.tintColor = .white
                self.customTitleLabel.textColor = .white
                self.customTitleLabel.alpha = 1.0
            } else {
                self.iconImageView.tintColor = .systemGray
                self.customTitleLabel.textColor = .systemGray
                self.customTitleLabel.alpha = 0.0
            }
        }
    }
}

// MARK: - UIColor Extension
extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
