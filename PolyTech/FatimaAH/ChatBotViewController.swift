import UIKit

struct Message {
    let text: String
    let isUser: Bool
}

class ChatBotViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var inputContainerView: UIView!
    @IBOutlet weak var backButton: UIImageView!

    private var messages: [Message] = []

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

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Chat Bot"

        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .interactive
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.contentInsetAdjustmentBehavior = .never

        messageTextField.delegate = self

        inputContainerView.layer.cornerRadius = 16
        inputContainerView.clipsToBounds = true

        sendButton.layer.cornerRadius = 10
        sendButton.clipsToBounds = true

        setupBackImageTap()

        messages = [Message(text: menuText, isUser: false)]
        reloadAndScrollToBottom()
    }

    private func setupBackImageTap() {
        backButton.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(backImageTapped))
        backButton.addGestureRecognizer(tap)
    }

    @objc private func backImageTapped() {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func sendButtonTapped(_ sender: UIButton) {
        sendMessage()
    }

    private func sendMessage() {
        let rawText = messageTextField.text ?? ""
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        messages.append(Message(text: text, isUser: true))
        messageTextField.text = ""
        reloadAndScrollToBottom()

        let reply = botReply(for: text)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.messages.append(Message(text: reply, isUser: false))
            self.reloadAndScrollToBottom()
        }
    }

    private func normalize(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()
        let cleaned = lower.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
        return cleaned
    }

    private func botReply(for input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = normalize(input)

        if let choice = Int(trimmed) {
            switch choice {

            case 0:
                return menuText

            case 1:
                return """
                Moodle login / access 📘
                1) Open Bahrain Polytechnic website.
                2) Scroll down and tap Moodle.
                3) Choose Student login.
                4) Enter your username + password.

                If you can’t login:
                • Try another browser (Safari/Chrome)
                • Clear cache and try again
                • If password is wrong, reply 3 (Reset password)
                """

            case 2:
                return """
                Banner login 🧾
                1) Open Bahrain Polytechnic website.
                2) Tap Banner.
                3) Enter your Student ID + password.

                If it says wrong password:
                • Reply 3 (Reset password)
                • Check Caps Lock and try again
                """

            case 3:
                return """
                Reset password 🔐
                Which account do you want to reset?

                1) Moodle
                2) Banner
                3) Email / Office 365

                Reply with: 3-1, 3-2, or 3-3
                """

            case 4:
                return """
                Wi-Fi / Internet 📶
                Try this order:
                1) Turn Wi-Fi off/on.
                2) Forget the network then re-join.
                3) Restart your phone/laptop.
                4) If it still doesn’t work, try another device.

                Tell me your device: iPhone / Android / Laptop
                """

            case 5:
                return """
                Contact IT / Get Help 🧑‍💻
                Use the Get Help page in the app.

                To help you faster, send:
                • Topic (Moodle/Banner/Wi-Fi/etc.)
                • Your device (iPhone/Android/Laptop)
                • Screenshot or exact error message
                """

            case 6:
                return """
                Technician availability 🛠️
                1) Open Get Help in the app.
                2) Choose your issue type (Wi-Fi / Banner / Moodle / Device).
                3) Add details + screenshots.
                4) Submit the request.

                Tip: Add your Student ID and the location (building/room) if on campus.
                """

            case 7:
                return """
                Email (Polytechnic email setup) ✉️
                If you can’t login:
                1) Try signing in on a browser first.
                2) Check your email format and password.
                3) If it fails, reply 3-3 to reset Email/Office.

                iPhone setup:
                • Add Account > Microsoft Exchange
                • Sign in with your Polytechnic email
                """

            case 8:
                return """
                Microsoft Teams / Office 365 💼
                Common fixes:
                1) Sign out then sign in again.
                2) Update Teams.
                3) If stuck on loading, reinstall Teams.
                4) Try logging in from a browser.

                Tell me your device and what error you see.
                """

            case 9:
                return """
                Two-Factor Authentication (Authenticator) 🔑
                If codes/approvals don’t work:
                1) Set phone time to Automatic.
                2) Make sure you selected the correct account.
                3) Remove the account from Authenticator and add it again.

                Tell me: iPhone or Android?
                """

            case 10:
                return """
                VPN (off-campus access) 🌍
                If VPN won’t connect:
                1) Make sure your internet works normally.
                2) Re-enter your username/password carefully.
                3) Try switching networks (Wi-Fi ↔︎ mobile hotspot).
                4) Restart the VPN app.

                Tell me your device: Windows / Mac / iPhone / Android
                """

            case 11:
                return """
                Printing / printers on campus 🖨️
                If printing doesn’t work:
                1) Make sure you are connected to campus Wi-Fi.
                2) Select the correct printer.
                3) Try printing a small PDF test page.
                4) If it queues forever, cancel and try again.

                Tell me which building/printer area you’re using.
                """

            case 12:
                return """
                Library access / eResources 📚
                If a database won’t open:
                1) Try on campus Wi-Fi first.
                2) If off campus, you may need VPN (reply 10).
                3) Try another browser or clear cache.

                Tell me the website/resource name you’re trying to access.
                """

            case 13:
                return """
                Attendance / course registration 📝
                If your course is missing:
                1) Check Banner registration status.
                2) Log out and log in again.
                3) Wait a few hours after timetable updates.

                If you have a registration error:
                • Send the course code + error message
                """

            case 14:
                return """
                Laptop / software requirements 💻
                General tips:
                1) Keep at least 20–30GB free storage.
                2) Update your OS.
                3) Install required apps: Teams, Office, course software.

                Tell me: Mac/Windows and your RAM (8GB/16GB).
                """

            case 15:
                return """
                VM / VMware problems 🧩
                If your VM won’t start:
                1) Restart your laptop.
                2) Ensure VMware is up to date.
                3) Check the VM folder path is correct.
                4) If “locked” error: close VMware, end tasks, reopen.

                Tell me the exact error message.
                """

            default:
                return "I don’t have that option. Type 0 to see the menu."
            }
        }

        if normalized == "31" {
            return """
            Moodle reset 🔐
            1) Open Moodle login page.
            2) Tap “Forgot password?”.
            3) Enter your username/email.
            4) Check your email and open the reset link.

            If no email arrives, reply 5 (Contact IT).
            """
        }

        if normalized == "32" {
            return """
            Banner reset 🔐
            Banner password resets are usually handled by IT.
            Reply 5 (Contact IT) and include:
            • Student ID
            • The error message / screenshot
            """
        }

        if normalized == "33" {
            return """
            Email / Office 365 reset 🔐
            1) Go to Microsoft sign-in page.
            2) Tap “Forgot password?”.
            3) Follow the steps and verify your identity.

            If you can’t reset, reply 5 (Contact IT).
            """
        }

        if normalized.contains("menu") || normalized.contains("options") {
            return menuText
        }

        if normalized.contains("moodle") { return "For Moodle help, reply 1. Type 0 to see all options." }
        if normalized.contains("banner") { return "For Banner help, reply 2. Type 0 to see all options." }
        if normalized.contains("password") || normalized.contains("reset") || normalized.contains("forgot") { return "For password reset, reply 3. Type 0 to see all options." }
        if normalized.contains("wifi") || normalized.contains("internet") || normalized.contains("network") { return "For Wi-Fi help, reply 4. Type 0 to see all options." }
        if normalized.contains("help") || normalized.contains("support") || normalized.contains("it") { return "To contact IT / Get Help, reply 5. Type 0 to see all options." }
        if normalized.contains("technician") { return "For technician availability, reply 6. Type 0 to see all options." }
        if normalized.contains("email") { return "For email setup help, reply 7. Type 0 to see all options." }
        if normalized.contains("teams") || normalized.contains("office") { return "For Teams/Office 365 help, reply 8. Type 0 to see all options." }
        if normalized.contains("auth") || normalized.contains("2fa") || normalized.contains("authenticator") { return "For Authenticator/2FA help, reply 9. Type 0 to see all options." }
        if normalized.contains("vpn") { return "For VPN help, reply 10. Type 0 to see all options." }
        if normalized.contains("print") { return "For printing help, reply 11. Type 0 to see all options." }
        if normalized.contains("library") { return "For library help, reply 12. Type 0 to see all options." }
        if normalized.contains("attendance") || normalized.contains("register") || normalized.contains("registration") { return "For attendance/registration help, reply 13. Type 0 to see all options." }
        if normalized.contains("laptop") || normalized.contains("software") { return "For laptop/software requirements, reply 14. Type 0 to see all options." }
        if normalized.contains("vm") || normalized.contains("vmware") { return "For VM/VMware help, reply 15. Type 0 to see all options." }
        if normalized.contains("hello") || normalized.contains("hi") || normalized.contains("hey") { return menuText }

        return "Reply with a number (0–15) so I can help you faster. Type 0 to see the menu."
    }

    private func reloadAndScrollToBottom() {
        tableView.reloadData()
        guard !messages.isEmpty else { return }
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
}

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
        cell.backgroundColor = .clear

        return cell
    }
}

extension ChatBotViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendMessage()
        return true
    }
}
