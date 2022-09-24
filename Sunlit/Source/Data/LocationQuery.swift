//
//  LocationQuery.swift
//  Evergreen
//
//  Created by Jonathan Hays on 6/30/21.
//

import UIKit
import CoreLocation
import UUSwift
import MapKit
import Snippets
import UUSwiftNetworking

extension SnippetsLocation
{
	static var currentLocationName = ""
	static var currentCity = ""
	static var currentState = ""
	static var currentCountry = ""
	static var currentLatitude = 0.0
	static var currentLongitude = 0.0
	static var nearbyVenues : [SnippetsLocation] = []
	
	// store map of venue name to icon
	// later would be better as real property on SnippetsLocation with all the Meridian fields
	static var icons : [ String: String ] = [:]

	class Query : NSObject, CLLocationManagerDelegate
	{
		static var locationChangedThreshold = 0.01
		static var locationProximityThreshold = 500.0
		static var locationAccuracyThreshold = 100.0

		static let nearbyVenuesUpdatedNotification = Notification.Name("SnippetsLocation Updated Notification")

		static var categories : [String] = [
			"restaurant", "store", "museum", "airport"
				//"bar", "theater", "school", "church", "gas", "restaurant", "coffee",
				//"zoo", "museum", "airport", "train", "mall", "arcade", "bookstore",
				//"bowling", "casino", "deli", "dance", "bagel", "library", "motel",
				//"hospital", "pharmacy", "park", "pool", "police", "bank", "pawnshop",
				//"gym", "hardware", "cafe", "salon", "military", "storage", "amusement",
				//"convenience"
		]

		static func scan()
		{
			SnippetsLocation.Query.shared.begin()
		}

		public static func search(searchString : String, _ completion: @escaping(([SnippetsLocation]) -> Void))
		{
			let location = CLLocation(latitude: SnippetsLocation.currentLatitude, longitude: SnippetsLocation.currentLongitude)

			findNearbyLocations(searchString, location) { venues in
				completion(venues)
//				let filteredVenues = filterByDistance(distance: SnippetsLocation.Query.locationProximityThreshold, latitude: SnippetsLocation.currentLatitude, longitude: SnippetsLocation.currentLongitude, venues: venues)
//
//				// If there aren't any nearby, then just return the closest...
//				if filteredVenues.count == 0 {
//					let closest = findClosest(latitude: SnippetsLocation.currentLatitude, longitude: SnippetsLocation.currentLongitude, venues: venues)
//					completion([closest])
//				}
//				else {
//					completion(filteredVenues)
//				}
			}
		}

		override private init()
		{
			super.init()
		}

		private func begin()
		{
			self.locationManager.requestAlwaysAuthorization()

			// For use in foreground
			self.locationManager.requestWhenInUseAuthorization()

			if CLLocationManager.locationServicesEnabled()
			{
				locationManager.delegate = self
				locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
				locationManager.startUpdatingLocation()
			}
		}

		func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
		{
			guard let location = manager.location else { return }

			SnippetsLocation.currentLatitude = location.coordinate.latitude
			SnippetsLocation.currentLongitude = location.coordinate.longitude

			self.geocoder.reverseGeocodeLocation(location)
			{ placemark, error in
				if let placemark : CLPlacemark = placemark?.first
				{
					SnippetsLocation.currentCity = placemark.locality ?? ""
					SnippetsLocation.currentState = placemark.administrativeArea ?? ""
					SnippetsLocation.currentCountry = placemark.country ?? ""
					SnippetsLocation.currentLocationName = placemark.areasOfInterest?.first ?? ""
				}
			}

			// We don't want to be re-entrant on this...
			if locationUpdateInProgress
			{
				return
			}

			let distanceMoved = location.distance(from: self.lastKnownLocation)

			// Make sure that the accuracy is high and that we've moved far enough that it matters...
			if  distanceMoved > SnippetsLocation.Query.locationChangedThreshold &&
				location.horizontalAccuracy > 0 &&
				location.horizontalAccuracy < SnippetsLocation.Query.locationAccuracyThreshold
			{
				self.locationUpdateInProgress = true
				self.lastKnownLocation = location

				SnippetsLocation.Query.findAllNearby(location) { venueData in

					self.locationUpdateInProgress = false

					SnippetsLocation.nearbyVenues = []
					for item in venueData
					{
						SnippetsLocation.nearbyVenues.append(item)
					}

					DispatchQueue.main.async {
						NotificationCenter.default.post(name: SnippetsLocation.Query.nearbyVenuesUpdatedNotification, object: SnippetsLocation.nearbyVenues)
					}
				}
			}
		}

		private static func findNearbyLocations(_ type : String, _ location : CLLocation, _ completion: @escaping(([SnippetsLocation]) -> Void))
		{
			// query the Meridian API
			let url = "https://api.latl.ong/places/nearby"
			let params = [
				"latitude": "45.539902",
				"longitude": "-122.629904"
			]
			UUHttpSession.get(url: url, queryArguments: params, completion: { response in
				var found_locations : [SnippetsLocation] = []
				
				if let places = response.parsedResponse as? [Dictionary<String, Any>] {
					for place in places {
						let venue = SnippetsLocation()
						if let latitude = place["latitude"] as? Double {
							venue.latitude = latitude
						}
						if let longitude = place["longitude"] as? Double {
							venue.longitude = longitude
						}
						if let name = place["name"] as? String {
							venue.name = name
						}
						if let icon = place["icon_carto"] as? String {
							SnippetsLocation.icons[venue.name] = icon
						}

						found_locations.append(venue)
					}
				}
				
				completion(found_locations)
			})
						
//			let request = MKLocalSearch.Request()
//			request.naturalLanguageQuery = type
//			request.region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: SnippetsLocation.Query.locationProximityThreshold, longitudinalMeters: SnippetsLocation.Query.locationProximityThreshold)
//			let search = MKLocalSearch(request: request)
//			search.start { response, error in
//
//				var foundLocations : [SnippetsLocation] = []
//
//				if let response = response,
//				   response.mapItems.count > 0
//				{
//					for item in response.mapItems
//					{
//						if item.isCurrentLocation
//						{
//							if let name = item.name
//							{
//								SnippetsLocation.currentLocationName = name
//							}
//						}
//
//						if let name = item.name
//						{
//							let venueData = SnippetsLocation()
//							venueData.latitude = item.placemark.coordinate.latitude
//							venueData.longitude = item.placemark.coordinate.longitude
//							venueData.name = name
//							venueData.category = item.pointOfInterestCategory
//
//							foundLocations.append(venueData)
//						}
//					}
//
//					completion(foundLocations)
//				}
//			}
		}

		static func findAllNearby(_ location : CLLocation, _ finalCompletion: @escaping(([SnippetsLocation])->Void))
		{
			var categories : [String] = SnippetsLocation.Query.categories
			var allLocations : [SnippetsLocation] = []
			var innerCompletion : (([SnippetsLocation])->Void) = { locations in }

			innerCompletion = { locations in
				for location in locations
				{
					allLocations.append(location)
				}

				if categories.count > 0
				{
					let category = categories.removeFirst()
					findNearbyLocations(category, location) { venues in
						let filteredVenues = filterByDistance(distance: SnippetsLocation.Query.locationProximityThreshold, latitude: SnippetsLocation.currentLatitude, longitude: SnippetsLocation.currentLongitude, venues: venues)
						innerCompletion(filteredVenues)
					}
				}
				else
				{
					finalCompletion(allLocations)
				}
			}

			let category = categories.removeFirst()
			self.findNearbyLocations(category, location, innerCompletion)
		}

		static func filterByDistance(distance : Double, latitude : Double, longitude : Double, venues : [SnippetsLocation]) -> [SnippetsLocation]
		{
			let location = CLLocation(latitude: latitude, longitude: longitude)
			var filteredVenues : [SnippetsLocation] = []
			for venue in venues {
				let locationDistance = CLLocation(latitude: venue.latitude, longitude: venue.longitude).distance(from: location)
				if locationDistance < distance
				{
					filteredVenues.append(venue)
				}
			}

			return filteredVenues
		}

		static func findClosest(latitude : Double, longitude : Double, venues : [SnippetsLocation]) -> SnippetsLocation
		{
			let location = CLLocation(latitude: latitude, longitude: longitude)
			var closestVenue = venues.first!
			var closestDistance = CLLocation(latitude: closestVenue.latitude, longitude: closestVenue.longitude).distance(from: location)
			for venue in venues {
				let venueDistance = CLLocation(latitude: venue.latitude, longitude: venue.longitude).distance(from: location)
				if venueDistance < closestDistance {
					closestDistance = venueDistance
					closestVenue = venue
				}
			}

			return closestVenue
		}

		private var locationManager = CLLocationManager()
		private var geocoder = CLGeocoder()
		private var lastKnownLocation = CLLocation()
		private var locationUpdateInProgress = false
		private static let shared = SnippetsLocation.Query()
	}
}
