//
//  MyProfileViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/9/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class MyProfileViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

	@IBOutlet var collectionView : UICollectionView!
	var userPosts : [SunlitPost] = []
	var user : SunlitUser?

    override func viewDidLoad() {
        super.viewDidLoad()
		self.fetchUserInfo()
    }
    

	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	func fetchUserInfo() {
		Snippets.shared.fetchCurrentUserInfo { (error, snippetsUser) in
			if let updatedUser = snippetsUser {
				self.user = SunlitPost.convertUser(user: updatedUser)

				DispatchQueue.main.async {
					self.collectionView.reloadData()
				}

				Snippets.shared.fetchUserMediaPosts(user: updatedUser) { (error, snippets : [SnippetsPost]) in
					self.userPosts = []
					for snippet in snippets {
						let sunlitPost = SunlitPost.create(snippet)
						self.userPosts.append(sunlitPost)
					}
					
					DispatchQueue.main.async {
						self.collectionView.reloadData()
					}
				}
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
		if self.user != nil {
			return 3
		}
		else {
			return 0
		}
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
	
	func configureHeaderCell(_ cell : ProfileHeaderCollectionViewCell, _ indexPath : IndexPath) {
		cell.followButton.clipsToBounds = true
		cell.followButton.layer.cornerRadius = (cell.followButton.bounds.size.height - 1) / 2.0
		cell.followButton.setTitle("Unfollow", for: .normal)
			
		cell.avatar.clipsToBounds = true
		cell.avatar.layer.cornerRadius = (cell.avatar.bounds.size.height - 1) / 2.0
			
		if let user = self.user {
			cell.fullName.text = user.fullName
			cell.userHandle.text = user.userHandle
			cell.blogAddress.setTitle(user.pathToWebSite, for: .normal)
			
			if let image = ImageCache.prefetch(user.pathToUserImage) {
				cell.avatar.image = image
			}
			else {
				cell.avatar.image = UIImage(named: "welcome_waves")
				self.loadPhoto(user.pathToUserImage, indexPath)
			}
		}
		
		// Make sure the cell goes the entire width
		cell.widthConstraint.constant = collectionView.frame.size.width
	}
	
	func configureBioCell(_ cell : ProfileBioCollectionViewCell) {
		
		if let user = self.user {
			cell.bio.attributedText = user.formattedBio
		}
		cell.widthConstraint.constant = self.collectionView.frame.size.width - 16
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
	}
	

}
