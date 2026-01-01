import UIKit

class HelpPageViewController: UIViewController {

    // MARK: - IBOutlets (Labels)
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var instagramLabel: UILabel!
    @IBOutlet weak var linkedinLabel: UILabel!
    @IBOutlet weak var tiktokLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupBackButton()
        setupTapGestures()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Back Button
    private func setupBackButton() {
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(goBack)
        )
        backButton.tintColor = .background
        navigationItem.leftBarButtonItem = backButton
    }

    @objc private func goBack() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Tap Gestures
    private func setupTapGestures() {
        makeLabelTappable(emailLabel, action: #selector(emailTapped))
        makeLabelTappable(phoneLabel, action: #selector(phoneTapped))
        makeLabelTappable(instagramLabel, action: #selector(instagramTapped))
        makeLabelTappable(linkedinLabel, action: #selector(linkedinTapped))
        makeLabelTappable(tiktokLabel, action: #selector(tiktokTapped))
    }

    private func makeLabelTappable(_ label: UILabel, action: Selector) {
        label.isUserInteractionEnabled = true
        label.textColor = .systemBlue
        let tap = UITapGestureRecognizer(target: self, action: action)
        label.addGestureRecognizer(tap)
    }

    // MARK: - Actions
    @objc private func emailTapped() {
        openIfPossible(
            urlString: "mailto:communications@polytechnic.bh",
            fallbackText: "communications@polytechnic.bh"
        )
    }

    @objc private func phoneTapped() {
        openIfPossible(
            urlString: "tel://+97317897000",
            fallbackText: "+973 1789 7000"
        )
    }

    @objc private func instagramTapped() {
        let appURL = URL(string: "instagram://user?username=bahrainpolytechnic")!
        let webURL = URL(string: "https://instagram.com/bahrainpolytechnic")!

        if UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else {
            UIApplication.shared.open(webURL)
        }
    }

    @objc private func linkedinTapped() {
        openWeb("https://www.linkedin.com/school/bahrain-polytechnic")
    }

    @objc private func tiktokTapped() {
        openWeb("https://www.tiktok.com/@bahrainpolytechnic")
    }

    // MARK: - Helpers
    private func openIfPossible(urlString: String, fallbackText: String) {
        guard let url = URL(string: urlString) else { return }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:])
        } else {
            copyFallback(text: fallbackText)
        }
    }

    private func openWeb(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url, options: [:])
    }

    private func copyFallback(text: String) {
        UIPasteboard.general.string = text

        let alert = UIAlertController(
            title: "Copied",
            message: "\(text) has been copied.\nYou can paste it manually.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
