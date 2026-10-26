import Foundation
import CoreFoundation
import CoreLocation

struct SunlitPlace {
    let identifier: String
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    var url: URL? = nil
}

struct SunlitCheckIn {
    let identifier: String
    let place: SunlitPlace
    let date: Date
    let note: String
    var blogName: String? = nil
    var postURL: URL? = nil
}

protocol PlacesDataSource {
    var isPreview: Bool { get }
    func fetchCheckIns(limit: Int, completion: @escaping (Result<[SunlitCheckIn], Error>) -> Void)
    func searchPlaces(matching query: String, completion: @escaping (Result<[SunlitPlace], Error>) -> Void)
    func cancelPlaceSearch()
    func checkIn(at place: SunlitPlace, note: String, blog: BlogSettings, completion: @escaping (Result<SunlitCheckIn, Error>) -> Void)
    func deleteCheckIn(_ checkIn: SunlitCheckIn, blog: BlogSettings, completion: @escaping (Result<Void, Error>) -> Void)
}

extension PlacesDataSource {
    func cancelPlaceSearch() {}
}

func makePlacesDataSource() -> PlacesDataSource {
    return MicropubPlacesDataSource()
}

final class MicropubPlacesDataSource: PlacesDataSource {
    let isPreview = false
    private static let sourcePageSize = 100
    private static let sourcePostLimit = 500
    private let session: URLSession
    private lazy var placeSearch = AppleMapsPlacesSearch()

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchCheckIns(limit: Int = 500, completion: @escaping (Result<[SunlitCheckIn], Error>) -> Void) {
        let blog = BlogSettings.blogForCheckIns()
        let postLimit = min(max(limit, 0), Self.sourcePostLimit)
        Task {
            do {
                var items: [Any] = []
                for offset in stride(from: 0, to: postLimit, by: Self.sourcePageSize) {
                    let pageSize = min(Self.sourcePageSize, postLimit - offset)
                    let request = try Self.sourceRequest(for: blog, offset: offset, limit: pageSize)
                    let (data, response) = try await self.session.data(for: request)
                    guard let response = response as? HTTPURLResponse else { throw SourceError.invalidResponse }
                    guard (200..<300).contains(response.statusCode) else { throw SourceError.httpStatus(response.statusCode) }
                    let page = try Self.sourceItems(from: data)
                    items.append(contentsOf: page.prefix(pageSize))
                    if page.count < pageSize { break }
                }
                completion(.success(Self.checkIns(from: items, blogName: blog.blogName)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    static func sourceRequest(for blog: BlogSettings, offset: Int = 0, limit: Int = 100) throws -> URLRequest {
        var request = try Self.authenticatedRequest(for: blog)
        guard let endpoint = request.url,
              var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else { throw SourceError.invalidConfiguration }
        var query = (components.queryItems ?? []).filter { !["q", "mp-destination", "limit", "offset"].contains($0.name) }
        query.append(URLQueryItem(name: "q", value: "source"))
        query.append(URLQueryItem(name: "limit", value: String(limit)))
        query.append(URLQueryItem(name: "offset", value: String(offset)))
        if let destination = blog.snippetsConfiguration?.micropubUid, !destination.isEmpty {
            query.append(URLQueryItem(name: "mp-destination", value: destination))
        }
        components.queryItems = query
        guard let url = components.url else { throw SourceError.invalidConfiguration }
        request.url = url
        return request
    }

    private static func authenticatedRequest(for blog: BlogSettings) throws -> URLRequest {
        guard let configuration = blog.snippetsConfiguration,
              configuration.type == .micropub,
              var components = URLComponents(string: configuration.micropubEndpoint),
              ["http", "https"].contains(components.scheme?.lowercased() ?? ""),
              components.host != nil else { throw SourceError.invalidConfiguration }
        guard !configuration.micropubToken.isEmpty else { throw SourceError.missingToken }
        components.queryItems = components.queryItems?.filter { $0.name != "q" && $0.name != "mp-destination" }
        guard let url = components.url else { throw SourceError.invalidConfiguration }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        request.setValue("Bearer \(configuration.micropubToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    static func checkIns(from data: Data, blogName: String) throws -> [SunlitCheckIn] {
        return Self.checkIns(from: try Self.sourceItems(from: data), blogName: blogName)
    }

    private static func sourceItems(from data: Data) throws -> [Any] {
        guard let response = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = response["items"] as? [Any] else { throw SourceError.invalidResponse }
        return items
    }

    private static func checkIns(from items: [Any], blogName: String) -> [SunlitCheckIn] {
        let dateFormatter = ISO8601DateFormatter()
        let fractionalDateFormatter = ISO8601DateFormatter()
        fractionalDateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // Limit source posts, including ordinary posts, before filtering for check-ins.
        return items.prefix(Self.sourcePostLimit).compactMap { item in
            guard let entry = item as? [String: Any],
                  let properties = entry["properties"] as? [String: Any],
                  let place = Self.place(in: properties),
                  let published = (properties["published"] as? [String])?.first,
                  let date = dateFormatter.date(from: published) ?? fractionalDateFormatter.date(from: published) else { return nil }
            let url = (properties["url"] as? [String])?.first
            let uid = (properties["uid"] as? [Any])?.first
            let identifier = url ?? (uid as? String) ?? (uid as? NSNumber)?.stringValue ?? UUID().uuidString
            let content = (properties["content"] as? [Any])?.first
            let note = (content as? String) ?? (content as? [String: String])?["value"] ?? ""
            return SunlitCheckIn(identifier: identifier, place: place, date: date, note: note.trimmingCharacters(in: .whitespacesAndNewlines), blogName: blogName, postURL: url.flatMap(URL.init(string:)))
        }
    }

    private static func place(in properties: [String: Any]) -> SunlitPlace? {
        let checkIns = properties["checkin"] as? [[String: Any]] ?? []
        let locations = properties["location"] as? [[String: Any]] ?? []
        for value in checkIns + locations {
            // Micropub uses nested h-card properties; Micro.blog returns a flat location.
            let location = value["properties"] as? [String: Any] ?? value
            guard let name = (location["name"] as? [String])?.first,
                  !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  let latitude = Self.number(in: location["latitude"]),
                  let longitude = Self.number(in: location["longitude"]) else { continue }
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            guard latitude.isFinite, longitude.isFinite, CLLocationCoordinate2DIsValid(coordinate) else { continue }
            let url = (location["url"] as? [String])?.first
            return SunlitPlace(identifier: url ?? "\(latitude),\(longitude)", name: name, address: "", coordinate: coordinate, url: url.flatMap(URL.init(string:)))
        }
        return nil
    }

    private static func number(in property: Any?) -> Double? {
        guard let value = (property as? [Any])?.first else { return nil }
        if let string = value as? String { return Double(string) }
        if let number = value as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID() { return number.doubleValue }
        return nil
    }

    private enum SourceError: LocalizedError {
        case invalidConfiguration, missingToken, invalidResponse, invalidPlace, invalidPostURL
        case deletionNotAuthorized(String)
        case httpStatus(Int)

        var errorDescription: String? {
            switch self {
            case .invalidConfiguration: return "The selected check-in blog does not have a Micropub endpoint."
            case .missingToken: return "Please sign in to the selected check-in blog again."
            case .invalidResponse: return "The blog returned an invalid check-in response."
            case .invalidPlace: return "Please choose a place with a name and valid coordinates."
            case .deletionNotAuthorized(let blogName): return "The blog did not authorize deleting this check-in. In Settings, tap Add External Blog under location check-ins and reconnect \(blogName) to allow deleting posts, then try again."
            case .invalidPostURL: return "This check-in does not have a valid post URL to delete."
            case .httpStatus(let status): return "Unable to load check-ins (\(status): \(HTTPURLResponse.localizedString(forStatusCode: status)))."
            }
        }
    }

    func searchPlaces(matching query: String, completion: @escaping (Result<[SunlitPlace], Error>) -> Void) {
        self.placeSearch.search(matching: query, completion: completion)
    }

    func cancelPlaceSearch() {
        self.placeSearch.cancel()
    }

    func checkIn(at place: SunlitPlace, note: String, blog: BlogSettings, completion: @escaping (Result<SunlitCheckIn, Error>) -> Void) {
        let date = CheckInPostDelay.selected.publishedDate()
        do {
            let request = try Self.checkInRequest(at: place, note: note, blog: blog, date: date)
            self.session.dataTask(with: request) { _, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let response = response as? HTTPURLResponse else {
                    completion(.failure(SourceError.invalidResponse))
                    return
                }
                guard (200..<300).contains(response.statusCode) else {
                    let message = "Unable to post check-in (\(response.statusCode): \(HTTPURLResponse.localizedString(forStatusCode: response.statusCode)))."
                    completion(.failure(NSError(domain: "SunlitCheckIn", code: response.statusCode, userInfo: [NSLocalizedDescriptionKey: message])))
                    return
                }
                let identifier = response.value(forHTTPHeaderField: "Location") ?? UUID().uuidString
                let postURL = response.value(forHTTPHeaderField: "Location").flatMap { URL(string: $0, relativeTo: request.url)?.absoluteURL }
                completion(.success(SunlitCheckIn(identifier: identifier, place: place, date: date, note: note, blogName: blog.blogName, postURL: postURL)))
            }.resume()
        } catch {
            completion(.failure(error))
        }
    }

    static func checkInRequest(at place: SunlitPlace, note: String, blog: BlogSettings, date: Date = CheckInPostDelay.selected.publishedDate()) throws -> URLRequest {
        guard !place.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              place.coordinate.latitude.isFinite, place.coordinate.longitude.isFinite,
              CLLocationCoordinate2DIsValid(place.coordinate) else { throw SourceError.invalidPlace }
        var request = try Self.authenticatedRequest(for: blog)
        var venue: [String: Any] = ["name": [place.name], "latitude": [place.coordinate.latitude], "longitude": [place.coordinate.longitude]]
        if let url = place.url { venue["url"] = [url.absoluteString] }
        var body: [String: Any] = [
            "type": ["h-entry"],
            "properties": [
                "published": [ISO8601DateFormatter().string(from: date)],
                "content": [note],
                "checkin": [["type": ["h-card"], "properties": venue]]
            ]
        ]
        if let destination = blog.snippetsConfiguration?.micropubUid, !destination.isEmpty { body["mp-destination"] = destination }
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    func deleteCheckIn(_ checkIn: SunlitCheckIn, blog: BlogSettings, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let request = try Self.deleteRequest(for: checkIn, blog: blog)
            self.session.dataTask(with: request) { _, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let response = response as? HTTPURLResponse else {
                    completion(.failure(SourceError.invalidResponse))
                    return
                }
                guard (200..<300).contains(response.statusCode) else {
                    if response.statusCode == 401 || response.statusCode == 403 {
                        completion(.failure(SourceError.deletionNotAuthorized(blog.blogName)))
                        return
                    }
                    let message = "Unable to delete check-in (\(response.statusCode): \(HTTPURLResponse.localizedString(forStatusCode: response.statusCode)))."
                    completion(.failure(NSError(domain: "SunlitCheckIn", code: response.statusCode, userInfo: [NSLocalizedDescriptionKey: message])))
                    return
                }
                completion(.success(()))
            }.resume()
        } catch {
            completion(.failure(error))
        }
    }

    static func deleteRequest(for checkIn: SunlitCheckIn, blog: BlogSettings) throws -> URLRequest {
        guard checkIn.blogName == nil || checkIn.blogName == blog.blogName else { throw SourceError.invalidConfiguration }
        guard let postURL = checkIn.postURL, postURL.host != nil,
              ["http", "https"].contains(postURL.scheme?.lowercased() ?? "") else { throw SourceError.invalidPostURL }
        var request = try Self.authenticatedRequest(for: blog)
        var body = ["action": "delete", "url": postURL.absoluteString]
        if let destination = blog.snippetsConfiguration?.micropubUid, !destination.isEmpty {
            body["mp-destination"] = destination
        }
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
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

    func fetchCheckIns(limit: Int = 500, completion: @escaping (Result<[SunlitCheckIn], Error>) -> Void) {
        completion(.success(Array(self.checkIns.prefix(max(limit, 0)))))
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

    func deleteCheckIn(_ checkIn: SunlitCheckIn, blog: BlogSettings, completion: @escaping (Result<Void, Error>) -> Void) {
        self.checkIns.removeAll { $0.identifier == checkIn.identifier }
        completion(.success(()))
    }
}
#endif
