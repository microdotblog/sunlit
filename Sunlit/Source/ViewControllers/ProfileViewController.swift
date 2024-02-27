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

class ProfileViewController: UIViewController {

    /* Include bios */
    static let headerSection = 0
    static let bioSection = 1
    static let photoSection = 2
    static let sectionCount = 3
    /* */
    
    /* Don't include bios
    static let headerSection = 0
    static let bioSection = -1
    static let photoSection = 1
    static let sectionCount = 2
     */
    
    
	var user : SnippetsUser!
	var userPosts : [SunlitPost] = []
	var loadInProgress = false
    var refreshControl = UIRefreshControl()

	@IBOutlet var collectionView : UICollectionView!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		// Merge if we can/need to from the user cache...
		self.user = SnippetsUser.save(self.user)
		self.navigationItem.title = self.user.fullName
        self.fetchUserInfo()

        self.refreshControl.addTarget(self, action: #selector(fetchUserInfo), for: .valueChanged)
        self.collectionView.addSubview(self.refreshControl)

		self.setupNavigation()
		self.setupGesture()
    }
	
    func setupNavigation() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(dismissViewController))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(onShare))
    }
	
	func setupGesture() {
		let gesture = UISwipeGestureRecognizer(target: self, action: #selector(dismissViewController))
		gesture.direction = .right
		self.view.addGestureRecognizer(gesture)
	}

	@objc func dismissViewController() {
		self.navigationController?.popViewController(animated: true)
	}
	
    @objc func onShare()
    {
        if let url = URL(string: self.user.siteURL)
        {
            let items = [url]
            let activities = [SafariShareActivity()]
            let viewController = UIActivityViewController(activityItems: items, applicationActivities: activities)
            self.present(viewController, animated: true)
        }
    }
    
	@objc func fetchUserInfo() {
        
        if self.loadInProgress == true {
            return
        }
        
        self.loadInProgress = true
        
        Snippets.Microblog.fetchUserDetails(user: self.user) { (error, updatedUser, posts : [SnippetsPost]) in
			
			if let snippetsUser = updatedUser {
				self.user = SnippetsUser.save(snippetsUser)
				
				DispatchQueue.main.async {
					self.collectionView.reloadData()
				}
                
                Snippets.Microblog.fetchUserMediaPosts(user: self.user) { (error, snippets: [SnippetsPost]) in

                    DispatchQueue.main.async {

                        var posts : [SunlitPost] = []
                        for snippet in snippets {
                            let post = SunlitPost.create(snippet)
                            posts.append(post)
                        }

                        self.loadInProgress = false
                        self.userPosts = posts
                        self.collectionView.reloadData()
                        self.refreshControl.endRefreshing()
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
					self.collectionView.reloadItems(at: [ index ])
				}
			}
		}
	}
	
	@objc func onFollowUser() {

        self.loadInProgress = true
        self.collectionView.reloadData()

        if self.user.isFollowing {
            
			Snippets.Microblog.unfollow(user: self.user) { (error) in
				if error == nil {
					self.user.isFollowing = false
					self.user = SnippetsUser.save(self.user)
				}
                
                DispatchQueue.main.async {
                    self.loadInProgress = false
                    self.collectionView.reloadData()
                }
			}
		}
		else {
			Snippets.Microblog.follow(user: self.user) { (error) in
				if error == nil {
					self.user.isFollowing = true
					self.user = SnippetsUser.save(self.user)
				}
                
                DispatchQueue.main.async {
                    self.loadInProgress = false
                    self.collectionView.reloadData()
                }
			}

		}
	}
}



/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

extension ProfileViewController : UITextViewDelegate {
	
	func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
		let safariViewController = SFSafariViewController(url: URL)
		self.present(safariViewController, animated: true, completion: nil)
		return false
	}
}
	


/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

extension ProfileViewController : UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSourcePrefetching {
	
	func numberOfSections(in collectionView: UICollectionView) -> Int {
		
        return ProfileViewController.sectionCount
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		
        if section == ProfileViewController.headerSection {
            return 1
        }
        
        if section == ProfileViewController.bioSection {
            return 1
        }
        
		return self.userPosts.count
	}
		
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		
        if indexPath.section == ProfileViewController.headerSection {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProfileHeaderCollectionViewCell", for: indexPath) as! ProfileHeaderCollectionViewCell
			self.configureHeaderCell(cell, indexPath)
			return cell
		}
        else if indexPath.section == ProfileViewController.bioSection {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProfileBioCollectionViewCell", for: indexPath) as! ProfileBioCollectionViewCell
			self.configureBioCell(cell)
			return cell
		}

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoEntryCollectionViewCell", for: indexPath) as! PhotoEntryCollectionViewCell
        self.configurePhotoCell(cell, indexPath)
        return cell
	}
	
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath){
	
		collectionView.deselectItem(at: indexPath, animated: true)
		
        if indexPath.section == ProfileViewController.photoSection {
			let post = self.userPosts[indexPath.item]
			let imagePath = post.images[0]
			var dictionary : [String : Any] = [:]
			dictionary["imagePath"] = imagePath
			dictionary["post"] = post
			
			NotificationCenter.default.post(name: .viewPostNotification, object: dictionary)
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
		
        if indexPath.section == ProfileViewController.headerSection {
			return ProfileHeaderCollectionViewCell.sizeOf(self.user, collectionViewWidth: collectionViewWidth)
		}
        else if indexPath.section == ProfileViewController.bioSection {
			return ProfileBioCollectionViewCell.sizeOf(self.user, collectionViewWidth:collectionViewWidth)
		}
		else {
			return PhotoEntryCollectionViewCell.sizeOf(collectionViewWidth: collectionViewWidth)
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.section == ProfileViewController.photoSection {
			if indexPath.item < self.userPosts.count {
				let post = self.userPosts[indexPath.item]
				self.loadPhoto(post.images.first ?? "", indexPath)
			}
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
		for indexPath in indexPaths {
            if indexPath.section == ProfileViewController.photoSection {
				let post = self.userPosts[indexPath.item]
				self.loadPhoto(post.images.first ?? "", indexPath)
			}
		}
	}
	
	func configureHeaderCell(_ cell : ProfileHeaderCollectionViewCell, _ indexPath : IndexPath) {
		cell.followButton.clipsToBounds = true
		cell.followButton.layer.cornerRadius = (cell.followButton.bounds.size.height - 1) / 2.0
		cell.followButton.isHidden = true
                		
		cell.followButton.addTarget(self, action: #selector(onFollowUser), for: .touchUpInside)
		
		if self.loadInProgress {
			cell.busyIndicator.startAnimating()
		}
		else {
			cell.busyIndicator.stopAnimating()
            cell.followButton.isHidden = false

			if self.user.isFollowing {
				cell.followButton.setTitle("Unfollow", for: .normal)
			}
            else {
                cell.followButton.setTitle("Follow", for: .normal)
            }
		}

		if self.user.username == SnippetsUser.current()?.username {
			// don't let someone unfollow themselves
			cell.followButton.isHidden = true
		}

		cell.avatar.clipsToBounds = true
		cell.avatar.layer.cornerRadius = (cell.avatar.bounds.size.height - 1) / 2.0
			
		cell.fullName.text = user.fullName
		cell.userHandle.text = "@" + user.username
		
		var address = user.siteURL
		if address.count > 0 && !address.contains("http") {
			address = "https://" + address
		}
		cell.blogAddress.setTitle(address, for: .normal)
			
		if let image = ImageCache.prefetch(user.avatarURL) {
			cell.avatar.image = image
		}
		else {
			cell.avatar.image = nil // UIImage(named: "welcome_waves")
			self.loadPhoto(user.avatarURL, indexPath)
		}
		
	}
	
	func configureBioCell(_ cell : ProfileBioCollectionViewCell) {
		//cell.bio.attributedText = user.attributedTextBio()
		cell.bio.text = user.bio
		//cell.widthConstraint.constant = ProfileBioCollectionViewCell.sizeOf(self.user, collectionViewWidth: self.collectionView.frame.size.width).width - 24.0
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







