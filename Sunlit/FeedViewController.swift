//
//  FeedViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/3/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class FeedViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITableViewDataSourcePrefetching {

	@IBOutlet var tableView : UITableView!
	
	var tableViewData : [SunlitPost] = []
	
    override func viewDidLoad() {
        super.viewDidLoad()

		NotificationCenter.default.addObserver(self, selector: #selector(handleTemporaryTokenReceivedNotification(_:)), name: NSNotification.Name("TemporaryTokenReceivedNotification"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleImageLoadedNotification(_:)), name: NSNotification.Name("Feed Image Loaded"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleUserProfileSelectedNotification), name: NSNotification.Name("Display User Profile"), object: nil)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		self.setupSnippets()
	}

	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */
	
	func refreshTableView(_ entries : [SnippetsPost]) {
		
		var posts : [SunlitPost] = []
		
		for entry in entries {
			let post = HTMLParser.parse(entry)
			posts.append(post)
		}
		
		self.tableViewData = posts
		self.tableView.reloadData()
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.tableViewData.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		let cell = tableView.dequeueReusableCell(withIdentifier: "FeedTableViewCell", for: indexPath) as! FeedTableViewCell
		let post = self.tableViewData[indexPath.row]
		cell.setup(indexPath.row, post)
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
	
		for indexPath in indexPaths {
			self.prefetchImages(indexPath)
		}
	}
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		self.prefetchImages(indexPath)
	}
	
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		let post = self.tableViewData[indexPath.row]

		let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
		let imageViewController = storyBoard.instantiateViewController(withIdentifier: "ImageViewerViewController") as! ImageViewerViewController
		imageViewController.pathToImage = post.images[0]
		self.navigationController?.pushViewController(imageViewController, animated: true)
	}

	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	@objc func handleImageLoadedNotification(_ notification : Notification) {
		if let index = notification.object as? Int {
			self.tableView.reloadRows(at: [ IndexPath(row: index, section: 0)], with: .fade)
		}
	}
	
	@objc func handleTemporaryTokenReceivedNotification(_ notification : Notification) {
		if let temporaryToken = notification.object as? String
		{
			Snippets.shared.requestPermanentTokenFromTemporaryToken(token: temporaryToken) { (error, token) in
				if let permanentToken = token
				{
					Settings.savePermanentToken(permanentToken)
					Snippets.shared.configure(permanentToken: permanentToken, blogUid: nil)
					
					Dialog.information("You have successfully logged in.", self)
					
					self.loadTimeline()
				}
			}
		}
	}
	
	@objc func handleUserProfileSelectedNotification(_ notification : Notification) {
		if let user = notification.object as? SunlitUser {
			let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
			let profileViewController = storyBoard.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
			profileViewController.user = user
			
			let navViewController = UINavigationController(rootViewController: profileViewController)
			self.present(navViewController, animated: true, completion: nil)
		}
	}
	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */
	func configureCollectionView() {
		
	}
	
	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	func loadTimeline() {
		
		Snippets.shared.fetchCurrentUserPhotoTimeline { (error, postObjects : [SnippetsPost]) in
			DispatchQueue.main.async {
				self.refreshTableView(postObjects)
			}
		}
		
	}

	func setupSnippets() {

		if let token = Settings.permanentToken() {
			Snippets.shared.configure(permanentToken: token, blogUid: nil)
			
			self.loadTimeline()
		}
		else {
			self.showLoginDialog()
		}
	}
	
	func showLoginDialog() {
		let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let loginViewController = storyboard.instantiateViewController(identifier: "LoginViewController")

        show(loginViewController, sender: self)
	}
	
	func prefetchImages(_ indexPath : IndexPath) {
		let post = self.tableViewData[indexPath.row]
		let imageSource = post.images[0]
		
		if ImageCache.prefetch(imageSource) == nil {
			ImageCache.fetch(imageSource) { (image) in
				if let _ = image {
					DispatchQueue.main.async {
						NotificationCenter.default.post(name: NSNotification.Name(rawValue: "Feed Image Loaded"), object: indexPath.row)
					}
				}
			}
		}
		
		let avatarSource = post.owner.pathToUserImage
		if ImageCache.prefetch(avatarSource) == nil {
			ImageCache.fetch(avatarSource) { (image) in
				if let _ = image {
					DispatchQueue.main.async {
						NotificationCenter.default.post(name: NSNotification.Name(rawValue: "Feed Image Loaded"), object: indexPath.row)
					}
				}
			}
		}
	}
	
}


/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

class FeedTableViewCell : UITableViewCell {
	
	//@IBOutlet var collectionView : UICollectionView!
	@IBOutlet var postImage : UIImageView!
	@IBOutlet var textView : UITextView!
	@IBOutlet var dateLabel : UILabel!
	@IBOutlet var userAvatar : UIImageView!
	@IBOutlet var userName : UILabel!
	@IBOutlet var userHandle : UILabel!
	@IBOutlet var heightConstraint : NSLayoutConstraint!
	
	var user : SunlitUser!
	
	func setup(_ index: Int, _ post : SunlitPost) {
		
		let owner = post.owner
		self.user = owner
		
		// Configure the user avatar
		self.userAvatar.clipsToBounds = true
		self.userAvatar.layer.cornerRadius = (self.userAvatar.bounds.size.height - 1) / 2.0

		// Update the text objects
		self.textView.attributedText = post.text
		self.userHandle.text = "@" + owner.userHandle
		self.userName.text = owner.fullName
		
		// Configure the photo sizes...
		self.setupPhotoAspectRatio(post)
		
		// Kick off the photo loading...
		self.loadPhotos(post, owner, index)
		
		// Add the user profile tap gestures where appropriate...
		self.addUserProfileTapGesture(self.userName)
		self.addUserProfileTapGesture(self.userAvatar)
		self.addUserProfileTapGesture(self.userHandle)
	}
	
	func setupPhotoAspectRatio(_ post : SunlitPost) {
		let width : CGFloat = UIApplication.shared.windows.first!.bounds.size.width
		let maxHeight = UIApplication.shared.windows.first!.bounds.size.height - 100
		var height : CGFloat = width * CGFloat(post.aspectRatio)
		if height > maxHeight {
			height = maxHeight
		}
		self.heightConstraint.constant = height

	}
	
	func loadPhotos(_ post : SunlitPost, _ owner : SunlitUser, _ index : Int) {
		let imageSource = post.images[0]
		if let image = ImageCache.prefetch(imageSource) {
			self.postImage.image = image
		}
		
		let avatarSource = owner.pathToUserImage
		if let avatar = ImageCache.prefetch(avatarSource) {
			self.userAvatar.image = avatar
		}
	}
	
	func addUserProfileTapGesture(_ view : UIView) {
		view.isUserInteractionEnabled = true

		for gesture in view.gestureRecognizers ?? [] {
			view.removeGestureRecognizer(gesture)
		}

		let gesture = UITapGestureRecognizer(target: self, action: #selector(handleUserTappedGesture))
		view.addGestureRecognizer(gesture)
	}
	
	@objc func handleUserTappedGesture() {
		NotificationCenter.default.post(name: NSNotification.Name("Display User Profile"), object: self.user)
	}
}


/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

class FeedCollectionViewCell : UICollectionViewCell {
	
}


