//
//  MyProfileViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/9/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import SafariServices
import Snippets

class MyProfileViewController: ContentViewController {
		
	var user : SnippetsUser!
	var updatedUserInfo : SnippetsUser? = nil
	var userPosts : [SunlitPost] = []
	var followingUsers : [SnippetsUser] = []
	var loadInProgress = false
	var followersLoaded = false
	var refreshControl = UIRefreshControl()
	
	@IBOutlet var collectionView : UICollectionView!
	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */
	
    override func viewDidLoad() {
        super.viewDidLoad()

		if let user = SnippetsUser.current() {
			self.user = user
			self.navigationItem.title = "Profile"
		}

        self.refreshControl.addTarget(self, action: #selector(fetchUserInfo), for: .valueChanged)
        self.collectionView.addSubview(self.refreshControl)
        
        self.setupNavigation()
        self.setupNotifications()
        self.prepareToDisplay()
	}

    override func setupNotifications() {
        super.setupNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(handleUserMentionsUpdated), name: .mentionsUpdatedNotification, object: nil)
    }

    override func prepareToDisplay() {
        super.prepareToDisplay()
        self.collectionView.reloadData()

        NotificationCenter.default.addObserver(self, selector: #selector(handleCurrentUserUpdatedNotification), name: .currentUserUpdatedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleUserMentionsUpdated), name: .mentionsUpdatedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleViewFollowingButtonClickedNotification), name: .followingButtonClickedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleViewConversationNotification(_:)), name: .viewConversationNotification, object: nil)

        self.fetchUserInfo()
    }
    
    override func setupNavigation() {
        super.setupNavigation()
        let settingsButton = UIBarButtonItem(image: UIImage(systemName: "gearshape"), style: .plain, target: self, action: #selector(onSettings))
        self.navigationItem.rightBarButtonItem = settingsButton
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(onClose))
    }
		
    @objc func onSettings() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Settings", bundle: nil)
        let settingsViewController = storyBoard.instantiateViewController(withIdentifier: "SettingsViewController")
        let navigationController = UINavigationController(rootViewController: settingsViewController)
        self.present(navigationController, animated: true, completion: nil)
    }
    
    @objc func onClose()
    {
        self.dismiss(animated: true)
    }
    
	@objc func handleCurrentUserUpdatedNotification() {
		if let user = SnippetsUser.current() {
			self.user = user
			self.fetchUserInfo()
			self.navigationItem.title = user.fullName
		}
	}
	
	@objc func handleViewFollowingButtonClickedNotification() {
		NotificationCenter.default.post(name: .showFollowingNotification, object: self.followingUsers)
	}
	
	@objc func handleUserMentionsUpdated() {
//		self.collectionView.reloadItems(at: [IndexPath(item: 0, section: 0)])
	}

	@objc func handleViewConversationNotification(_ notification : Notification) {
		if let post = notification.object as? SunlitPost {
			let storyBoard: UIStoryboard = UIStoryboard(name: "Conversation", bundle: nil)
			let conversationViewController = storyBoard.instantiateViewController(withIdentifier: "ConversationViewController") as! ConversationViewController
			conversationViewController.sourcePost = post
			self.navigationController?.pushViewController(conversationViewController, animated: true)
		}
	}

	@objc func fetchUserInfo() {
		
		if self.loadInProgress == true {
			return
		}
		
		self.loadInProgress = true
		
		Snippets.Microblog.fetchCurrentUserInfo { (error, snippetsUser) in
			
            if let updatedUser = snippetsUser {
				self.user = SnippetsUser.save(updatedUser)

				DispatchQueue.main.async {
					self.collectionView.reloadData()
				}

				Snippets.Microblog.fetchUserMediaPosts(user: updatedUser) { (error, snippets : [SnippetsPost]) in
	
					DispatchQueue.main.async {

						var posts : [SunlitPost] = []
						for snippet in snippets {
							let sunlitPost = SunlitPost.create(snippet)
							posts.append(sunlitPost)
						}

						self.loadInProgress = false
						self.userPosts = posts
						self.collectionView.reloadData()
						self.refreshControl.endRefreshing()
					}
				}
				
				Snippets.Microblog.listFollowing(user: self.user, completeList: true) { (error, users) in
					self.followingUsers = users
					self.followersLoaded = true
					self.user.followingCount = users.count
					self.user = SnippetsUser.saveAsCurrent(self.user)
					
					DispatchQueue.main.async {
						self.collectionView.reloadData()
					}
				}
			}
		}
	}
		
	func loadPhoto(_ path : String,  _ index : IndexPath) {
		
		// If the photo exists, bail!
		if ImageCache.prefetch(path) != nil {
			return
		}
		
		ImageCache.fetch(path) { (image) in
			if let _ = image {
				DispatchQueue.main.async {
					self.collectionView.performBatchUpdates({
						self.collectionView.reloadItems(at: [ index ])
					}, completion: nil)
				}
			}
		}
	}
	

	@IBAction func onShowLogin() {
		NotificationCenter.default.post(name: .showLoginNotification, object: nil)
	}

	@IBAction func onShowMentions() {
		
	}
	
}



/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

extension MyProfileViewController : UITextViewDelegate {
	
	func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
		let safariViewController = SFSafariViewController(url: URL)
		self.present(safariViewController, animated: true, completion: nil)
		return false
	}
	
}



/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

extension MyProfileViewController : UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSourcePrefetching {
	
	func numberOfSections(in collectionView: UICollectionView) -> Int {
		
		// Check for the logged out state...
		if Settings.snippetsToken() == nil {
			return 0
		}
		
		return 4
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		
		if self.user == nil {
			return 0
		}
		
		if section == 0 || section == 1 || section == 3 {
			return 1
		}

		return self.userPosts.count
	}
		
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		
		if indexPath.section == 0 {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProfileHeaderCollectionViewCell", for: indexPath) as! ProfileHeaderCollectionViewCell
			self.configureHeaderCell(cell, indexPath)
			return cell
		}
		else if indexPath.section == 1 {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProfileBioCollectionViewCell", for: indexPath) as! ProfileBioCollectionViewCell
			self.configureBioCell(cell)
			return cell
		}
		else if indexPath.section == 3 {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoEntryCollectionViewSpacerCell", for: indexPath)
			return cell
		}
		else {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoEntryCollectionViewCell", for: indexPath) as! PhotoEntryCollectionViewCell
			self.configurePhotoCell(cell, indexPath)
			return cell
		}
	}
	
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath){
		
		collectionView.deselectItem(at: indexPath, animated: true)
		
		if indexPath.section == 2 {
			if indexPath.item < self.userPosts.count {
				let post = self.userPosts[indexPath.item]
				let imagePath = post.images[0]
				var dictionary : [String : Any] = [:]
				dictionary["imagePath"] = imagePath
				dictionary["post"] = post
			
				NotificationCenter.default.post(name: .viewPostNotification, object: dictionary)
			}
		}
	}
	
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

		var collectionViewWidth = collectionView.bounds.size.width
		
		if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
			collectionViewWidth = collectionViewWidth - flowLayout.sectionInset.left
			collectionViewWidth = collectionViewWidth - flowLayout.sectionInset.right
			
			collectionViewWidth = collectionViewWidth - collectionView.contentInset.left
			collectionViewWidth = collectionViewWidth - collectionView.contentInset.right
		}
		
		if indexPath.section == 0 {
			return ProfileHeaderCollectionViewCell.sizeOf(self.user, collectionViewWidth: collectionViewWidth)
		}
		else if indexPath.section == 1 {
			return ProfileBioCollectionViewCell.sizeOf(self.user, collectionViewWidth:collectionViewWidth)
		}
		else if indexPath.section == 3 {
			return CGSize(width: collectionViewWidth, height: 60.0)
		}
		else {
			return PhotoEntryCollectionViewCell.sizeOf(collectionViewWidth: collectionViewWidth)
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		if indexPath.section == 2 {
			if indexPath.item < self.userPosts.count {
				let post = self.userPosts[indexPath.item]
				self.loadPhoto(post.images.first ?? "", indexPath)
			}
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
		for indexPath in indexPaths {
			if indexPath.section == 2 {
				let post = self.userPosts[indexPath.item]
				self.loadPhoto(post.images.first ?? "", indexPath)
			}
		}
	}
	
	func configureHeaderCell(_ cell : ProfileHeaderCollectionViewCell, _ indexPath : IndexPath) {
		
		cell.avatar.clipsToBounds = true
		cell.avatar.layer.cornerRadius = (cell.avatar.bounds.size.height - 1) / 2.0
			
		cell.fullName.text = user.fullName
		cell.userHandle.text = "@" + user.username
		
		var address = user.siteURL
		if address.count > 0 && !address.contains("http") {
			address = "https://" + address
		}
		cell.blogAddress .setTitle(address, for: .normal)
		if let image = ImageCache.prefetch(user.avatarURL) {
			cell.avatar.image = image
		}
		else {
			cell.avatar.image = nil // UIImage(named: "welcome_waves")
			self.loadPhoto(user.avatarURL, indexPath)
		}
		
		cell.configureFollowing(count: self.followingUsers.count, complete: self.followersLoaded)
	}
	
	func configureBioCell(_ cell : ProfileBioCollectionViewCell) {
		cell.bio.text = user.bio
		//cell.bio.attributedText = user.attributedTextBio()
		cell.widthConstraint.constant = self.view.bounds.size.width - 16.0
	}
	
	func configurePhotoCell(_ cell : PhotoEntryCollectionViewCell, _ indexPath : IndexPath) {
		if indexPath.item < self.userPosts.count {
			let post = self.userPosts[indexPath.item]
			cell.date.text = ""
			if let date = post.publishedDate {
				cell.date.text = date.friendlyFormat()
			}

			cell.photo.image = nil
			if let image = ImageCache.prefetch(post.images.first ?? "") {
				cell.photo.image = image
			}
		}

		cell.contentView.clipsToBounds = true
	}
	
}



