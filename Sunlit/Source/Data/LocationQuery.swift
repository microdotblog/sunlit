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


extension SnippetsLocation
{
	static var currentLocationName = ""
	static var currentCity = ""
	static var currentState = ""
	static var currentCountry = ""
	static var currentLatitude = 0.0
	static var currentLongitude = 0.0
	static var nearbyVenues : [SnippetsLocation] = []

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
			findNearbyLocations(searchString, location, completion)
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
			print("Searching for locations of type " + type)

			let request = MKLocalSearch.Request()
			request.naturalLanguageQuery = type
			request.region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: SnippetsLocation.Query.locationProximityThreshold, longitudinalMeters: SnippetsLocation.Query.locationProximityThreshold)
			let search = MKLocalSearch(request: request)
			search.start { response, error in

				var foundLocations : [SnippetsLocation] = []

				if let response = response,
				   response.mapItems.count > 0
				{
					for item in response.mapItems
					{
						if item.isCurrentLocation
						{
							if let name = item.name
							{
								SnippetsLocation.currentLocationName = name
							}
						}

						let placeLocation = item.placemark.coordinate
						let distance = CLLocation(latitude: placeLocation.latitude, longitude: placeLocation.longitude).distance(from: location)
						if distance < SnippetsLocation.Query.locationProximityThreshold
						{
							if let name = item.name
							{
								let venueData = SnippetsLocation()
								venueData.latitude = item.placemark.coordinate.latitude
								venueData.longitude = item.placemark.coordinate.longitude
								venueData.name = name

								foundLocations.append(venueData)
							}
						}
					}

					completion(foundLocations)
				}
			}

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
					findNearbyLocations(category, location, innerCompletion)
				}
				else
				{
					finalCompletion(allLocations)
				}
			}

			let category = categories.removeFirst()
			self.findNearbyLocations(category, location, innerCompletion)
		}

		private var locationManager = CLLocationManager()
		private var geocoder = CLGeocoder()
		private var lastKnownLocation = CLLocation()
		private var locationUpdateInProgress = false
		private static let shared = SnippetsLocation.Query()
	}
}
