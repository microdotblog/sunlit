//
//  ProfileViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/7/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout /*, UICollectionViewDataSourcePrefetching */  {
		
	var user : SunlitUser!
	var updatedUserInfo : SunlitUser? = nil
	var userPosts : [SunlitPost] = []
	
	@IBOutlet var collectionView : UICollectionView!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		self.fetchUserInfo(user)
		self.fetchUserPosts()
		
		if let layout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
			layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
		}
		
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissViewController))
    }
    
	@objc func dismissViewController() {
		self.dismiss(animated: true, completion: nil)
	}
	
	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	func fetchUserInfo(_ user : SunlitUser) {
		Snippets.shared.fetchUserDetails(user: user) { (error, updatedUser, posts : [SnippetsPost]) in
			
			if let snippetsUser = updatedUser {
				self.user = HTMLParser.convertUser(user: snippetsUser)
				self.updatedUserInfo = self.user
			
				DispatchQueue.main.async {
					self.collectionView.reloadData()
				}
			}
		}
	}
	
	func fetchUserPosts() {
		Snippets.shared.fetchUserMediaPosts(user: self.user) { (error, snippets: [SnippetsPost]) in

			self.userPosts = []
			for snippet in snippets {
				let post = HTMLParser.parse(snippet)
				self.userPosts.append(post)
			}
			
			DispatchQueue.main.async {
				self.collectionView.reloadData()
			}

		}
	}
	
	func loadPhoto(_ path : String,  _ index : IndexPath) {
		ImageCache.fetch(path) { (image) in
			if let _ = image {
				DispatchQueue.main.async {
					self.collectionView.reloadItems(at: [ index ])
				}
			}
		}
	}

	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */
	
	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 3
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		
		if section == 0 {
			return 1
		}
		else if section == 1 {
			return 1
		}
		else {
			return self.userPosts.count
		}
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
	
	func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		if indexPath.section == 1 {
			cell.updateConstraintsIfNeeded()
			cell.layoutIfNeeded()
		}
	}
	
	func configureHeaderCell(_ cell : ProfileHeaderCollectionViewCell, _ indexPath : IndexPath) {
		cell.followButton.clipsToBounds = true
		cell.followButton.layer.cornerRadius = (cell.followButton.bounds.size.height - 1) / 2.0
		cell.followButton.setTitle("Unfollow", for: .normal)
			
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
		
		// This shouldn't be needed...
		cell.contentView.updateConstraintsIfNeeded()
		cell.contentView.layoutIfNeeded()
	}
	
	func configureBioCell(_ cell : ProfileBioCollectionViewCell) {
		cell.bio.attributedText = user.formattedBio
		cell.widthConstraint.constant = self.collectionView.frame.size.width
		
		// This shouldn't be needed...
		cell.contentView.updateConstraintsIfNeeded()
		cell.bio.sizeToFit()
		cell.contentView.layoutIfNeeded()
		cell.bio.sizeToFit()
	}
	
	func configurePhotoCell(_ cell : PhotoEntryCollectionViewCell, _ indexPath : IndexPath) {
		let post = self.userPosts[indexPath.item]
		cell.date.text = ""
		if let date = post.publishedDate {
			cell.date.text = date.uuRfc3339String()
		}

		cell.photo.image = UIImage(named: "welcome_waves")

		if let image = ImageCache.prefetch(post.images.first ?? "") {
			cell.photo.image = image
		}
		else {
			self.loadPhoto(post.images.first ?? "", indexPath)
		}
		
		cell.widthConstraint.constant = (collectionView.frame.size.width - 16.0) / 2.0
		
		// This shouldn't be needed...
		cell.contentView.updateConstraintsIfNeeded()
		cell.contentView.layoutIfNeeded()
	}
	
	
	/*
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

		if indexPath.section == 0 {
			return UICollectionView.systemLayoutSizeFitting(collectionView)
			//return CGSize(width: collectionView.bounds.size.width, height: 0)
		}
		else {
			let size = collectionView.bounds.size.width - 8
			return CGSize(width: size / 2, height: 44.0 + (size / 2))
		}
	}
*/
	
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
	@IBOutlet var bio : UITextView!
	@IBOutlet var widthConstraint : NSLayoutConstraint!
}

/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

class PhotoEntryCollectionViewCell : UICollectionViewCell {
	@IBOutlet var photo : UIImageView!
	@IBOutlet var date : UILabel!
	@IBOutlet var widthConstraint : NSLayoutConstraint!
}
