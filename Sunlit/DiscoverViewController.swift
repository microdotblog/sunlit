//
//  DiscoverViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/17/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import SafariServices

class DiscoverViewController: UIViewController {
	
	@IBOutlet var busyIndicator : UIActivityIndicatorView!
	@IBOutlet var collectionView : UICollectionView!
	@IBOutlet var tableView : UITableView!
	@IBOutlet var scrollView : UIScrollView!
	@IBOutlet var stackView : UIStackView!
	var keyboardAccessoryView : UIView!

	@IBOutlet var stackViewWidthConstraint : NSLayoutConstraint!
	var selectedButton : UIButton? = nil
	
	var tableViewRefreshControl = UIRefreshControl()
	var collectionViewRefreshControl = UIRefreshControl()
	
	var posts : [SunlitPost] = []
	var tagmojiDictionary : [String : String] = [:]
	var collection = "photos"
	var collectionTitle = "photos"
	var loadingData = false
	
	

    override func viewDidLoad() {
        super.viewDidLoad()
        
		self.setupTableViewAndCollectionView()
		self.loadFrequentlyUsedEmoji()
		self.navigationItem.title = "Discover " + self.collectionTitle
		
		Tagmoji.shared.refresh { (updated) in
			self.loadTagmoji()
		}
		
		self.setupSnippets()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.navigationController?.navigationBar.topItem?.title = "Discover " + self.collectionTitle
		self.setupNotifications()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		NotificationCenter.default.removeObserver(self)
	}

	
	func setupTableViewAndCollectionView() {
		self.tableViewRefreshControl.addTarget(self, action: #selector(setupSnippets), for: .valueChanged)
		self.tableView.addSubview(self.tableViewRefreshControl)
		
		self.collectionViewRefreshControl.addTarget(self, action: #selector(setupSnippets), for: .valueChanged)
		self.collectionView.addSubview(self.collectionViewRefreshControl)
		
		self.loadFrequentlyUsedEmoji()
	}

	func setupNotifications() {
		NotificationCenter.default.addObserver(self, selector: #selector(handleImageLoadedNotification(_:)), name: NSNotification.Name("Feed Image Loaded"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleUserProfileSelectedNotification), name: NSNotification.Name("Display User Profile"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardShowNotification(_:)), name: NSNotification.Name("Keyboard Appear"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleReplyResponseNotification(_:)), name: NSNotification.Name("Reply Response"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleViewConversationNotification(_:)), name: NSNotification.Name("View Conversation"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardOnScreenNotification(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardOffScreenNotification(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleViewImageNotification(_:)), name: NSNotification.Name("View Image"), object: nil)
	}
	

	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	func refresh(_ entries : [SnippetsPost]) {
		
		var posts : [SunlitPost] = []
		
		for entry in entries {
			let post = SunlitPost.create(entry)
			if post.images.count > 0 {
				posts.append(post)
			}
		}
		
		self.posts = posts
		self.tableViewRefreshControl.endRefreshing()
		self.collectionViewRefreshControl.endRefreshing()
		self.busyIndicator.isHidden = true
		
		if self.tableView.isHidden == false {
			self.tableView.reloadData()
		}
		else if self.collectionView.isHidden == false {
			self.collectionView.reloadData()
		}
	}

	
	func loadTimeline() {
		if self.loadingData == true {
			return
		}
		
		self.loadingData = true
		
		Snippets.shared.fetchDiscoverTimeline(collection: self.collection) { (error, postObjects, tagmoji) in
			DispatchQueue.main.async {
				
				// Default to using the collection view...
				if self.tableView.isHidden == true && self.collectionView.isHidden == true {
					self.collectionView.isHidden = false
				}
				self.navigationController?.navigationBar.topItem?.title = "Discover " + self.collectionTitle
				self.refresh(postObjects)
				
				self.loadingData = false
			}
		}
	}
	
	@objc func loadMoreTimeline() {
		// Safety check for double loads...
		if self.loadingData == true {
			return
		}

		if let last = self.posts.last {
			self.loadingData = true
	
			var parameters : [String : String] = [:]
			parameters["count"] = "10"
			parameters["before_id"] = last.identifier

			Snippets.shared.fetchDiscoverTimeline(collection: self.collection, parameters: parameters) { (error, entries, tagmoji) in
				
				DispatchQueue.main.async {
					var row = self.posts.count
					var indexPaths : [IndexPath] = []
					for entry in entries {
						let post = SunlitPost.create(entry)
						
						if post.images.count > 0 {
							self.posts.append(post)

							let indexPath = IndexPath(row: row, section: 0)
							indexPaths.append(indexPath)
							row = row + 1
						}						
					}
					
					self.tableView.insertRows(at: indexPaths, with: .automatic)
					self.loadingData = false
				}
			}
		}

	}
	
	func loadFrequentlyUsedEmoji() {
		let emoji = Tagmoji.shared.frequentlyUsedEmoji()
		let scrollView = UIScrollView()
		let contentView = UIView()
		scrollView.addSubview(contentView)
		scrollView.backgroundColor = UIColor.white
		
		var buttonOffset = CGPoint(x: 0, y: 0)
		for symbol in emoji {
			let button = UIButton(frame: CGRect(x: buttonOffset.x, y: buttonOffset.y, width: 44, height: 44))
			button.setTitle(symbol, for: .normal)
			contentView.addSubview(button)
			buttonOffset.x += 44
			button.addTarget(self, action: #selector(self.emojiSelected(_:)), for: .touchUpInside)

			if let backgroundImage = UIImage.uuSolidColorImage(color: UIColor(named: "color_emoji_selection")!) {
				button.setBackgroundImage(backgroundImage, for: .highlighted)
			}
		}
		
		contentView.frame = CGRect(x: 0, y: 0, width: buttonOffset.x, height: 44)
		scrollView.addSubview(contentView)
		scrollView.contentSize = CGSize(width: buttonOffset.x, height: buttonOffset.y)
		scrollView.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 44)
		self.keyboardAccessoryView = scrollView
	}


	func loadTagmoji() {
		
		DispatchQueue.main.async {
			var buttonOffset = CGPoint(x: 0, y: 0)
			let tagmojiArray = Tagmoji.shared.all()
			self.selectedButton  = nil
				
			for tagmoji in tagmojiArray {
				if let name = Tagmoji.shared.tileFor(tagmoji: tagmoji) {
					self.collection = name
					
					let button = UIButton(type: .custom)
					button.frame = CGRect(x: buttonOffset.x, y: buttonOffset.y, width: 36, height: 36)
					button.setTitle(tagmoji, for: .normal)
					if let color_img = UIImage.uuSolidColorImage(color: UIColor(named: "color_emoji_selection")!) {
						button.setBackgroundImage(color_img, for: .selected)
					}
					button.layer.cornerRadius = 6
					button.clipsToBounds = true
						
					if name == "photos" {
						self.stackView.insertArrangedSubview(button, at: 0)
						self.selectedButton = button
						button.isSelected = true
					}
					else {
						self.stackView.addArrangedSubview(button)
					}
					buttonOffset.x += 44
					button.addTarget(self, action: #selector(self.tagmojiSelected(_:)), for: .touchUpInside)
				}
			}
			
			self.stackViewWidthConstraint.constant = buttonOffset.x
			self.scrollView.contentSize = CGSize(width: buttonOffset.x, height: buttonOffset.y)
		}
	}
	
	@objc func setupSnippets() {
		self.loadTimeline()
	}
	
	
	func prefetchImages(_ indexPath : IndexPath) {
		let post = self.posts[indexPath.row]
		let imageSource = post.images[0]
		
		if ImageCache.prefetch(imageSource) == nil {
			ImageCache.fetch(imageSource) { (image) in
				if let _ = image {
					DispatchQueue.main.async {
						NotificationCenter.default.post(name: NSNotification.Name(rawValue: "Feed Image Loaded"), object: indexPath)
					}
				}
			}
		}
		
		let avatarSource = post.owner.pathToUserImage
		if ImageCache.prefetch(avatarSource) == nil {
			ImageCache.fetch(avatarSource) { (image) in
				if let _ = image {
					DispatchQueue.main.async {
						NotificationCenter.default.post(name: NSNotification.Name(rawValue: "Feed Image Loaded"), object: indexPath)
					}
				}
			}
		}
	}
	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	@objc func emojiSelected(_ button : UIButton) {
		if let emoji = button.title(for: .normal) {
			NotificationCenter.default.post(name: NSNotification.Name("Emoji Selected"), object: emoji)
		}
	}
	
	@objc func tagmojiSelected(_ button : UIButton) {
		if let selected = self.selectedButton {
			selected.isSelected = false
		}
		
		self.selectedButton = button
		button.isSelected = true
		
		if let emoji = button.title(for: .normal),
			let title = Tagmoji.shared.tileFor(tagmoji: emoji),
			let collection = Tagmoji.shared.routeFor(tagmoji: emoji) {
			self.collection = collection
			self.collectionTitle = title

			DispatchQueue.main.async {
				
				if title == "photos" {
					self.tableView.isHidden = true
					self.collectionView.isHidden = false
				}
				else {
					self.tableView.isHidden = false
					self.collectionView.isHidden = true
				}
				
				self.navigationController?.navigationBar.topItem?.title = "Discover " + title
				self.refresh([])
				
				self.busyIndicator.isHidden = false
			}
			
			Snippets.shared.fetchDiscoverTimeline(collection: collection) { (error, postObjects, tagmoji) in
				DispatchQueue.main.async {
					self.refresh(postObjects)
				}
			}
		}
	}
	
	@objc func keyboardOnScreenNotification(_ notification : Notification) {
		
		if let info : [AnyHashable : Any] = notification.userInfo {
			if let value : NSValue = info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
				let frame = value.cgRectValue

				self.view.addSubview(self.keyboardAccessoryView)
				self.keyboardAccessoryView.frame = CGRect(x: 0, y: frame.origin.y - 44, width: frame.size.width, height: 44)
				self.keyboardAccessoryView.alpha = 0.0
				self.keyboardAccessoryView.isHidden = false
				
				UIView.animate(withDuration: 0.25) {
					self.keyboardAccessoryView.alpha = 1.0
				}
			}
		}
	}

	@objc func keyboardOffScreenNotification(_ notification : Notification) {
		self.keyboardAccessoryView.removeFromSuperview()
	}

	
	@objc func handleKeyboardShowNotification(_ notification : Notification) {
		if let cellOffset = notification.object as? CGFloat {
			let safeArea : CGFloat = self.view.safeAreaInsets.top
			let accessoryViewHeight : CGFloat = self.keyboardAccessoryView.frame.size.height
			let parentOffset : CGFloat = self.tableView.frame.origin.y
			let offset = cellOffset + accessoryViewHeight + parentOffset - safeArea
			self.tableView.setContentOffset(CGPoint(x: 0, y: offset), animated: true)
		}
	}
	
	@objc func handleImageLoadedNotification(_ notification : Notification) {
		if let indexPath = notification.object as? IndexPath {
			if indexPath.row < self.posts.count {
				if self.tableView.isHidden == false {
					if indexPath.row < self.posts.count {
						self.tableView.reloadRows(at: [ indexPath ], with: .none)
					}
				}
				else if self.collectionView.isHidden == false {
					if indexPath.item < self.posts.count {
						self.collectionView.reloadItems(at: [ indexPath ])
					}
				}
			}
		}
	}
		
	@objc func handleUserProfileSelectedNotification(_ notification : Notification) {
		if let user = notification.object as? SnippetsUser {
			let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
			let profileViewController = storyBoard.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
			profileViewController.user = user
			self.navigationController?.pushViewController(profileViewController, animated: true)
		}
	}
	
	@objc func handleViewConversationNotification(_ notification : Notification) {
		if let post = notification.object as? SunlitPost {
			let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
			let conversationViewController = storyBoard.instantiateViewController(withIdentifier: "ConversationViewController") as! ConversationViewController
			conversationViewController.sourcePost = post
			self.navigationController?.pushViewController(conversationViewController, animated: true)
		}
	}
	
	@objc func handleReplyResponseNotification(_ notification : Notification) {
		var message = "Reply posted!"
		
		if let error = notification.object as? Error {
			message = error.localizedDescription
		}
		
		Dialog(self).information(message)
	}
	
	@objc func handleViewImageNotification(_ notification : Notification) {
		if let dictionary = notification.object as? [String : Any] {
			let imagePath = dictionary["imagePath"] as! String
			let post = dictionary["post"] as! SunlitPost
			let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
			let imageViewController = storyBoard.instantiateViewController(withIdentifier: "ImageViewerViewController") as! ImageViewerViewController
			imageViewController.pathToImage = imagePath
			imageViewController.post = post
			self.navigationController?.pushViewController(imageViewController, animated: true)
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
					if self.collectionView.isHidden == false {
						if index.item < self.posts.count {
							self.collectionView.reloadItems(at: [ index ])
						}
					}
				}
			}
		}
	}
	
}




/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */


extension DiscoverViewController : UITextFieldDelegate, UITextViewDelegate {

	func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
		UIView.setAnimationsEnabled(false)
		self.tableView.beginUpdates()
		self.tableView.endUpdates()
		UIView.setAnimationsEnabled(true)
			
		return true
	}
	
	func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
		let safariViewController = SFSafariViewController(url: URL)
		self.present(safariViewController, animated: true, completion: nil)
		return false
	}
	
}


/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

extension DiscoverViewController : UITableViewDelegate, UITableViewDataSource {
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.posts.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		let cell = tableView.dequeueReusableCell(withIdentifier: "SunlitPostTableViewCell", for: indexPath) as! SunlitPostTableViewCell
		if indexPath.row < self.posts.count {
			let post = self.posts[indexPath.row]
			cell.setup(indexPath.row, post, parentWidth: tableView.bounds.size.width)
		}
		return cell
	}
	
	func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
	
		for indexPath in indexPaths {
			self.prefetchImages(indexPath)
		}
	}
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		self.prefetchImages(indexPath)
		
		if indexPath.row > (self.posts.count - 3) {
			self.loadMoreTimeline()
		}
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		let post = self.posts[indexPath.row]

		let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
		let imageViewController = storyBoard.instantiateViewController(withIdentifier: "ImageViewerViewController") as! ImageViewerViewController
		imageViewController.pathToImage = post.images[0]
		imageViewController.post = post
		self.navigationController?.pushViewController(imageViewController, animated: true)
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		let post = self.posts[indexPath.row]
		return SunlitPostTableViewCell.height(post, parentWidth: tableView.bounds.size.width)
	}
}

/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

extension DiscoverViewController : UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDataSourcePrefetching {
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return self.posts.count
	}
	
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoEntryCollectionViewCell", for: indexPath) as! PhotoEntryCollectionViewCell
		self.configurePhotoCell(cell, indexPath)
		return cell
	}
	
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath){
		
		collectionView.deselectItem(at: indexPath, animated: true)
		
		let post = self.posts[indexPath.item]
		let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
		let imageViewController = storyBoard.instantiateViewController(withIdentifier: "ImageViewerViewController") as! ImageViewerViewController
		imageViewController.pathToImage = post.images[0]
		imageViewController.post = post
		self.navigationController?.pushViewController(imageViewController, animated: true)
	}
	
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

		var collectionViewWidth = collectionView.bounds.size.width
		
		if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
			collectionViewWidth = collectionViewWidth - flowLayout.sectionInset.left
			collectionViewWidth = collectionViewWidth - flowLayout.sectionInset.right
			
			collectionViewWidth = collectionViewWidth - collectionView.contentInset.left
			collectionViewWidth = collectionViewWidth - collectionView.contentInset.right
		}
		
		return PhotoEntryCollectionViewCell.sizeOf(collectionViewWidth: collectionViewWidth)
	}
	
	func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		let post = self.posts[indexPath.item]
		self.loadPhoto(post.images.first ?? "", indexPath)
	}
	
	func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
		for indexPath in indexPaths {
			let post = self.posts[indexPath.item]
			self.loadPhoto(post.images.first ?? "", indexPath)
		}
	}
	
	func configurePhotoCell(_ cell : PhotoEntryCollectionViewCell, _ indexPath : IndexPath) {
		if indexPath.item < self.posts.count {
			let post = self.posts[indexPath.item]
			cell.date.text = "@\(post.owner.userHandle)"

			cell.photo.image = nil
			if let image = ImageCache.prefetch(post.images.first ?? "") {
				cell.photo.image = image
			}
			
			cell.contentView.layer.cornerRadius = 8.0
			cell.contentView.clipsToBounds = true
			cell.contentView.layer.borderWidth = 0.5
			cell.contentView.layer.borderColor = UIColor.darkGray.cgColor
			cell.widthConstraint.constant = PhotoEntryCollectionViewCell.sizeOf(collectionViewWidth: self.collectionView.bounds.size.width).width
		}
	}
	
}
