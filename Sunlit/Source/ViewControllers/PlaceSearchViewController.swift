import UIKit

final class PlaceSearchViewController: UITableViewController, UISearchResultsUpdating {
    private let dataSource: PlacesDataSource
    private let onCheckIn: () -> Void
    private let searchController = UISearchController(searchResultsController: nil)
    private let statusLabel = UILabel()
    private var results: [SunlitPlace] = []
    private var searchWork: DispatchWorkItem?
    private var searchGeneration = 0
    private var saving = false

    init(dataSource: PlacesDataSource, onCheckIn: @escaping () -> Void) {
        self.dataSource = dataSource
        self.onCheckIn = onCheckIn
        super.init(style: .plain)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "New Check-in"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        self.searchController.searchResultsUpdater = self
        self.searchController.obscuresBackgroundDuringPresentation = false
        self.searchController.searchBar.placeholder = "Search places"
        self.navigationItem.searchController = self.searchController
        self.navigationItem.hidesSearchBarWhenScrolling = false
        self.definesPresentationContext = true
        self.tableView.keyboardDismissMode = .onDrag
        self.statusLabel.textAlignment = .center
        self.statusLabel.numberOfLines = 0
        self.statusLabel.textColor = .secondaryLabel
        self.statusLabel.font = .preferredFont(forTextStyle: .body)
        self.statusLabel.adjustsFontForContentSizeCategory = true
        self.tableView.backgroundView = self.statusLabel
        self.search("")
    }

    func updateSearchResults(for searchController: UISearchController) {
        self.search(searchController.searchBar.text ?? "")
    }

    private func search(_ query: String) {
        self.searchWork?.cancel()
        self.searchGeneration += 1
        let generation = self.searchGeneration
        self.statusLabel.text = self.results.isEmpty ? "Searching places…" : nil
        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.dataSource.searchPlaces(matching: query) { [weak self] result in
                DispatchQueue.main.async {
                    guard let self = self, generation == self.searchGeneration else { return }
                    switch result {
                    case .success(let places):
                        self.results = places
                        self.statusLabel.text = places.isEmpty ? "No places found.\nTry a different search." : nil
                    case .failure(let error):
                        self.results = []
                        self.statusLabel.text = error.localizedDescription
                    }
                    self.tableView.reloadData()
                }
            }
        }
        self.searchWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
    }

    @objc private func cancel() {
        self.searchWork?.cancel()
        self.searchGeneration += 1
        self.dismiss(animated: true)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        self.dataSource.isPreview ? "Sample places" : nil
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { self.results.count }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Place") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "Place")
        let place = self.results[indexPath.row]
        cell.textLabel?.text = place.name
        cell.textLabel?.font = .preferredFont(forTextStyle: .headline)
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.text = place.address
        cell.detailTextLabel?.font = .preferredFont(forTextStyle: .subheadline)
        cell.detailTextLabel?.adjustsFontForContentSizeCategory = true
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.textColor = .secondaryLabel
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !self.saving, self.results.indices.contains(indexPath.row) else { return }
        let place = self.results[indexPath.row]
        self.searchController.searchBar.resignFirstResponder()
        let message = self.dataSource.isPreview ? "\(place.address)\n\nPreview only. This check-in won’t be published." : place.address
        let alert = UIAlertController(title: place.name, message: message, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Add a note (optional)" }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: self.dataSource.isPreview ? "Add Preview Check-in" : "Check In", style: .default) { [weak self, weak alert] _ in
            self?.checkIn(at: place, note: alert?.textFields?.first?.text ?? "")
        })
        self.present(alert, animated: true)
    }

    private func checkIn(at place: SunlitPlace, note: String) {
        self.saving = true
        self.tableView.isUserInteractionEnabled = false
        self.navigationItem.leftBarButtonItem?.isEnabled = false
        self.searchController.searchBar.isUserInteractionEnabled = false
        self.navigationController?.isModalInPresentation = true
        self.dataSource.checkIn(at: place, note: note) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.saving = false
                self.tableView.isUserInteractionEnabled = true
                self.navigationItem.leftBarButtonItem?.isEnabled = true
                self.searchController.searchBar.isUserInteractionEnabled = true
                self.navigationController?.isModalInPresentation = false
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
