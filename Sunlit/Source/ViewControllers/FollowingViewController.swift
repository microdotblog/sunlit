//
//  FollowingViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 8/4/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import Snippets

class FollowingViewController: UIViewController {

	@IBOutlet var tableView : UITableView!
	
	var following : [SnippetsUser] = []
	var userToLoad: SnippetsUser?
	var onFollowingLoaded: (([SnippetsUser]) -> Void)?
	var visible = false
	private var loading = false
	private let loadingIndicator = UIActivityIndicatorView(style: .large)
	
    override func viewDidLoad() {
        super.viewDidLoad()

		self.setupNavigation()
		self.setupGesture()
		if self.userToLoad != nil {
			self.loadingIndicator.hidesWhenStopped = true
			self.loadingIndicator.accessibilityLabel = "Loading following"
			self.loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
			self.view.addSubview(self.loadingIndicator)
			NSLayoutConstraint.activate([
				self.loadingIndicator.centerXAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor),
				self.loadingIndicator.centerYAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerYAnchor)
			])
			let refreshControl = UIRefreshControl()
			refreshControl.addTarget(self, action: #selector(loadFollowing), for: .valueChanged)
			self.tableView.refreshControl = refreshControl
			self.loadFollowing()
		}
	}

	@objc private func loadFollowing() {
		guard !self.loading, let user = self.userToLoad else { return }
		self.loading = true
		let accountGeneration = Settings.accountGeneration
		if self.following.isEmpty { self.loadingIndicator.startAnimating() }
		Snippets.Microblog.listFollowing(user: user, completeList: true) { [weak self] error, users in
			DispatchQueue.main.async {
				guard let self = self, accountGeneration == Settings.accountGeneration,
					self.userToLoad?.username == user.username else { return }
				self.loading = false
				self.loadingIndicator.stopAnimating()
				self.tableView.refreshControl?.endRefreshing()
				if let error = error {
					if self.visible { Dialog(self).information(error.localizedDescription) }
					return
				}
				self.following = users
				self.tableView.reloadData()
				self.onFollowingLoaded?(users)
			}
		}
	}

	func setupNavigation() {
		self.navigationItem.title = "Following"
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(dismissViewController))
	}
	
	func setupGesture() {
		let gesture = UISwipeGestureRecognizer(target: self, action: #selector(dismissViewController))
		gesture.direction = .right
		self.view.addGestureRecognizer(gesture)
	}

	@objc func dismissViewController() {
		self.navigationController?.popViewController(animated: true)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.visible = true
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		self.visible = false
	}
	
	func loadPhoto(_ path : String,  _ index : IndexPath) {
		
		// If the photo exists, bail!
		if ImageCache.prefetch(path) != nil {
			return
		}
		
		ImageCache.fetch(path) { (image) in
			
			if let image = image {
				DispatchQueue.main.async {
					guard self.visible, self.following.indices.contains(index.row),
						self.following[index.row].avatarURL == path,
						let cell = self.tableView.cellForRow(at: index) as? ProfileTableViewCell else { return }
					cell.avatar.image = image
				}
			}
		}
	}

}

extension FollowingViewController : UITableViewDelegate, UITableViewDataSource {

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileTableViewCell", for: indexPath) as! ProfileTableViewCell
		let user = self.following[indexPath.row]
		cell.setup(user, indexPath)
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		let user = self.following[indexPath.row]
		self.loadPhoto(user.avatarURL, indexPath)
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.following.count
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let user = self.following[indexPath.row]
		NotificationCenter.default.post(name: .viewUserProfileNotification, object: user)
	}

}
