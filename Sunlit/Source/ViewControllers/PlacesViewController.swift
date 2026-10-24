import UIKit

final class PlacesViewController: ContentViewController, UITableViewDataSource {
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let refreshControl = UIRefreshControl()
    private let statusLabel = UILabel()
    private var dataSource: PlacesDataSource
    private var checkIns: [SunlitCheckIn] = []
    private var loadGeneration = 0
    private weak var hostNavigationItem: UINavigationItem?
    private var previousRightButton: UIBarButtonItem?

    init(dataSource: PlacesDataSource = makePlacesDataSource()) {
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.dataSource = self
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 148
        self.tableView.separatorInset = .zero
        self.tableView.separatorInsetReference = .fromCellEdges
        self.tableView.register(PlaceCheckInTableViewCell.self, forCellReuseIdentifier: PlaceCheckInTableViewCell.reuseIdentifier)
        self.refreshControl.addTarget(self, action: #selector(loadCheckIns), for: .valueChanged)
        self.tableView.refreshControl = self.refreshControl
        self.statusLabel.textAlignment = .center
        self.statusLabel.textColor = .secondaryLabel
        self.statusLabel.font = .preferredFont(forTextStyle: .body)
        self.statusLabel.adjustsFontForContentSizeCategory = true
        self.statusLabel.numberOfLines = 0
        self.tableView.backgroundView = self.statusLabel
        if self.dataSource.isPreview {
            let header = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 44))
            header.text = "Preview check-ins · Sample data"
            header.font = .preferredFont(forTextStyle: .footnote)
            header.textColor = .secondaryLabel
            header.textAlignment = .center
            self.tableView.tableHeaderView = header
        }
        self.view.addSubview(self.tableView)
        NSLayoutConstraint.activate([
            self.tableView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
            self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
    }

    override func navbarTitle() -> String { "Places" }

    override func setupNavigation() {
        super.setupNavigation()
        if let item = self.navigationController?.navigationBar.topItem {
            if self.hostNavigationItem == nil {
                self.previousRightButton = item.rightBarButtonItem
            }
            self.hostNavigationItem = item
            let button = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newCheckIn))
            button.accessibilityLabel = "New Check-in"
            item.rightBarButtonItem = button
        }
    }

    override func prepareToDisplay() {
        super.prepareToDisplay()
        self.loadCheckIns()
    }

    override func prepareToHide() {
        super.prepareToHide()
        self.hostNavigationItem?.rightBarButtonItem = self.previousRightButton
        self.hostNavigationItem = nil
        self.previousRightButton = nil
    }

    override func handleScrollToTopGesture() {
        self.tableView.setContentOffset(CGPoint(x: 0, y: -self.tableView.adjustedContentInset.top), animated: true)
    }

    @objc private func loadCheckIns() {
        self.loadGeneration += 1
        let generation = self.loadGeneration
        self.statusLabel.text = self.checkIns.isEmpty ? "Loading check-ins…" : nil
        self.dataSource.fetchCheckIns { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self, generation == self.loadGeneration else { return }
                self.refreshControl.endRefreshing()
                switch result {
                case .success(let checkIns):
                    self.checkIns = checkIns.sorted { $0.date > $1.date }
                    self.statusLabel.text = checkIns.isEmpty ? "No check-ins yet.\nTap + to add your first place." : nil
                    self.tableView.reloadData()
                case .failure(let error):
                    self.statusLabel.text = self.checkIns.isEmpty ? error.localizedDescription : nil
                    if !self.checkIns.isEmpty { Dialog(self).information(error.localizedDescription) }
                }
            }
        }
    }

    func resetForLogout() {
        self.loadGeneration += 1
        self.checkIns = []
        self.dataSource = makePlacesDataSource()
        if self.isViewLoaded {
            self.refreshControl.endRefreshing()
            self.statusLabel.text = nil
            self.tableView.reloadData()
            self.dismiss(animated: false)
        }
    }

    @objc private func newCheckIn() {
        let accountGeneration = Settings.accountGeneration
        let composer = CheckInViewController(dataSource: self.dataSource) { [weak self] in
            guard accountGeneration == Settings.accountGeneration else { return }
            self?.loadCheckIns()
        }
        self.present(UINavigationController(rootViewController: composer), animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { self.checkIns.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PlaceCheckInTableViewCell.reuseIdentifier, for: indexPath) as! PlaceCheckInTableViewCell
        cell.configure(with: self.checkIns[indexPath.row])
        return cell
    }
}
