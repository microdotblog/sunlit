import Foundation
import CoreFoundation
import CoreLocation

struct SunlitPlace {
    let identifier: String
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
}

struct SunlitCheckIn {
    let identifier: String
    let place: SunlitPlace
    let date: Date
    let note: String
    var blogName: String? = nil
}

protocol PlacesDataSource {
    var isPreview: Bool { get }
    func fetchCheckIns(completion: @escaping (Result<[SunlitCheckIn], Error>) -> Void)
    func searchPlaces(matching query: String, completion: @escaping (Result<[SunlitPlace], Error>) -> Void)
    func checkIn(at place: SunlitPlace, note: String, blog: BlogSettings, completion: @escaping (Result<SunlitCheckIn, Error>) -> Void)
}

func makePlacesDataSource() -> PlacesDataSource {
    return MicropubPlacesDataSource()
}

private struct PlacesUnavailableError: LocalizedError {
    var errorDescription: String? { "Searching for nearby places and posting check-ins aren’t available yet." }
}

final class MicropubPlacesDataSource: PlacesDataSource {
    let isPreview = false
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchCheckIns(completion: @escaping (Result<[SunlitCheckIn], Error>) -> Void) {
        let blog = BlogSettings.blogForCheckIns()
        do {
            let request = try Self.sourceRequest(for: blog)
            self.session.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let response = response as? HTTPURLResponse else {
                    completion(.failure(SourceError.invalidResponse))
                    return
                }
                guard (200..<300).contains(response.statusCode) else {
                    completion(.failure(SourceError.httpStatus(response.statusCode)))
                    return
                }
                do {
                    let checkIns = try Self.checkIns(from: data ?? Data(), blogName: blog.blogName)
                    completion(.success(checkIns))
                } catch {
                    completion(.failure(error))
                }
            }.resume()
        } catch {
            completion(.failure(error))
        }
    }

    static func sourceRequest(for blog: BlogSettings) throws -> URLRequest {
        guard let configuration = blog.snippetsConfiguration,
              configuration.type == .micropub,
              var components = URLComponents(string: configuration.micropubEndpoint),
              ["http", "https"].contains(components.scheme?.lowercased() ?? ""),
              components.host != nil else { throw SourceError.invalidConfiguration }
        guard !configuration.micropubToken.isEmpty else { throw SourceError.missingToken }
        var query = (components.queryItems ?? []).filter { $0.name != "q" && $0.name != "mp-destination" }
        query.append(URLQueryItem(name: "q", value: "source"))
        if let destination = configuration.micropubUid, !destination.isEmpty {
            query.append(URLQueryItem(name: "mp-destination", value: destination))
        }
        components.queryItems = query
        guard let url = components.url else { throw SourceError.invalidConfiguration }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        request.setValue("Bearer \(configuration.micropubToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    static func checkIns(from data: Data, blogName: String) throws -> [SunlitCheckIn] {
        guard let response = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = response["items"] as? [Any] else { throw SourceError.invalidResponse }
        let dateFormatter = ISO8601DateFormatter()
        let fractionalDateFormatter = ISO8601DateFormatter()
        fractionalDateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        return items.compactMap { item in
            guard let entry = item as? [String: Any],
                  let properties = entry["properties"] as? [String: Any],
                  let locations = properties["location"] as? [[String: Any]],
                  let location = locations.first,
                  let name = (location["name"] as? [String])?.first,
                  !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  let latitude = Self.number(in: location["latitude"]),
                  let longitude = Self.number(in: location["longitude"]),
                  let published = (properties["published"] as? [String])?.first,
                  let date = dateFormatter.date(from: published) ?? fractionalDateFormatter.date(from: published) else { return nil }
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            guard latitude.isFinite, longitude.isFinite, CLLocationCoordinate2DIsValid(coordinate) else { return nil }
            let url = (properties["url"] as? [String])?.first
            let uid = (properties["uid"] as? [Any])?.first
            let identifier = url ?? (uid as? String) ?? (uid as? NSNumber)?.stringValue ?? UUID().uuidString
            let placeURL = (location["url"] as? [String])?.first
            let place = SunlitPlace(identifier: placeURL ?? "\(latitude),\(longitude)", name: name, address: "", coordinate: coordinate)
            let content = (properties["content"] as? [Any])?.first
            let note = (content as? String) ?? (content as? [String: String])?["value"] ?? ""
            return SunlitCheckIn(identifier: identifier, place: place, date: date, note: note.trimmingCharacters(in: .whitespacesAndNewlines), blogName: blogName)
        }
    }

    private static func number(in property: Any?) -> Double? {
        guard let value = (property as? [Any])?.first else { return nil }
        if let string = value as? String { return Double(string) }
        if let number = value as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID() { return number.doubleValue }
        return nil
    }

    private enum SourceError: LocalizedError {
        case invalidConfiguration, missingToken, invalidResponse
        case httpStatus(Int)

        var errorDescription: String? {
            switch self {
            case .invalidConfiguration: return "The selected check-in blog does not have a Micropub endpoint."
            case .missingToken: return "Please sign in to the selected check-in blog again."
            case .invalidResponse: return "The blog returned an invalid check-in response."
            case .httpStatus(let status): return "Unable to load check-ins (\(status): \(HTTPURLResponse.localizedString(forStatusCode: status)))."
            }
        }
    }

    func searchPlaces(matching query: String, completion: @escaping (Result<[SunlitPlace], Error>) -> Void) {
        completion(.failure(PlacesUnavailableError()))
    }

    func checkIn(at place: SunlitPlace, note: String, blog: BlogSettings, completion: @escaping (Result<SunlitCheckIn, Error>) -> Void) {
        completion(.failure(PlacesUnavailableError()))
    }
}

#if DEBUG
final class PreviewPlacesDataSource: PlacesDataSource {
    let isPreview = true
    private let places = [
        SunlitPlace(identifier: "preview-library", name: "Austin Central Library", address: "710 W César Chávez St, Austin, TX", coordinate: CLLocationCoordinate2D(latitude: 30.2655, longitude: -97.7516)),
        SunlitPlace(identifier: "preview-barton", name: "Barton Springs Pool", address: "2201 Barton Springs Rd, Austin, TX", coordinate: CLLocationCoordinate2D(latitude: 30.2640, longitude: -97.7713)),
        SunlitPlace(identifier: "preview-zilker", name: "Zilker Metropolitan Park", address: "Austin, TX", coordinate: CLLocationCoordinate2D(latitude: 30.2670, longitude: -97.7730))
    ]
    private var checkIns: [SunlitCheckIn] = []

    init() {
        let now = Date()
        self.checkIns = self.places.enumerated().map { index, place in
            SunlitCheckIn(identifier: "preview-\(index)", place: place, date: now.addingTimeInterval(-Double(index + 1) * 86400), note: index == 0 ? "A quiet afternoon with a good book." : "")
        }
    }

    func fetchCheckIns(completion: @escaping (Result<[SunlitCheckIn], Error>) -> Void) {
        completion(.success(self.checkIns))
    }

    func searchPlaces(matching query: String, completion: @escaping (Result<[SunlitPlace], Error>) -> Void) {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        completion(.success(self.places.filter {
            query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) || $0.address.localizedCaseInsensitiveContains(query)
        }))
    }

    func checkIn(at place: SunlitPlace, note: String, blog: BlogSettings, completion: @escaping (Result<SunlitCheckIn, Error>) -> Void) {
        let checkIn = SunlitCheckIn(identifier: UUID().uuidString, place: place, date: Date(), note: note, blogName: blog.blogName)
        self.checkIns.insert(checkIn, at: 0)
        completion(.success(checkIn))
    }
}
#endif
