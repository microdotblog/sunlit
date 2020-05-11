//
//  FeedViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/3/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class FeedViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITableViewDataSourcePrefetching, UITextViewDelegate {

	@IBOutlet var tableView : UITableView!
	var refreshControl = UIRefreshControl()
	var keyboardAccessoryView : UIView!
	var tableViewData : [SunlitPost] = []
	
    override func viewDidLoad() {
        super.viewDidLoad()
		self.setupTableView()
		self.setupNotifications()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.navigationController?.setNavigationBarHidden(true, animated: true)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		self.setupSnippets()
	}
	
	func setupTableView() {
		self.refreshControl.addTarget(self, action: #selector(setupSnippets), for: .valueChanged)
		self.tableView.addSubview(self.refreshControl)
		self.loadTagmoji()
	}
	
	func setupNotifications() {
		NotificationCenter.default.addObserver(self, selector: #selector(handleTemporaryTokenReceivedNotification(_:)), name: NSNotification.Name("TemporaryTokenReceivedNotification"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleImageLoadedNotification(_:)), name: NSNotification.Name("Feed Image Loaded"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleUserProfileSelectedNotification), name: NSNotification.Name("Display User Profile"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardShowNotification(_:)), name: NSNotification.Name("Keyboard Appear"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardOnScreenNotification(_:)), name: UIResponder.keyboardDidShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardOffScreenNotification(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleReplyResponseNotification(_:)), name: NSNotification.Name("Reply Response"), object: nil)
	}

	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */
	
	
	func refreshTableView(_ entries : [SnippetsPost]) {
		
		var posts : [SunlitPost] = []
		
		for entry in entries {
			let post = SunlitPost.create(entry)
			posts.append(post)
		}
		
		self.tableViewData = posts
		self.refreshControl.endRefreshing()
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

	@objc func emojiSelected(_ button : UIButton) {
		if let emoji = button.title(for: .normal) {
			NotificationCenter.default.post(name: NSNotification.Name("Emoji Selected"), object: emoji)
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
		if let offset = notification.object as? CGFloat {
			self.tableView.setContentOffset(CGPoint(x: 0, y: offset), animated: true)
		}
	}
	
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
			self.navigationController?.pushViewController(profileViewController, animated: true)
		}
	}
	
	@objc func handleReplyResponseNotification(_ notification : Notification) {
		var message = "Reply posted!"
		
		if let error = notification.object as? Error {
			message = error.localizedDescription
		}
		
		Dialog.information(message, self)
	}
	
	func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
		UIView.setAnimationsEnabled(false)
		self.tableView.beginUpdates()
		self.tableView.endUpdates()
		UIView.setAnimationsEnabled(true)
			
		return true
	}

	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */
	func configureCollectionView() {
		
	}
	
	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	func loadTagmoji() {
		let scrollView = UIScrollView()
		let contentView = UIView()
		scrollView.addSubview(contentView)
		scrollView.backgroundColor = UIColor.white
		
		var buttonOffset = CGPoint(x: 0, y: 0)
		Snippets.shared.fetchTagmojiCategories { (error, tagmoji : [[String : Any]]) in
			DispatchQueue.main.async {
				for dictionary in tagmoji {
					if let symbol = dictionary["emoji"] as? String {
						let button = UIButton(frame: CGRect(x: buttonOffset.x, y: buttonOffset.y, width: 44, height: 44))
						button.setTitle(symbol, for: .normal)
						contentView.addSubview(button)
						buttonOffset.x += 44
						
						button.addTarget(self, action: #selector(self.emojiSelected(_:)), for: .touchUpInside)
					}
				}
				contentView.frame = CGRect(x: 0, y: 0, width: buttonOffset.x, height: 44)
				scrollView.addSubview(contentView)
				scrollView.contentSize = CGSize(width: buttonOffset.x, height: buttonOffset.y)
				scrollView.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 44)
				self.keyboardAccessoryView = scrollView
			}
		}
	}
	
	func loadTimeline() {
		
		Snippets.shared.fetchCurrentUserPhotoTimeline { (error, postObjects : [SnippetsPost]) in
			DispatchQueue.main.async {
				self.refreshTableView(postObjects)
			}
		}
		
	}

	@objc func setupSnippets() {

		if let token = Settings.permanentToken() {
			Snippets.shared.configure(permanentToken: token, blogUid: nil)
			
			self.loadTimeline()
		}
		else {
			self.refreshControl.endRefreshing()
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
	
	@IBOutlet var postImage : UIImageView!
	@IBOutlet var textView : UITextView!
	@IBOutlet var dateLabel : UILabel!
	@IBOutlet var userAvatar : UIImageView!
	@IBOutlet var userName : UILabel!
	@IBOutlet var userHandle : UILabel!
	@IBOutlet var heightConstraint : NSLayoutConstraint!
	@IBOutlet var replyContainer : UIView!
	@IBOutlet var replyField : UITextView!
	@IBOutlet var replyButton : UIButton!
	@IBOutlet var replyIconButton : UIButton!
	@IBOutlet var postButton : UIButton!
	@IBOutlet var conversationButton : UIButton!
	@IBOutlet var conversationHeightConstraint : NSLayoutConstraint!
	
	var user : SunlitUser!
	var post : SunlitPost!
	
	func setup(_ index: Int, _ post : SunlitPost) {
		
		let owner = post.owner
		self.post = post
		self.user = owner
		
		self.replyContainer.layer.cornerRadius = 18.0
		self.replyContainer.layer.borderColor = UIColor.lightGray.cgColor
		self.replyContainer.layer.borderWidth = 0.0

		self.conversationButton.isHidden = !self.post.source.hasConversation
		self.conversationHeightConstraint.constant = self.post.source.hasConversation ? 44.0 : 0.0
		
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
	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	@IBAction func onReply() {
		Snippets.shared.reply(originalPost: self.post.source, content: self.replyField.text) { (error) in
			NotificationCenter.default.post(name: NSNotification.Name("Reply Response"), object: error)
		}
		
		self.textView.resignFirstResponder()
	}
	
	@IBAction func onViewConversation() {
		
	}
	
	@IBAction func onActivateReply() {
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardOnScreen(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardOffScreen(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleEmojiSelectedNotification(_:)), name: NSNotification.Name("Emoji Selected"), object: nil)
		self.replyContainer.layer.borderWidth = 0.5;

		self.replyField.isHidden = false
		self.replyButton.isHidden = true
		self.replyIconButton.isHidden = true
		self.postButton.isHidden = false

		self.replyField.alpha = 0.0
		self.replyButton.alpha = 1.0
		self.replyIconButton.alpha = 1.0
		self.postButton.alpha = 0.0

		UIView.animate(withDuration: 0.35) {
			self.replyField.alpha = 1.0
			self.replyButton.alpha = 0.0
			self.replyIconButton.alpha = 0.0
			self.postButton.alpha = 1.0
			self.replyContainer.backgroundColor = UIColor.white
		}
		
		self.replyField.becomeFirstResponder()
	}
	
	@objc func keyboardOnScreen(_ notification : Notification) {
		if let info : [AnyHashable : Any] = notification.userInfo {
			if let value : NSValue = info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
				let rawFrame = value.cgRectValue
				
				var safeArea : CGFloat = 0.0
				safeArea = safeArea + UIApplication.shared.windows[0].safeAreaInsets.bottom
				let textBoxOffset = self.replyContainer.frame.origin.y + self.replyContainer.frame.size.height - 10.5
				let cellOffset : CGFloat = self.frame.origin.y
				let keyboardSize : CGFloat = rawFrame.size.height
				let offset = cellOffset + textBoxOffset - keyboardSize - safeArea
				
				NotificationCenter.default.post(name: NSNotification.Name(rawValue: "Keyboard Appear"), object: offset)
			}
			
		}
	}
	
	@objc func keyboardOffScreen(_ notification : Notification) {
			
		self.replyContainer.layer.borderWidth = 0.0

		self.replyField.isHidden = true
		self.replyButton.isHidden = false
		self.replyIconButton.isHidden = false
		self.postButton.isHidden = true

		UIView.animate(withDuration: 0.35) {
			self.replyField.alpha = 0.0;
			self.replyButton.alpha = 1.0;
			self.replyIconButton.alpha = 1.0;
			self.postButton.alpha = 0.0;
			self.replyContainer.backgroundColor = UIColor.clear
		}
		
		NotificationCenter.default.removeObserver(self)
	}
	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */
	
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
	
	@objc func handleEmojiSelectedNotification(_ notification : Notification) {
		if let emoji = notification.object as? String {
			self.replyField.text = self.replyField.text + emoji
		}
	}
	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */
	
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
}


/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

class FeedCollectionViewCell : UICollectionViewCell {
	
}


