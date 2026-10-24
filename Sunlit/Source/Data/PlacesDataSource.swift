import Foundation
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
}

// The API routes and response format can be added without changing the screens.
protocol PlacesDataSource {
    var isPreview: Bool { get }
    func fetchCheckIns(completion: @escaping (Result<[SunlitCheckIn], Error>) -> Void)
    func searchPlaces(matching query: String, completion: @escaping (Result<[SunlitPlace], Error>) -> Void)
    func checkIn(at place: SunlitPlace, note: String, completion: @escaping (Result<SunlitCheckIn, Error>) -> Void)
}

func makePlacesDataSource() -> PlacesDataSource {
    #if DEBUG
    return PreviewPlacesDataSource()
    #else
    return UnavailablePlacesDataSource()
    #endif
}

private struct PlacesUnavailableError: LocalizedError {
    var errorDescription: String? { "Places isn’t available yet. Please check back in a future update." }
}

private final class UnavailablePlacesDataSource: PlacesDataSource {
    let isPreview = false

    func fetchCheckIns(completion: @escaping (Result<[SunlitCheckIn], Error>) -> Void) {
        completion(.failure(PlacesUnavailableError()))
    }

    func searchPlaces(matching query: String, completion: @escaping (Result<[SunlitPlace], Error>) -> Void) {
        completion(.failure(PlacesUnavailableError()))
    }

    func checkIn(at place: SunlitPlace, note: String, completion: @escaping (Result<SunlitCheckIn, Error>) -> Void) {
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

    func checkIn(at place: SunlitPlace, note: String, completion: @escaping (Result<SunlitCheckIn, Error>) -> Void) {
        let checkIn = SunlitCheckIn(identifier: UUID().uuidString, place: place, date: Date(), note: note)
        self.checkIns.insert(checkIn, at: 0)
        completion(.success(checkIn))
    }
}
#endif
