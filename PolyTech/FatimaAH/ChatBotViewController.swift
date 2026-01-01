import UIKit

// MARK: - Message Model
// Represents one chat message (either from user or bot)
struct Message {
    let text: String      // Message text
    let isUser: Bool      // true = user message, false = bot message
}

// MARK: - ChatBot View Controller
final class ChatBotViewController: UIViewController {

    // MARK: - IBOutlets (UI elements from Storyboard)
    @IBOutlet weak var tableView: UITableView!          // Displays chat messages
    @IBOutlet weak var messageTextField: UITextField!   // Input field for user text
    @IBOutlet weak var sendButton: UIButton!            // Send message button
    @IBOutlet weak var inputContainerView: UIView!      // Bottom container (text field + send button)
    @IBOutlet weak var backButton: UIImageView!         // Back button (image)

    // MARK: - Data Source
    private var messages: [Message] = []                // All chat messages

    // MARK: - Main Menu Text (Bot welcome message)
    private var menuText: String {
        return """
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

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Chat Bot"

        // TableView setup
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .interactive
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.contentInsetAdjustmentBehavior = .never

        // TextField delegate
        messageTextField.delegate = self

        // Style input container
        inputContainerView.layer.cornerRadius = 16
        inputContainerView.clipsToBounds = true

        // Style send button
        sendButton.layer.cornerRadius = 10
        sendButton.clipsToBounds = true

        // Enable tap on back image
        setupBackImageTap()

        // Initial bot message (menu)
        messages = [Message(text: menuText, isUser: false)]
        reloadAndScrollToBottom()
    }

    // MARK: - Back Button (Image Tap)
    private func setupBackImageTap() {
        backButton.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(backImageTapped))
        backButton.addGestureRecognizer(tap)
    }

    // Action when back image is tapped
    @objc private func backImageTapped() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Send Button Action
    @IBAction func sendButtonTapped(_ sender: UIButton) {
        sendMessage()
    }

    // MARK: - Send Message Logic
    private func sendMessage() {
        let rawText = messageTextField.text ?? ""
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        // Add user message
        messages.append(Message(text: text, isUser: true))
        messageTextField.text = ""
        reloadAndScrollToBottom()

        // Get bot reply
        let reply = botReply(for: text)

        // Simulate typing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.messages.append(Message(text: reply, isUser: false))
            self.reloadAndScrollToBottom()
        }
    }

    // MARK: - Normalize Input
    // Cleans user input (lowercase, remove symbols)
    private func normalize(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()
        let cleaned = lower.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
        return cleaned
    }

    // MARK: - Bot Reply Logic
    private func botReply(for input: String) -> String {
        let normalized = normalize(input)

        // ✅ Use normalized for number detection so "7)", "7." etc still works
        if let choice = Int(normalized) {
            switch choice {

            case 0:
                return menuText

            case 1:
                return "Moodle login / access 📘\n1) Open Polytechnic website > Moodle\n2) Login with your username + password."

            case 2:
                return "Banner login 🧾\n1) Open Polytechnic website > Banner\n2) Enter Student ID + password."

            case 3:
                return "Reset password 🔐\nWhich account?\n1) Moodle\n2) Banner\n3) Email/Office\nReply: 3-1, 3-2, or 3-3"

            case 4:
                return "Wi-Fi / Internet 📶\n1) Turn Wi-Fi off/on\n2) Forget network & re-join\n3) Restart device."

            case 5:
                return "Contact IT / Get Help 🧑‍💻\nUse the Get Help page in the app."

            case 6:
                return "Technician availability 🛠️\nOpen Get Help and submit your issue with details + location."

            case 7:
                return "Email setup ✉️\nTry logging in via browser first. If it fails, reset or contact IT."

            case 8:
                return "Microsoft Teams / Office 365 💼\nSign out/in, update the app, or reinstall if stuck."

            case 9:
                return "Authenticator / 2FA 🔑\nSet phone time to Automatic and re-add the account if approvals fail."

            case 10:
                return "VPN 🌍\nCheck internet, re-enter credentials, try another network, restart VPN app."

            case 11:
                return "Printing 🖨️\nBe on campus Wi-Fi, pick correct printer, try a small test page."

            case 12:
                return "Library / eResources 📚\nTry on campus first, off campus may need VPN (reply 10)."

            case 13:
                return "Attendance / Registration 📝\nCheck Banner registration and send course code + error if any."

            case 14:
                return "Laptop / Software 💻\nKeep storage free, update OS, install required apps (Teams/Office)."

            case 15:
                return "VM / VMware 🧩\nRestart laptop, update VMware, check VM folder path, share exact error."

            default:
                return "I don’t have that option. Type 0 to see the menu."
            }
        }

        // Special reset choices like 3-1, 3-2, 3-3 -> normalized becomes "31" "32" "33"
        if normalized == "31" { return "Moodle reset 🔐\nUse “Forgot password?” on Moodle login page." }
        if normalized == "32" { return "Banner reset 🔐\nBanner resets are usually handled by IT. Reply 5." }
        if normalized == "33" { return "Email reset 🔐\nUse Microsoft “Forgot password?” or reply 5 for IT." }

        // Keyword-based fallback replies
        if normalized.contains("menu") { return menuText }
        if normalized.contains("moodle") { return "Reply 1 for Moodle help. Type 0 for menu." }
        if normalized.contains("banner") { return "Reply 2 for Banner help. Type 0 for menu." }
        if normalized.contains("password") { return "Reply 3 to reset password. Type 0 for menu." }
        if normalized.contains("wifi") { return "Reply 4 for Wi-Fi help. Type 0 for menu." }

        return "Reply with a number (0–15) so I can help you faster. Type 0 to see the menu."
    }

    // MARK: - Reload & Scroll
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
