//
//  ProfileViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/7/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import SafariServices
import Snippets

class ProfileViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSourcePrefetching, UITextViewDelegate {
		
	var user : SnippetsUser!
	var updatedUserInfo : SnippetsUser? = nil
	var userPosts : [SunlitPost] = []
	
	@IBOutlet var collectionView : UICollectionView!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		// Merge if we can/need to from the user cache...
		self.user = SnippetsUser.save(self.user)
		self.navigationItem.title = self.user.fullName
		
		if self.user.bio.count > 0 {
			self.fetchUserPosts()
		}
		else {
			self.fetchUserInfo(user)
		}
		
		self.navigationItem.leftBarButtonItem = UIBarButtonItem.barButtonWithImage(named: "back_button", target: self, action: #selector(dismissViewController))
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

	
	func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
		let safariViewController = SFSafariViewController(url: URL)
		self.present(safariViewController, animated: true, completion: nil)
		return false
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
			
			let storyBoard: UIStoryboard = UIStoryboard(name: "ImageViewer", bundle: nil)
			let imageViewController = storyBoard.instantiateViewController(withIdentifier: "ImageViewerViewController") as! ImageViewerViewController
			imageViewController.pathToImage = post.images[0]
			imageViewController.post = post
			self.navigationController?.pushViewController(imageViewController, animated: true)
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
		else {
			return PhotoEntryCollectionViewCell.sizeOf(collectionViewWidth: collectionViewWidth)
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		if indexPath.section == 2 {
			let post = self.userPosts[indexPath.item]
			self.loadPhoto(post.images.first ?? "", indexPath)
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
		
		var address = user.pathToWebSite
		if address.count > 0 && !address.contains("http") {
			address = "https://" + address
		}
		cell.blogAddress.text = address
			
		if let image = ImageCache.prefetch(user.pathToUserImage) {
			cell.avatar.image = image
		}
		else {
			cell.avatar.image = UIImage(named: "welcome_waves")
			self.loadPhoto(user.pathToUserImage, indexPath)
		}
		
		cell.widthConstraint.constant = self.collectionView.bounds.size.width
	}
	
	func configureBioCell(_ cell : ProfileBioCollectionViewCell) {
		cell.bio.attributedText = user.attributedTextBio()
		cell.widthConstraint.constant = self.collectionView.bounds.size.width 
	}
	
	func configurePhotoCell(_ cell : PhotoEntryCollectionViewCell, _ indexPath : IndexPath) {
		let post = self.userPosts[indexPath.item]
		cell.date.text = ""
		if let date = post.publishedDate {
			cell.date.text = date.friendlyFormat()
		}

		cell.photo.image = nil
		if let image = ImageCache.prefetch(post.images.first ?? "") {
			cell.photo.image = image
		}
		
		cell.photo.layer.borderColor = UIColor.lightGray.cgColor
		cell.photo.layer.borderWidth = 0.5
		
		cell.contentView.layer.cornerRadius = 8.0
		cell.contentView.clipsToBounds = true
		cell.contentView.layer.borderWidth = 0.5
		cell.contentView.layer.borderColor = UIColor.lightGray.cgColor
		cell.widthConstraint.constant = PhotoEntryCollectionViewCell.sizeOf(collectionViewWidth: self.collectionView.bounds.size.width).width
	}
	
}







