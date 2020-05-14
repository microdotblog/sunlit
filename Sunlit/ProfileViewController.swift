//
//  ProfileViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/7/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSourcePrefetching {
		
	var user : SnippetsUser!
	var updatedUserInfo : SnippetsUser? = nil
	var userPosts : [SunlitPost] = []
	
	@IBOutlet var collectionView : UICollectionView!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		if let flowLayout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
			flowLayout.estimatedItemSize = CGSize(width: self.view.frame.size.width, height: 200)
		}
		
		// Merge if we can/need to from the user cache...
		self.user = SnippetsUser.save(self.user)
		
		if self.user.bio.count > 0 {
			self.fetchUserPosts()
		}
		else {
			self.fetchUserInfo(user)
		}
		
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissViewController))
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.navigationController?.setNavigationBarHidden(false, animated: true)
	}
    
	@objc func dismissViewController() {
		self.navigationController?.popViewController(animated: true)
	}
	
	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	func fetchUserInfo(_ user : SnippetsUser) {
		Snippets.shared.fetchUserDetails(user: user) { (error, updatedUser, posts : [SnippetsPost]) in
			
			if let snippetsUser = updatedUser {
				self.user = SnippetsUser.save(snippetsUser)
				
				self.updatedUserInfo = self.user
			
				DispatchQueue.main.async {
					self.collectionView.reloadData()
					
					if self.userPosts.count <= 0 {
						self.fetchUserPosts()
					}
				}
			}
		}
	}
	
	func fetchUserPosts() {
		Snippets.shared.fetchUserMediaPosts(user: self.user) { (error, snippets: [SnippetsPost]) in

			var posts : [SunlitPost] = []
			for snippet in snippets {
				let post = SunlitPost.create(snippet)
				posts.append(post)
			}
			
			DispatchQueue.main.async {
				self.userPosts = posts
				self.collectionView.reloadData()
				
				self.fetchUserInfo(self.user)
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
					self.collectionView.reloadItems(at: [ index ])
				}
			}
		}
	}
	
	@objc func onFollowUser() {
		if self.user.isFollowing {
			Snippets.shared.unfollow(user: self.user) { (error) in
				if error == nil {
					self.user.isFollowing = false
					self.user = SnippetsUser.save(self.user)
					
					DispatchQueue.main.async {
						self.collectionView.reloadData()
					}
				}
			}
		}
		else {
			Snippets.shared.follow(user: self.user) { (error) in
				if error == nil {
					self.user.isFollowing = true
					self.user = SnippetsUser.save(self.user)
					
					DispatchQueue.main.async {
						self.collectionView.reloadData()
					}
				}
			}

		}
	}

	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */
	
	func numberOfSections(in collectionView: UICollectionView) -> Int {
		if self.userPosts.count == 0 {
			return 2
		}
		
		return 3
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		
		if section == 0 || section == 1 {
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
		else {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoEntryCollectionViewCell", for: indexPath) as! PhotoEntryCollectionViewCell
			self.configurePhotoCell(cell, indexPath)
			return cell
		}
	}
	
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath){
		
		collectionView.deselectItem(at: indexPath, animated: true)
		
		if indexPath.section == 2 {
			let post = self.userPosts[indexPath.item]
			
			let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
			let imageViewController = storyBoard.instantiateViewController(withIdentifier: "ImageViewerViewController") as! ImageViewerViewController
			imageViewController.pathToImage = post.images[0]
			self.navigationController?.pushViewController(imageViewController, animated: true)
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
	
	func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		if indexPath.section == 2 {
			let post = self.userPosts[indexPath.item]
			self.loadPhoto(post.images.first ?? "", indexPath)
		}
	}
	
	func configureHeaderCell(_ cell : ProfileHeaderCollectionViewCell, _ indexPath : IndexPath) {
		cell.followButton.clipsToBounds = true
		cell.followButton.layer.cornerRadius = (cell.followButton.bounds.size.height - 1) / 2.0
		cell.followButton.setTitle("Unfollow", for: .normal)
		cell.followButton.isHidden = true
		cell.followButton.addTarget(self, action: #selector(onFollowUser), for: .touchUpInside)
		
		if self.user.isFollowing {
			cell.followButton.setTitle("Unfollow", for: .normal)
			cell.followButton.isHidden = false
		}
		else if self.updatedUserInfo != nil {
			cell.followButton.isHidden = false
			cell.followButton.setTitle("Follow", for: .normal)
		}
			
		cell.avatar.clipsToBounds = true
		cell.avatar.layer.cornerRadius = (cell.avatar.bounds.size.height - 1) / 2.0
			
		cell.fullName.text = user.fullName
		cell.userHandle.text = "@" + user.userHandle
		cell.blogAddress.setTitle(user.pathToWebSite, for: .normal)
			
		if let image = ImageCache.prefetch(user.pathToUserImage) {
			cell.avatar.image = image
		}
		else {
			cell.avatar.image = UIImage(named: "welcome_waves")
			self.loadPhoto(user.pathToUserImage, indexPath)
		}

		// Make sure the cell goes the entire width
		cell.widthConstraint.constant = collectionView.frame.size.width
	}
	
	func configureBioCell(_ cell : ProfileBioCollectionViewCell) {
		cell.bio.attributedText = user.attributedTextBio()
		cell.widthConstraint.constant = self.collectionView.frame.size.width - 16
	}
	
	func configurePhotoCell(_ cell : PhotoEntryCollectionViewCell, _ indexPath : IndexPath) {
		let post = self.userPosts[indexPath.item]
		cell.date.text = ""
		if let date = post.publishedDate {
			cell.date.text = date.uuRfc3339String()
		}

		cell.photo.image = nil

		if let image = ImageCache.prefetch(post.images.first ?? "") {
			cell.photo.image = image
		}
		
		let size = (collectionView.frame.size.width - 8.0) / 2.0
		cell.widthConstraint.constant = size
		cell.heightConstraint.constant = size + 40
	}
	
}


/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

class ProfileHeaderCollectionViewCell : UICollectionViewCell {
	@IBOutlet var avatar : UIImageView!
	@IBOutlet var followButton : UIButton!
	@IBOutlet var fullName : UILabel!
	@IBOutlet var userHandle : UILabel!
	@IBOutlet var blogAddress : UIButton!
	@IBOutlet var widthConstraint : NSLayoutConstraint!
}

/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

class ProfileBioCollectionViewCell : UICollectionViewCell {
	@IBOutlet var bio : UILabel!
	@IBOutlet var widthConstraint : NSLayoutConstraint!
}

/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

class PhotoEntryCollectionViewCell : UICollectionViewCell {
	@IBOutlet var photo : UIImageView!
	@IBOutlet var date : UILabel!
	@IBOutlet var widthConstraint : NSLayoutConstraint!
	@IBOutlet var heightConstraint : NSLayoutConstraint!
	@IBOutlet var cellHeightConstraint : NSLayoutConstraint!
}
