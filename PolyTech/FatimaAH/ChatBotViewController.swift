import UIKit

// MARK: - Message Model
struct Message {
    let text: String
    let isUser: Bool
}

// MARK: - ChatBot View Controller
class ChatBotViewController: UIViewController {

    // MARK: UI Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var inputContainerView: UIView!

    // MARK: Data
    private var messages: [Message] = []

    // MARK: Menu Text
    private var menuText: String {
        """
        Hi 👋 I can help with these topics. Reply with a number:

        1) Moodle login / access
        2) Banner login
        3) Reset password
        4) Wi-Fi / Internet on campus
        5) Contact IT / Get Help

        6) Technician availability
        7) Email (Polytechnic email setup)
        8) Microsoft Teams / Office 365
        9) Two-Factor Authentication (Authenticator)
        10) VPN (off-campus access)

        11) Printing / printers on campus
        12) Library access / eResources
        13) Attendance / course registration help
        14) Laptop / software requirements
        15) VM / VMware problems

        Type 0 to see this menu again.
        """
    }

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Chat Bot"

        setupTableView()
        setupInputUI()
        setupNavigationBackButton()

        // Initial bot message (menu)
        messages = [Message(text: menuText, isUser: false)]
        reloadAndScrollToBottom()

        // Listen to keyboard "return" on the textfield
        messageTextField.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: Table Setup
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self

        tableView.keyboardDismissMode = .interactive
        tableView.separatorStyle = .none

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = UITableView.automaticDimension

        tableView.contentInsetAdjustmentBehavior = .never
    }

    // MARK: Input UI Setup
    private func setupInputUI() {
        inputContainerView.layer.cornerRadius = 16
        inputContainerView.clipsToBounds = true

        sendButton.layer.cornerRadius = 10
        sendButton.clipsToBounds = true
    }

    // MARK: Navigation Back Button
    private func setupNavigationBackButton() {
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(goBack)
        )
        backButton.tintColor = .onBackground
        navigationItem.leftBarButtonItem = backButton
    }

    @objc private func goBack() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: Actions
    @IBAction func sendButtonTapped(_ sender: UIButton) {
        sendMessage()
    }

    // MARK: Send / Receive
    private func sendMessage() {
        let rawText = messageTextField.text ?? ""
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        // Add user message
        messages.append(Message(text: text, isUser: true))
        messageTextField.text = ""
        reloadAndScrollToBottom()

        // Generate bot reply
        let reply = botReply(for: text)

        // Add bot message after a short delay (feels more natural)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.messages.append(Message(text: reply, isUser: false))
            self.reloadAndScrollToBottom()
        }
    }

    // MARK: Input Cleaning
    private func normalize(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()
        let cleaned = lower.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
        return cleaned
    }

    // MARK: Bot Logic
    private func botReply(for input: String) -> String {
        let normalized = normalize(input)

        // Greetings
        let greetings = ["hi", "hello", "hey", "goodmorning", "goodafternoon", "goodevening"]
        if greetings.contains(normalized) {
            return "Hello! 👋 How can I help you today? Type 0 to see the menu."
        }

        // Menu choices (numbers)
        if let choice = Int(normalized) {
            switch choice {
            case 0: return menuText
            case 1: return "Moodle login 📘\n1) Go to Moodle on the Polytechnic website\n2) Login with username + password"
            case 2: return "Banner login 🧾\nOpen Banner and enter your Student ID + password"
            case 3: return "Reset password 🔐\nWhich account? Reply 3-1 (Moodle), 3-2 (Banner), 3-3 (Email/Office)"
            case 4: return "Wi-Fi / Internet 📶\nTry turning Wi-Fi off/on, forget & rejoin network, or restart your device"
            case 5: return "Contact IT 🧑‍💻\nUse the 'Get Help' page in the app to submit your request"
            case 6: return "Technician availability 🛠️\nSubmit your issue + location via 'Get Help'"
            case 7: return "Email setup ✉️\nTry logging in via browser first. Reset password or contact IT if needed"
            case 8: return "Microsoft Teams / Office 365 💼\nSign out/in, update, or reinstall the app"
            case 9: return "Two-Factor Authentication 🔑\nSet phone time to Automatic and re-add the account if approvals fail"
            case 10: return "VPN 🌍\nCheck internet, re-enter credentials, or restart VPN app"
            case 11: return "Printing 🖨️\nUse campus Wi-Fi, select correct printer, try a small test page"
            case 12: return "Library / eResources 📚\nOn-campus works automatically. Off-campus may need VPN (reply 10)"
            case 13: return "Attendance / Registration 📝\nCheck Banner registration. Send course code + error if any"
            case 14: return "Laptop / Software 💻\nFree storage, update OS, install required apps"
            case 15: return "VM / VMware 🧩\nRestart laptop, update VMware, check VM folder path, share exact error"
            default: return "I don’t have that option. Type 0 to see the menu."
            }
        }

        // Reset options (3-1 / 3-2 / 3-3)
        switch normalized {
        case "31": return "Moodle reset 🔐\nUse 'Forgot password?' on Moodle login page"
        case "32": return "Banner reset 🔐\nBanner resets are handled by IT. Reply 5 to contact IT"
        case "33": return "Email reset 🔐\nUse Microsoft 'Forgot password?' or contact IT (reply 5)"
        default: break
        }

        // Keywords
        if normalized.contains("help") { return "Sure! What do you need help with? Type 0 to see the menu." }
        if normalized.contains("thanks") || normalized.contains("thankyou") { return "You're welcome! 😊 Anything else I can help with?" }
        if normalized.contains("moodle") { return "Reply 1 for Moodle help. Type 0 for menu." }
        if normalized.contains("banner") { return "Reply 2 for Banner help. Type 0 for menu." }
        if normalized.contains("password") { return "Reply 3 to reset password. Type 0 for menu." }
        if normalized.contains("wifi") { return "Reply 4 for Wi-Fi help. Type 0 for menu." }

        // Small talk
        if normalized.contains("howareyou") { return "I'm just a bot 🤖, but I'm here to help you! How can I assist today?" }
        if normalized.contains("good") { return "Glad to hear that! 😊 What can I help you with today?" }
        if normalized.contains("problem") || normalized.contains("issue") {
            return "I'm sorry to hear that 😔 Can you tell me which system it relates to? (Moodle, Banner, Wi-Fi, etc.)"
        }

        // Fallback
        return "I'm not sure I understand. 🤔 Reply with a number (0–15) or type a keyword like 'Moodle', 'Wi-Fi', or 'help'."
    }

    // MARK: UI Helpers
    private func reloadAndScrollToBottom() {
        tableView.reloadData()
        guard !messages.isEmpty else { return }
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
}

// MARK: - TableView DataSource & Delegate
extension ChatBotViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath)
        let msg = messages[indexPath.row]

        cell.textLabel?.text = msg.text
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.textAlignment = msg.isUser ? .right : .left
        cell.selectionStyle = .none
        cell.backgroundColor = .background

        return cell
    }
}

// MARK: - TextField Delegate
extension ChatBotViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendMessage()
        return true
    }
}
