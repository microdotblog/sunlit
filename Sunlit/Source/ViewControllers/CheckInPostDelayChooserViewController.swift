import UIKit

final class CheckInPostDelayChooserViewController: UITableViewController {
    private let delays = CheckInPostDelay.allCases
    private let onSelection: (CheckInPostDelay) -> Void
    private let cellIdentifier = "DelayCell"

    static func present(from viewController: UIViewController, onSelection: @escaping (CheckInPostDelay) -> Void) {
        let chooser = CheckInPostDelayChooserViewController(onSelection: onSelection)
        let navigationController = UINavigationController(rootViewController: chooser)
        navigationController.modalPresentationStyle = .pageSheet
        navigationController.preferredContentSize = CGSize(width: 420, height: 520)

        if let sheet = navigationController.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = false
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            sheet.preferredCornerRadius = 24
        }

        viewController.present(navigationController, animated: true)
    }

    init(onSelection: @escaping (CheckInPostDelay) -> Void) {
        self.onSelection = onSelection
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Schedule Check-ins"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(onClose))
        self.navigationItem.leftBarButtonItem?.accessibilityLabel = "Close"
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: self.cellIdentifier)
        self.tableView.rowHeight = 52
        self.tableView.sectionHeaderTopPadding = 8
        self.tableView.sectionHeaderHeight = .leastNormalMagnitude
        self.tableView.estimatedSectionHeaderHeight = 0
        self.tableView.contentInset.top = -24
        self.tableView.backgroundColor = .systemGroupedBackground
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { self.delays.count }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.cellIdentifier, for: indexPath)
        let delay = self.delays[indexPath.row]
        cell.textLabel?.text = delay.title
        cell.textLabel?.font = .preferredFont(forTextStyle: .body)
        cell.textLabel?.textColor = .label
        cell.accessoryType = delay == CheckInPostDelay.selected ? .checkmark : .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let delay = self.delays[indexPath.row]
        CheckInPostDelay.selected = delay
        self.onSelection(delay)
        self.dismiss(animated: true)
    }

    @objc private func onClose() { self.dismiss(animated: true) }
}
