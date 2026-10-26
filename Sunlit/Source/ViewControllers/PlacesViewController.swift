import UIKit

private final class PlacesTableView: UITableView {
    private let rowSeparators = PlacesRowSeparatorsView()

    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        self.separatorStyle = .none
        self.addSubview(self.rowSeparators)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Keep separators outside the cells that UIKit moves during a swipe.
        self.rowSeparators.frame = self.bounds
        self.rowSeparators.rowBottoms = (self.indexPathsForVisibleRows ?? []).map {
            self.rectForRow(at: $0).maxY - self.bounds.minY
        }
        self.rowSeparators.separatorColor = self.separatorColor ?? .separator
        self.rowSeparators.setNeedsDisplay()
        self.bringSubviewToFront(self.rowSeparators)
    }
}

private final class PlacesRowSeparatorsView: UIView {
    var rowBottoms: [CGFloat] = []
    var separatorColor: UIColor = .separator

    init() {
        super.init(frame: .zero)
        self.backgroundColor = .clear
        self.isOpaque = false
        self.isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draw(_ rect: CGRect) {
        let scale = max(self.traitCollection.displayScale, 1)
        let lineHeight = 1 / scale
        self.separatorColor.setFill()
        for bottom in self.rowBottoms {
            let y = (bottom * scale).rounded() / scale - lineHeight
            UIRectFill(CGRect(x: 0, y: y, width: self.bounds.width, height: lineHeight))
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.setNeedsDisplay()
    }
}

final class PlacesViewController: ContentViewController, UITableViewDataSource, UITableViewDelegate {
    private struct DeletionKey: Hashable {
        let blogName: String
        let identifier: String
    }

    private let tableView = PlacesTableView(frame: .zero, style: .plain)
    private let refreshControl = UIRefreshControl()
    private let busyIndicator = UIActivityIndicatorView(style: .large)
    private let statusLabel = UILabel()
    private var dataSource: PlacesDataSource
    private var checkIns: [SunlitCheckIn] = []
    private var loadGeneration = 0
    private var loadedBlogName: String?
    private var deletingCheckIns = Set<DeletionKey>()
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
        self.tableView.delegate = self
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 148
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
        self.busyIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.busyIndicator.hidesWhenStopped = true
        self.busyIndicator.accessibilityLabel = "Loading check-ins"
        self.view.addSubview(self.busyIndicator)
        NSLayoutConstraint.activate([
            self.tableView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
            self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.busyIndicator.centerXAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor),
            self.busyIndicator.centerYAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerYAnchor)
        ])
    }

    override func navbarTitle() -> String { "Places" }

    override func setupNotifications() {
        super.setupNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(loadCheckIns), name: BlogSettings.checkInBlogChangedNotification, object: nil)
    }

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
        self.fetchCheckIns(limit: 500)
    }

    private func fetchCheckIns(limit: Int, merging: Bool = false) {
        let blogName = BlogSettings.blogForCheckIns().blogName
        let accountGeneration = Settings.accountGeneration
        if self.loadedBlogName != blogName {
            self.checkIns = []
            self.loadedBlogName = blogName
            self.tableView.reloadData()
        }
        self.loadGeneration += 1
        let generation = self.loadGeneration
        self.statusLabel.text = nil
        if self.checkIns.isEmpty && !self.refreshControl.isRefreshing {
            self.busyIndicator.startAnimating()
        } else {
            self.busyIndicator.stopAnimating()
        }
        self.dataSource.fetchCheckIns(limit: limit) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self, generation == self.loadGeneration,
                      accountGeneration == Settings.accountGeneration,
                      blogName == BlogSettings.blogForCheckIns().blogName else { return }
                self.refreshControl.endRefreshing()
                self.busyIndicator.stopAnimating()
                switch result {
                case .success(let checkIns):
                    if merging {
                        let refreshedIDs = Set(checkIns.map { $0.identifier })
                        self.checkIns.removeAll { refreshedIDs.contains($0.identifier) }
                        self.checkIns.append(contentsOf: checkIns)
                    } else {
                        self.checkIns = checkIns
                    }
                    self.checkIns.sort { $0.date > $1.date }
                    self.statusLabel.text = self.checkIns.isEmpty ? "No check-ins yet.\nTap + to add your first place." : nil
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
        self.loadedBlogName = nil
        self.deletingCheckIns.removeAll()
        self.dataSource = makePlacesDataSource()
        if self.isViewLoaded {
            self.refreshControl.endRefreshing()
            self.busyIndicator.stopAnimating()
            self.statusLabel.text = nil
            self.tableView.reloadData()
            self.dismiss(animated: false)
        }
    }

    @objc private func newCheckIn() {
        let accountGeneration = Settings.accountGeneration
        let composer = CheckInViewController(dataSource: self.dataSource) { [weak self] in
            guard accountGeneration == Settings.accountGeneration else { return }
            self?.fetchCheckIns(limit: 5, merging: true)
        }
        self.present(UINavigationController(rootViewController: composer), animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { self.checkIns.count }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard self.checkIns.indices.contains(indexPath.row),
              let blogName = self.loadedBlogName else { return false }
        let checkIn = self.checkIns[indexPath.row]
        let key = DeletionKey(blogName: blogName, identifier: checkIn.identifier)
        return !self.deletingCheckIns.contains(key) && (self.dataSource.isPreview || checkIn.postURL != nil)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard self.tableView(tableView, canEditRowAt: indexPath) else { return nil }
        let checkIn = self.checkIns[indexPath.row]
        let blog = BlogSettings.blogForCheckIns()
        let accountGeneration = Settings.accountGeneration
        guard self.loadedBlogName == blog.blogName else { return nil }
        let delete = UIContextualAction(style: .destructive, title: nil) { [weak self] _, _, completion in
            guard let self = self, accountGeneration == Settings.accountGeneration else { completion(false); return }
            self.deleteCheckIn(checkIn, blog: blog, completion: completion)
        }
        let buttonSize = CGSize(width: 56, height: 56)
        let symbol = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        let trash = UIImage(systemName: "trash", withConfiguration: symbol)?.withTintColor(.white, renderingMode: .alwaysOriginal)
        delete.image = UIGraphicsImageRenderer(size: buttonSize).image { _ in
            UIColor.systemRed.setFill()
            UIBezierPath(ovalIn: CGRect(origin: .zero, size: buttonSize)).fill()
            if let trash = trash {
                let origin = CGPoint(x: (buttonSize.width - trash.size.width) / 2,
                                     y: (buttonSize.height - trash.size.height) / 2)
                trash.draw(at: origin)
            }
        }.withRenderingMode(.alwaysOriginal)
        delete.image?.accessibilityLabel = "Delete check-in"
        delete.backgroundColor = .clear
        return UISwipeActionsConfiguration(actions: [delete])
    }

    private func deleteCheckIn(_ checkIn: SunlitCheckIn, blog: BlogSettings, completion: @escaping (Bool) -> Void) {
        let key = DeletionKey(blogName: blog.blogName, identifier: checkIn.identifier)
        guard self.loadedBlogName == blog.blogName,
              BlogSettings.blogForCheckIns().blogName == blog.blogName,
              self.checkIns.contains(where: { $0.identifier == checkIn.identifier }),
              self.deletingCheckIns.insert(key).inserted else { completion(false); return }
        let accountGeneration = Settings.accountGeneration
        self.dataSource.deleteCheckIn(checkIn, blog: blog) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self, accountGeneration == Settings.accountGeneration else { completion(false); return }
                self.deletingCheckIns.remove(key)
                guard self.loadedBlogName == blog.blogName,
                      BlogSettings.blogForCheckIns().blogName == blog.blogName else { completion(false); return }
                switch result {
                case .success:
                    // A fetch started before deletion may still contain the deleted post.
                    self.loadGeneration += 1
                    self.refreshControl.endRefreshing()
                    self.busyIndicator.stopAnimating()
                    let row = self.checkIns.firstIndex(where: { $0.identifier == checkIn.identifier })
                    if let row = row {
                        self.checkIns.remove(at: row)
                        self.tableView.deleteRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
                    }
                    self.statusLabel.text = self.checkIns.isEmpty ? "No check-ins yet.\nTap + to add your first place." : nil
                    if row == nil { self.loadCheckIns() }
                    completion(true)
                case .failure(let error):
                    completion(false)
                    Dialog(self).information(error.localizedDescription)
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PlaceCheckInTableViewCell.reuseIdentifier, for: indexPath) as! PlaceCheckInTableViewCell
        cell.configure(with: self.checkIns[indexPath.row])
        return cell
    }
}
