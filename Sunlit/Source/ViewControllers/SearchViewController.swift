//
//  SearchViewController.swift
//  Sunlit
//
//  Created by Manton Reece on 8/22/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import Snippets

class SearchViewController: UIViewController, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate, UITableViewDataSourcePrefetching {

	@IBOutlet var searchBar : UISearchBar!
	@IBOutlet var tableView : UITableView!
	
	var results: [ SnippetsUser ] = []
	var delayTimer: Timer? = nil
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.searchBar.becomeFirstResponder()
	}

	func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
		if let timer = self.delayTimer {
			timer.invalidate()
			self.delayTimer = nil
		}
		
		self.delayTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { Timer in
			Snippets.shared.searchUsers(searchText) { error, users in
				DispatchQueue.main.async {
					self.results = users
					self.tableView.reloadData()
				}
			}
		}
	}

	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		self.searchBar.resignFirstResponder()
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return results.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let user = self.results[indexPath.row]
		
		let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultTableViewCell", for: indexPath) as! SearchResultTableViewCell
		cell.setup(user, indexPath)
		
		return cell
	}
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let user = self.results[indexPath.row]
            self.loadAvatarPhoto(user.avatarURL, indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let user = self.results[indexPath.row]
        self.loadAvatarPhoto(user.avatarURL, indexPath)
    }

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let user = self.results[indexPath.row]
		NotificationCenter.default.post(name: .viewUserProfileNotification, object: user)
	}

    func loadAvatarPhoto(_ path : String,  _ indexPath : IndexPath) {
        
        // If the photo exists, bail!
        if ImageCache.prefetch(path) != nil {
            return
        }
        
        ImageCache.fetch(self, path) { (image) in
            if let _ = image {
                DispatchQueue.main.async {
                    if let visibleIndexPaths = self.tableView.indexPathsForVisibleRows {
                     
                        if visibleIndexPaths.contains(indexPath) {
                            self.tableView.performBatchUpdates {
                                self.tableView.reloadRows(at: [indexPath], with: .automatic)
                            }
                            completion: { (complete) in
                            }
                        }
                    }
                }
            }
        }
    }
}
