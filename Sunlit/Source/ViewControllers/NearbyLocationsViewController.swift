//
//  NearbyLocationsViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 8/8/21.
//  Copyright © 2021 Micro.blog, LLC. All rights reserved.
//

import UIKit
import Snippets

class NearbyLocationsViewController: UIViewController {

	@IBOutlet var tableView : UITableView!
	@IBOutlet var searchField : UITextField!

	var nearbyVenues : [SnippetsLocation] = []

    override func viewDidLoad() {
        super.viewDidLoad()

		NotificationCenter.default.addObserver(self, selector: #selector(handleLocationsUpdatedNotification(_:)), name: SnippetsLocation.Query.nearbyVenuesUpdatedNotification, object: nil)
    }

	@objc func handleLocationsUpdatedNotification(_ notification : Notification) {
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
		let cell = tableView.dequeueReusableCell(withIdentifier: "NearbyLocationsTableViewCell", for: indexPath) as! NearbyLocationsTableViewCell
		let venue = nearbyVenues[indexPath.row]
		cell.locationNameLabel.text = venue.name
		return cell
	}

}
