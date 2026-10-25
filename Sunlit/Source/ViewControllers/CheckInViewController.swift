import UIKit

final class CheckInViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, UISearchBarDelegate {
    private let dataSource: PlacesDataSource
    private let onCheckIn: () -> Void
    private let accountGeneration = Settings.accountGeneration
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let noteTextView = UITextView()
    private let notePlaceholder = UILabel()
    private let noteCell = UITableViewCell()
    private let searchBar = UISearchBar()
    private let nearbyHeader = UIView()
    private let blogSelectorButton = UIButton(type: .system)
    private var results: [SunlitPlace] = []
    private var selectedPlaceID: String?
    private var statusText = "Finding nearby places…"
    private var searchWork: DispatchWorkItem?
    private var searchGeneration = 0
    private var loading = false
    private var saving = false
    private var searchFailed = false
    private var needsLocationSettings = false

    init(dataSource: PlacesDataSource, onCheckIn: @escaping () -> Void) {
        self.dataSource = dataSource
        self.onCheckIn = onCheckIn
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "New Check-in"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancel))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Post", style: .plain, target: self, action: #selector(postCheckIn))
        self.view.backgroundColor = .secondarySystemBackground
        self.configureNote()
        self.configureNearbyHeader()
        self.configureLayout()
        self.updateBlogSelectorButton()
        NotificationCenter.default.addObserver(self, selector: #selector(retryLocationSearch), name: UIApplication.didBecomeActiveNotification, object: nil)
        self.search("")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateBlogSelectorButton()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.isBeingDismissed || self.navigationController?.isBeingDismissed == true {
            self.searchWork?.cancel()
            self.searchGeneration += 1
            self.dataSource.cancelPlaceSearch()
        }
    }

    @objc private func retryLocationSearch() {
        if self.needsLocationSettings && self.viewIfLoaded?.window != nil && !self.saving {
            self.search(self.searchBar.text ?? "")
        }
    }

    private func configureNote() {
        self.noteCell.selectionStyle = .none
        self.noteCell.separatorInset = .zero
        self.noteTextView.font = .preferredFont(forTextStyle: .body)
        self.noteTextView.adjustsFontForContentSizeCategory = true
        self.noteTextView.backgroundColor = .clear
        self.noteTextView.isScrollEnabled = false
        self.noteTextView.textContainerInset = .zero
        self.noteTextView.textContainer.lineFragmentPadding = 0
        self.noteTextView.delegate = self
        self.noteTextView.accessibilityLabel = "Blog post text"
        self.noteTextView.translatesAutoresizingMaskIntoConstraints = false
        self.notePlaceholder.text = "Write a check-in for your blog…"
        self.notePlaceholder.font = .preferredFont(forTextStyle: .body)
        self.notePlaceholder.adjustsFontForContentSizeCategory = true
        self.notePlaceholder.textColor = .placeholderText
        self.notePlaceholder.isUserInteractionEnabled = false
        self.notePlaceholder.isAccessibilityElement = false
        self.notePlaceholder.translatesAutoresizingMaskIntoConstraints = false
        self.noteCell.contentView.addSubview(self.noteTextView)
        self.noteTextView.addSubview(self.notePlaceholder)
        NSLayoutConstraint.activate([
            self.noteTextView.leadingAnchor.constraint(equalTo: self.noteCell.contentView.layoutMarginsGuide.leadingAnchor),
            self.noteTextView.trailingAnchor.constraint(equalTo: self.noteCell.contentView.layoutMarginsGuide.trailingAnchor),
            self.noteTextView.topAnchor.constraint(equalTo: self.noteCell.contentView.topAnchor, constant: 16),
            self.noteTextView.bottomAnchor.constraint(equalTo: self.noteCell.contentView.bottomAnchor, constant: -16),
            self.noteTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 160),
            self.notePlaceholder.leadingAnchor.constraint(equalTo: self.noteTextView.leadingAnchor),
            self.notePlaceholder.topAnchor.constraint(equalTo: self.noteTextView.topAnchor),
            self.notePlaceholder.trailingAnchor.constraint(lessThanOrEqualTo: self.noteTextView.trailingAnchor)
        ])
    }

    private func configureNearbyHeader() {
        self.nearbyHeader.backgroundColor = .systemBackground
        self.searchBar.searchBarStyle = .minimal
        self.searchBar.placeholder = "Search nearby places"
        self.searchBar.delegate = self
        self.searchBar.translatesAutoresizingMaskIntoConstraints = false
        self.nearbyHeader.addSubview(self.searchBar)
        NSLayoutConstraint.activate([
            self.searchBar.topAnchor.constraint(equalTo: self.nearbyHeader.topAnchor, constant: 4),
            self.searchBar.leadingAnchor.constraint(equalTo: self.nearbyHeader.leadingAnchor, constant: 4),
            self.searchBar.trailingAnchor.constraint(equalTo: self.nearbyHeader.trailingAnchor, constant: -4),
            self.searchBar.heightAnchor.constraint(equalToConstant: 56),
            self.searchBar.bottomAnchor.constraint(equalTo: self.nearbyHeader.bottomAnchor, constant: -4)
        ])
    }

    private func configureLayout() {
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 68
        self.tableView.separatorInsetReference = .fromCellEdges
        self.tableView.sectionHeaderTopPadding = 0
        self.tableView.keyboardDismissMode = .interactive
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        let toolbar = UIView()
        toolbar.backgroundColor = .secondarySystemBackground
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        self.blogSelectorButton.translatesAutoresizingMaskIntoConstraints = false
        self.blogSelectorButton.addTarget(self, action: #selector(selectBlog), for: .touchUpInside)
        let dismissKeyboard = UIButton(type: .system)
        dismissKeyboard.setImage(UIImage(systemName: "keyboard.chevron.compact.down"), for: .normal)
        dismissKeyboard.tintColor = .label
        dismissKeyboard.accessibilityLabel = "Dismiss keyboard"
        dismissKeyboard.translatesAutoresizingMaskIntoConstraints = false
        dismissKeyboard.addTarget(self, action: #selector(endEditing), for: .touchUpInside)
        self.view.addSubview(self.tableView)
        self.view.addSubview(toolbar)
        toolbar.addSubview(self.blogSelectorButton)
        toolbar.addSubview(dismissKeyboard)
        NSLayoutConstraint.activate([
            self.tableView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            self.tableView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: toolbar.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: self.view.keyboardLayoutGuide.topAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 44),
            self.blogSelectorButton.centerXAnchor.constraint(equalTo: toolbar.centerXAnchor),
            self.blogSelectorButton.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),
            self.blogSelectorButton.leadingAnchor.constraint(greaterThanOrEqualTo: toolbar.safeAreaLayoutGuide.leadingAnchor, constant: 52),
            self.blogSelectorButton.trailingAnchor.constraint(lessThanOrEqualTo: dismissKeyboard.leadingAnchor, constant: -8),
            dismissKeyboard.trailingAnchor.constraint(equalTo: toolbar.safeAreaLayoutGuide.trailingAnchor, constant: -8),
            dismissKeyboard.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),
            dismissKeyboard.widthAnchor.constraint(equalToConstant: 44),
            dismissKeyboard.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func updateBlogSelectorButton() {
        var configuration = UIButton.Configuration.plain()
        configuration.title = BlogSettings.blogForCheckIns().blogName
        configuration.image = UIImage(systemName: "chevron.down", withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .regular))
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 5
        configuration.titleLineBreakMode = .byTruncatingMiddle
        configuration.baseForegroundColor = .label
        configuration.contentInsets = .zero
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = .systemFont(ofSize: 15)
            return attributes
        }
        self.blogSelectorButton.configuration = configuration
        self.blogSelectorButton.isUserInteractionEnabled = !self.saving && BlogSettings.publishedBlogs().count > 1
        self.blogSelectorButton.accessibilityLabel = "Publishing to \(BlogSettings.blogForCheckIns().blogName)"
    }

    @objc private func selectBlog() {
        self.view.endEditing(true)
        BlogChooserViewController.present(from: self, blogs: BlogSettings.publishedBlogs(), purpose: .checkIns) { [weak self] _ in
            self?.updateBlogSelectorButton()
        }
    }

    @objc private func endEditing() { self.view.endEditing(true) }

    func textViewDidChange(_ textView: UITextView) {
        self.notePlaceholder.isHidden = !textView.text.isEmpty
        UIView.performWithoutAnimation { self.tableView.performBatchUpdates(nil) }
        if let selection = textView.selectedTextRange {
            let caret = textView.caretRect(for: selection.end).insetBy(dx: 0, dy: -16)
            self.tableView.scrollRectToVisible(textView.convert(caret, to: self.tableView), animated: false)
        }
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) { self.search(searchText) }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) { searchBar.resignFirstResponder() }

    private func search(_ query: String) {
        self.searchWork?.cancel()
        self.dataSource.cancelPlaceSearch()
        self.searchGeneration += 1
        let generation = self.searchGeneration
        self.loading = true
        self.searchFailed = false
        self.needsLocationSettings = false
        self.statusText = query.isEmpty ? "Finding nearby places…" : "Searching places…"
        if self.results.isEmpty {
            let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 1))
            cell?.textLabel?.text = self.statusText
            cell?.accessoryType = .none
            cell?.accessibilityTraits = .staticText
        }
        self.updatePostButton()
        let work = DispatchWorkItem { [weak self] in
            guard let self = self, generation == self.searchGeneration else { return }
            self.dataSource.searchPlaces(matching: query) { [weak self] result in
                DispatchQueue.main.async {
                    guard let self = self, generation == self.searchGeneration,
                          self.accountGeneration == Settings.accountGeneration else { return }
                    self.loading = false
                    let previousCount = max(self.results.count, 1)
                    switch result {
                    case .success(let places):
                        // The service supplies nearby/best-match order; keep that ranking.
                        self.results = places
                        if !places.contains(where: { $0.identifier == self.selectedPlaceID }) {
                            self.selectedPlaceID = places.first?.identifier
                        }
                        self.statusText = "No places found. Try a different search."
                    case .failure(let error):
                        self.results = []
                        self.selectedPlaceID = nil
                        self.statusText = error.localizedDescription
                        self.searchFailed = true
                        self.needsLocationSettings = (error as? AppleMapsPlacesSearch.SearchError) == .permissionDenied
                    }
                    // Keep the search field and note attached while replacing results.
                    self.tableView.performBatchUpdates {
                        self.tableView.deleteRows(at: (0..<previousCount).map { IndexPath(row: $0, section: 1) }, with: .none)
                        self.tableView.insertRows(at: (0..<max(self.results.count, 1)).map { IndexPath(row: $0, section: 1) }, with: .none)
                    }
                    self.updatePostButton()
                }
            }
        }
        self.searchWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
    }

    private func updatePostButton() {
        self.navigationItem.rightBarButtonItem?.title = self.saving ? "Posting…" : "Post"
        self.navigationItem.rightBarButtonItem?.isEnabled = !self.loading && !self.saving && self.selectedPlaceID != nil
    }

    @objc private func cancel() {
        self.searchWork?.cancel()
        self.dataSource.cancelPlaceSearch()
        self.searchGeneration += 1
        self.view.endEditing(true)
        self.dismiss(animated: true)
    }

    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 1 : max(self.results.count, 1)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        section == 1 ? self.nearbyHeader : nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        section == 1 ? UITableView.automaticDimension : .leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat { section == 1 ? 64 : 0 }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        section == 1 && self.dataSource.isPreview ? "Preview only. Check-ins won’t be published." : nil
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 { return self.noteCell }
        let cell = tableView.dequeueReusableCell(withIdentifier: "Place") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "Place")
        guard !self.results.isEmpty else {
            let action = self.needsLocationSettings ? "Open Settings" : "Tap to try again."
            cell.textLabel?.text = self.searchFailed ? self.statusText + "\n" + action : self.statusText
            cell.textLabel?.font = .preferredFont(forTextStyle: .body)
            cell.textLabel?.adjustsFontForContentSizeCategory = true
            cell.textLabel?.textColor = .secondaryLabel
            cell.textLabel?.numberOfLines = 0
            cell.detailTextLabel?.text = nil
            cell.accessoryType = self.needsLocationSettings ? .disclosureIndicator : .none
            cell.accessibilityTraits = self.searchFailed ? .button : .staticText
            return cell
        }
        let place = self.results[indexPath.row]
        let selected = place.identifier == self.selectedPlaceID
        cell.textLabel?.text = place.name
        cell.textLabel?.font = .preferredFont(forTextStyle: .headline)
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.textColor = .label
        cell.detailTextLabel?.text = place.address
        cell.detailTextLabel?.font = .preferredFont(forTextStyle: .subheadline)
        cell.detailTextLabel?.adjustsFontForContentSizeCategory = true
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.accessoryType = selected ? .checkmark : .none
        cell.accessibilityTraits = selected ? [.button, .selected] : .button
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1, self.results.isEmpty, self.searchFailed, !self.loading, !self.saving {
            if self.needsLocationSettings, let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            } else {
                self.search(self.searchBar.text ?? "")
            }
            return
        }
        guard indexPath.section == 1, !self.saving, !self.loading, self.results.indices.contains(indexPath.row) else { return }
        self.selectedPlaceID = self.results[indexPath.row].identifier
        self.tableView.reloadRows(at: self.tableView.indexPathsForVisibleRows?.filter { $0.section == 1 } ?? [], with: .none)
        self.updatePostButton()
    }

    @objc private func postCheckIn() {
        guard !self.saving, !self.loading,
              let place = self.results.first(where: { $0.identifier == self.selectedPlaceID }) else { return }
        let blog = BlogSettings.blogForCheckIns()
        let note = self.noteTextView.text ?? ""
        self.searchWork?.cancel()
        self.searchGeneration += 1
        self.dataSource.cancelPlaceSearch()
        self.saving = true
        self.view.endEditing(true)
        self.tableView.isUserInteractionEnabled = false
        self.blogSelectorButton.isUserInteractionEnabled = false
        self.navigationItem.leftBarButtonItem?.isEnabled = false
        self.navigationController?.isModalInPresentation = true
        self.updatePostButton()
        self.dataSource.checkIn(at: place, note: note, blog: blog) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self, self.accountGeneration == Settings.accountGeneration else { return }
                self.saving = false
                self.tableView.isUserInteractionEnabled = true
                self.navigationItem.leftBarButtonItem?.isEnabled = true
                self.navigationController?.isModalInPresentation = false
                self.updateBlogSelectorButton()
                self.updatePostButton()
                switch result {
                case .success:
                    self.dismiss(animated: true, completion: self.onCheckIn)
                case .failure(let error):
                    Dialog(self).information(error.localizedDescription)
                }
            }
        }
    }
}
