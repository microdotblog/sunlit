//
//  NearbyLocationsViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 8/8/21.
//  Copyright © 2021 Micro.blog, LLC. All rights reserved.
//

import UIKit
import Snippets
import MapKit

class NearbyLocationsViewController: UIViewController {

	@IBOutlet var tableView : UITableView!
	@IBOutlet var searchField : UITextField!
	@IBOutlet var busyIndicator : UIActivityIndicatorView!

	var nearbyVenues : [SnippetsLocation] = []

    override func viewDidLoad() {
        super.viewDidLoad()

		self.setupNotifications()
		self.setupNavigation()
    }

	func setupNotifications() {
		NotificationCenter.default.addObserver(self, selector: #selector(handleLocationsUpdatedNotification(_:)), name: SnippetsLocation.Query.nearbyVenuesUpdatedNotification, object: nil)
	}
	
	func setupNavigation() {
		self.navigationItem.title = "New Check-in"
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Continue", style: .plain, target: self, action: #selector(onContinue))
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(onCancel))
	}

	@objc func onContinue() {
		// prompt for optional text
		// ...
	}

	@objc func onCancel() {
		self.dismiss(animated: true)
	}
	
	@objc func handleLocationsUpdatedNotification(_ notification : Notification) {

		self.busyIndicator.isHidden = true

		// Ignore if text in the text field...
		if let text = self.searchField.text,
		   text.count > 0 {
			return
		}

		self.nearbyVenues = SnippetsLocation.nearbyVenues
		self.tableView.reloadData()
	}
}

extension NearbyLocationsViewController : UITextFieldDelegate
{
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		if let text = textField.text,
		   text.count > 0
		{
			SnippetsLocation.Query.search(searchString: text) { nearbyVenues in
				self.nearbyVenues = nearbyVenues
				self.tableView.reloadData()
			}
		}

		return false
	}
}

extension NearbyLocationsViewController : UITableViewDataSource, UITableViewDelegate {

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.nearbyVenues.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "NearbyLocationsTableViewCell") as! NearbyLocationsTableViewCell
		let venue = nearbyVenues[indexPath.row]
		cell.locationNameLabel.text = venue.name

		cell.categoryImageView.image = nil
		if var icon = SnippetsLocation.icons[venue.name] {
			// temporary fix because of missing icons
			if icon == "amenity/school" {
				icon = "amenity/community_centre"
			}
			if icon == "cuisine/pizza" {
				icon = "amenity/restaurant"
			}
			if let img = UIImage(named: "Carto/\(icon)") {
				cell.categoryImageView.image = img
			}
		}
				
		cell.map.delegate = self
		cell.map.isUserInteractionEnabled = false

		let location = CLLocationCoordinate2D(latitude: venue.latitude, longitude: venue.longitude)
		let region = MKCoordinateRegion( center: location, latitudinalMeters: CLLocationDistance(exactly: 500)!, longitudinalMeters: CLLocationDistance(exactly: 500)!)

		cell.map.setRegion(cell.map.regionThatFits(region), animated: false)

//		cell.map.removeAnnotations(cell.map.annotations)
//		let objectAnnotation = MKPointAnnotation()
//		objectAnnotation.coordinate = location
//		objectAnnotation.title = ""
//		cell.map.addAnnotation(objectAnnotation)

		return cell
	}

}

extension NearbyLocationsViewController : MKMapViewDelegate {

	func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
		if fullyRendered {
			mapView.alpha = 1.0
		}
	}

}
