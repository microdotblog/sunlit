import UIKit
import MapKit

final class PlaceCheckInTableViewCell: UITableViewCell {
    static let reuseIdentifier = "PlaceCheckInTableViewCell"
    private static let snapshots = NSCache<NSString, UIImage>()
    private let mapImage = UIImageView()
    private let nameLabel = UILabel()
    private let addressLabel = UILabel()
    private let dateLabel = UILabel()
    private let noteLabel = UILabel()
    private var snapshotter: MKMapSnapshotter?
    private var representedSnapshot: String?
    private var place: SunlitPlace?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        var background = UIBackgroundConfiguration.clear()
        background.backgroundColor = .systemBackground
        self.backgroundConfiguration = background
        self.automaticallyUpdatesBackgroundConfiguration = false
        self.separatorInset = .zero
        self.nameLabel.font = .preferredFont(forTextStyle: .headline)
        self.addressLabel.font = .preferredFont(forTextStyle: .subheadline)
        self.dateLabel.font = .preferredFont(forTextStyle: .caption1)
        self.noteLabel.font = .preferredFont(forTextStyle: .body)
        self.addressLabel.textColor = .secondaryLabel
        self.dateLabel.textColor = .secondaryLabel
        for label in [self.nameLabel, self.addressLabel, self.dateLabel, self.noteLabel] {
            label.numberOfLines = 0
            label.adjustsFontForContentSizeCategory = true
        }
        self.mapImage.backgroundColor = .secondarySystemBackground
        self.mapImage.contentMode = .scaleAspectFill
        self.mapImage.clipsToBounds = true
        self.mapImage.layer.cornerRadius = 10
        self.mapImage.tintColor = .secondaryLabel
        self.mapImage.isAccessibilityElement = false
        let labels = UIStackView(arrangedSubviews: [self.nameLabel, self.addressLabel, self.noteLabel, self.dateLabel])
        labels.axis = .vertical
        labels.spacing = 8
        labels.setCustomSpacing(6, after: self.nameLabel)
        let row = UIStackView(arrangedSubviews: [self.mapImage, labels])
        row.alignment = .top
        row.spacing = 16
        row.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(row)
        NSLayoutConstraint.activate([
            self.mapImage.widthAnchor.constraint(equalToConstant: 96),
            self.mapImage.heightAnchor.constraint(equalToConstant: 96),
            row.leadingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.trailingAnchor),
            row.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 16),
            row.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -16)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.cancelSnapshot()
        self.place = nil
        self.mapImage.image = nil
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if self.window == nil {
            self.cancelSnapshot()
        } else {
            self.loadSnapshot()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            self.loadSnapshot()
        }
    }

    func configure(with checkIn: SunlitCheckIn) {
        self.place = checkIn.place
        self.nameLabel.text = checkIn.place.name
        self.addressLabel.text = checkIn.place.address
        self.addressLabel.isHidden = checkIn.place.address.isEmpty
        self.dateLabel.text = checkIn.date.timestampFormat()

        var note = checkIn.note
        let locationSentence = checkIn.place.name + "."
        let locationPrefix = locationSentence + " "
        if note == locationSentence {
            note = ""
        } else if note.hasPrefix(locationPrefix) {
            note = String(note.dropFirst(locationPrefix.count))
        }
        self.noteLabel.text = note
        self.noteLabel.isHidden = note.isEmpty
        self.loadSnapshot()
    }

    private func cancelSnapshot() {
        self.representedSnapshot = nil
        self.snapshotter?.cancel()
        self.snapshotter = nil
    }

    private func loadSnapshot() {
        self.cancelSnapshot()
        guard let place = self.place else { return }
        let coordinate = place.coordinate
        let key = "\(coordinate.latitude),\(coordinate.longitude)-\(self.traitCollection.userInterfaceStyle.rawValue)"
        self.representedSnapshot = key
        if let image = Self.snapshots.object(forKey: key as NSString) {
            self.mapImage.image = image
            return
        }
        self.mapImage.image = nil
        guard self.window != nil, CLLocationCoordinate2DIsValid(coordinate) else { return }
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 700, longitudinalMeters: 700)
        options.size = CGSize(width: 96, height: 96)
        options.traitCollection = self.traitCollection
        options.pointOfInterestFilter = .excludingAll
        let snapshotter = MKMapSnapshotter(options: options)
        self.snapshotter = snapshotter
        snapshotter.start(with: .main) { [weak self] snapshot, error in
            guard let self = self, self.representedSnapshot == key, let snapshot = snapshot else { return }
            self.snapshotter = nil
            let image = snapshot.image
            Self.snapshots.setObject(image, forKey: key as NSString, cost: Int(image.size.width * image.size.height * image.scale * image.scale * 4))
            Self.snapshots.totalCostLimit = 8 * 1024 * 1024
            self.mapImage.image = image
        }
    }
}
