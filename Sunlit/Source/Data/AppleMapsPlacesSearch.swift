import Foundation
import CoreLocation
import MapKit

final class AppleMapsPlacesSearch: NSObject, CLLocationManagerDelegate {
    enum SearchError: LocalizedError {
        case permissionDenied, restricted, locationUnavailable

        var errorDescription: String? {
            switch self {
            case .permissionDenied: return "Allow location access for Sunlit in Settings to find nearby places."
            case .restricted: return "Location access is restricted on this device."
            case .locationUnavailable: return "Unable to find your current location. Please try again."
            }
        }
    }

    private let locationManager: CLLocationManager
    private let makeSearch: (String, CLLocation) -> MKLocalSearch
    private var completion: ((Result<[SunlitPlace], Error>) -> Void)?
    private var query = ""
    private var location: CLLocation?
    private var requestingLocation = false
    private var locationTimeout: DispatchWorkItem?
    private var activeSearch: MKLocalSearch?
    private var generation = 0

    init(locationManager: CLLocationManager = CLLocationManager(), makeSearch: @escaping (String, CLLocation) -> MKLocalSearch = AppleMapsPlacesSearch.localSearch) {
        self.locationManager = locationManager
        self.makeSearch = makeSearch
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func search(matching query: String, completion: @escaping (Result<[SunlitPlace], Error>) -> Void) {
        self.cancel()
        self.query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        self.completion = completion
        self.checkAuthorization()
    }

    func cancel() {
        self.generation += 1
        self.completion = nil
        self.locationTimeout?.cancel()
        self.locationTimeout = nil
        self.locationManager.stopUpdatingLocation()
        self.requestingLocation = false
        self.activeSearch?.cancel()
        self.activeSearch = nil
    }

    private func checkAuthorization() {
        guard self.completion != nil else { return }
        switch self.locationManager.authorizationStatus {
        case .notDetermined: self.locationManager.requestWhenInUseAuthorization()
        case .denied: self.finish(.failure(SearchError.permissionDenied))
        case .restricted: self.finish(.failure(SearchError.restricted))
        case .authorizedAlways, .authorizedWhenInUse:
            guard !self.requestingLocation, self.activeSearch == nil else { return }
            if let location = self.location, abs(location.timestamp.timeIntervalSinceNow) < 60 {
                self.findPlaces(near: location)
            } else {
                self.requestingLocation = true
                let generation = self.generation
                let timeout = DispatchWorkItem { [weak self] in
                    guard let self = self, generation == self.generation else { return }
                    self.finish(.failure(SearchError.locationUnavailable))
                }
                self.locationTimeout = timeout
                DispatchQueue.main.asyncAfter(deadline: .now() + 20, execute: timeout)
                self.locationManager.requestLocation()
            }
        @unknown default: self.finish(.failure(SearchError.locationUnavailable))
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.checkAuthorization()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard self.requestingLocation else { return }
        guard let location = locations.last(where: {
            $0.horizontalAccuracy >= 0 && abs($0.timestamp.timeIntervalSinceNow) < 120 && CLLocationCoordinate2DIsValid($0.coordinate)
        }) else {
            self.finish(.failure(SearchError.locationUnavailable))
            return
        }
        self.location = location
        self.requestingLocation = false
        self.locationTimeout?.cancel()
        self.locationTimeout = nil
        self.findPlaces(near: location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard self.requestingLocation else { return }
        self.finish(.failure((error as? CLError)?.code == .denied ? SearchError.permissionDenied : SearchError.locationUnavailable))
    }

    private func findPlaces(near location: CLLocation) {
        let generation = self.generation
        let search = self.makeSearch(self.query, location)
        self.activeSearch = search
        search.start { [weak self] response, error in
            DispatchQueue.main.async {
                guard let self = self, generation == self.generation else { return }
                if let error = error {
                    if (error as? MKError)?.code == .placemarkNotFound { self.finish(.success([])) }
                    else { self.finish(.failure(error)) }
                } else {
                    self.finish(.success(Self.places(from: response?.mapItems ?? [], near: location)))
                }
            }
        }
    }

    private func finish(_ result: Result<[SunlitPlace], Error>) {
        let completion = self.completion
        self.cancel()
        completion?(result)
    }

    static func localSearch(query: String, location: CLLocation) -> MKLocalSearch {
        if query.isEmpty {
            return MKLocalSearch(request: MKLocalPointsOfInterestRequest(center: location.coordinate, radius: 1000))
        }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
        request.resultTypes = .pointOfInterest
        if #available(iOS 18.0, macOS 15.0, *) { request.regionPriority = .required }
        return MKLocalSearch(request: request)
    }

    static func places(from items: [MKMapItem], near location: CLLocation) -> [SunlitPlace] {
        var identifiers = Set<String>()
        let places: [SunlitPlace] = items.compactMap { item in
            guard let name = item.name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  CLLocationCoordinate2DIsValid(item.placemark.coordinate), !item.isCurrentLocation else { return nil }
            let coordinate = item.placemark.coordinate
            let identifier = "\(name)-\(coordinate.latitude),\(coordinate.longitude)"
            guard identifiers.insert(identifier).inserted else { return nil }
            let street = [item.placemark.subThoroughfare, item.placemark.thoroughfare].compactMap { $0 }.joined(separator: " ")
            let city = [item.placemark.locality, item.placemark.administrativeArea].compactMap { $0 }.joined(separator: ", ")
            let address = [street, city].filter { !$0.isEmpty }.joined(separator: ", ")
            var url = URLComponents(string: "https://maps.apple.com/")!
            url.queryItems = [URLQueryItem(name: "q", value: name), URLQueryItem(name: "ll", value: "\(coordinate.latitude),\(coordinate.longitude)")]
            return SunlitPlace(identifier: identifier, name: name, address: address, coordinate: coordinate, url: url.url)
        }
        return places.sorted {
            let first = CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude).distance(from: location)
            let second = CLLocation(latitude: $1.coordinate.latitude, longitude: $1.coordinate.longitude).distance(from: location)
            return first == second ? $0.name < $1.name : first < second
        }
    }
}
