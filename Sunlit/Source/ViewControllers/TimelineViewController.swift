//
//  TimelineViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/3/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import SafariServices
import Snippets

class TimelineViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITableViewDataSourcePrefetching, UITextViewDelegate {

	@IBOutlet var tableView : UITableView!
	@IBOutlet var loggedOutView : UIView!
	var refreshControl = UIRefreshControl()
	var keyboardAccessoryView : UIView!
	var tableViewData : [SunlitPost] = []
	var loadingData = false
	
    override func viewDidLoad() {
        super.viewDidLoad()
		self.navigationItem.title = "Timeline"
		self.setupTableView()
		self.loadTimeline()
	}
		
	func setupTableView() {
		self.refreshControl.addTarget(self, action: #selector(loadTimeline), for: .valueChanged)
		self.tableView.addSubview(self.refreshControl)
		self.loadFrequentlyUsedEmoji()
	}
	
	func setupNotifications() {
		NotificationCenter.default.addObserver(self, selector: #selector(handleImageLoadedNotification(_:)), name: NSNotification.Name("Feed Image Loaded"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleUserProfileSelectedNotification), name: NSNotification.Name("Display User Profile"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardShowNotification(_:)), name: NSNotification.Name("Keyboard Appear"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardOnScreenNotification(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardOffScreenNotification(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShowNotification(_:)), name: UIResponder.keyboardDidShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleReplyResponseNotification(_:)), name: NSNotification.Name("Reply Response"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleViewConversationNotification(_:)), name: NSNotification.Name("View Conversation"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleViewImageNotification(_:)), name: NSNotification.Name("View Image"), object: nil)
	}
	
	func updateLoggedInStatus() {
		let token = Settings.snippetsToken()
		self.loggedOutView.isHidden = (token != nil)
	}
	
	@IBAction func onShowLogin() {
		NotificationCenter.default.post(name: NSNotification.Name(rawValue: "Show Login"), object: nil)
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
		
		let cell = tableView.dequeueReusableCell(withIdentifier: "SunlitPostTableViewCell", for: indexPath) as! SunlitPostTableViewCell
		let post = self.tableViewData[indexPath.row]
		cell.setup(indexPath.row, post, parentWidth: tableView.bounds.size.width)
		return cell
	}
	
	func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
	
		for indexPath in indexPaths {
			self.prefetchImages(indexPath)
		}
	}
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		self.prefetchImages(indexPath)
		
		if indexPath.row > (self.tableViewData.count - 3) {
			self.loadMoreTimeline()
		}
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		let post = self.tableViewData[indexPath.row]

		let storyBoard: UIStoryboard = UIStoryboard(name: "ImageViewer", bundle: nil)
		let imageViewController = storyBoard.instantiateViewController(withIdentifier: "ImageViewerViewController") as! ImageViewerViewController
		imageViewController.pathToImage = post.images[0]
		imageViewController.post = post
		self.navigationController?.pushViewController(imageViewController, animated: true)
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		let post = self.tableViewData[indexPath.row]
		return SunlitPostTableViewCell.height(post, parentWidth: tableView.bounds.size.width)
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
				self.keyboardAccessoryView.isHidden = false
				self.keyboardAccessoryView.alpha = 1.0
				self.view.addSubview(self.keyboardAccessoryView)

				let frame = value.cgRectValue
				let height = self.keyboardAccessoryView.frame.size.height
				let safeArea : CGFloat = self.view.safeAreaInsets.bottom
				let offset = frame.origin.y - height + safeArea - 88.0
				self.keyboardAccessoryView.frame = CGRect(x: 0, y: offset, width: frame.size.width, height: height)
			}
		}
	}

	@objc func keyboardOffScreenNotification(_ notification : Notification) {
		self.keyboardAccessoryView.removeFromSuperview()
		self.keyboardAccessoryView.alpha = 0.0
	}

	@objc func keyboardDidShowNotification(_ notification : Notification) {
		UIView.animate(withDuration: 0.3) {
			self.keyboardAccessoryView.alpha = 1.0
		}
	}

	@objc func handleKeyboardShowNotification(_ notification : Notification) {
		
		if let cellOffset = notification.object as? CGFloat {
			var superview = self.view.superview
			var safeArea : CGFloat = self.view.safeAreaInsets.bottom
			while superview != nil && safeArea == 0.0 {
				safeArea = safeArea + superview!.safeAreaInsets.bottom
				superview = superview?.superview
			}
			
			let accessoryViewHeight = self.keyboardAccessoryView.frame.size.height
			let parentOffset = self.tableView.frame.origin.y
			let buffer : CGFloat = 16.0
			let editViewHeight : CGFloat = 22.0
			let offset = cellOffset - accessoryViewHeight - parentOffset + safeArea + buffer + editViewHeight
			self.tableView.setContentOffset(CGPoint(x: 0, y: offset), animated: true)
		}
	}
	
	@objc func handleImageLoadedNotification(_ notification : Notification) {
		if let indexPath = notification.object as? IndexPath {
			if indexPath.row < self.tableViewData.count {
				self.tableView.reloadRows(at: [ indexPath ], with: .none)
			}
		}
	}
	
	@objc func handleUserProfileSelectedNotification(_ notification : Notification) {
		if let user = notification.object as? SnippetsUser {
			let storyBoard: UIStoryboard = UIStoryboard(name: "Profile", bundle: nil)
			let profileViewController = storyBoard.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
			profileViewController.user = user
			self.navigationController?.pushViewController(profileViewController, animated: true)
		}
	}
	
	@objc func handleViewConversationNotification(_ notification : Notification) {
		if let post = notification.object as? SunlitPost {
			let storyBoard: UIStoryboard = UIStoryboard(name: "Conversation", bundle: nil)
			let conversationViewController = storyBoard.instantiateViewController(withIdentifier: "ConversationViewController") as! ConversationViewController
			conversationViewController.sourcePost = post
			self.navigationController?.pushViewController(conversationViewController, animated: true)
		}
	}
	
	@objc func handleViewImageNotification(_ notification : Notification) {
		if let dictionary = notification.object as? [String : Any] {
			let imagePath = dictionary["imagePath"] as! String
			let post = dictionary["post"] as! SunlitPost
			let storyBoard: UIStoryboard = UIStoryboard(name: "ImageViewer", bundle: nil)
			let imageViewController = storyBoard.instantiateViewController(withIdentifier: "ImageViewerViewController") as! ImageViewerViewController
			imageViewController.pathToImage = imagePath
			imageViewController.post = post
			self.navigationController?.pushViewController(imageViewController, animated: true)
		}
	}
	
	@objc func handleReplyResponseNotification(_ notification : Notification) {
		var message = "Reply posted!"
		
		if let error = notification.object as? Error {
			message = error.localizedDescription
		}
		
		Dialog(self).information(message)
	}
	

	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

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
	
	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

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
		self.keyboardAccessoryView.alpha = 0.0
	}
	
	@objc func loadTimeline() {
		
		let token = Settings.snippetsToken()
		self.loggedOutView.isHidden = (token != nil)

		// Safety check for double loads...
		if self.loadingData == true {
			return
		}
		
		self.loadingData = true
		Snippets.shared.fetchCurrentUserMediaTimeline { (error, postObjects : [SnippetsPost]) in
			DispatchQueue.main.async {
				self.refreshTableView(postObjects)
				self.loadingData = false
			}
		}
	}
	
	@objc func loadMoreTimeline() {
		// Safety check for double loads...
		if self.loadingData == true {
			return
		}

		if let last = self.tableViewData.last {
			self.loadingData = true
	
			var parameters : [String : String] = [:]
			parameters["count"] = "10"
			parameters["before_id"] = last.identifier

			Snippets.shared.fetchCurrentUserMediaTimeline(parameters: parameters, completion:
			{ (error, entries : [SnippetsPost]) in
				DispatchQueue.main.async {
					
					var row = self.tableViewData.count
					var indexPaths : [IndexPath] = []
					for entry in entries {
						let post = SunlitPost.create(entry)
						self.tableViewData.append(post)
						
						let indexPath = IndexPath(row: row, section: 0)
						indexPaths.append(indexPath)
						row = row + 1
					}
					
					self.tableView.insertRows(at: indexPaths, with: .automatic)
					self.loadingData = false
				}
			})
		}

	}

	
	func prefetchImages(_ indexPath : IndexPath) {
		let post = self.tableViewData[indexPath.row]
		
		for imageSource in post.images {
			if ImageCache.prefetch(imageSource) == nil {
				ImageCache.fetch(imageSource) { (image) in
					if let _ = image {
						DispatchQueue.main.async {
							NotificationCenter.default.post(name: NSNotification.Name(rawValue: "Feed Image Loaded"), object: indexPath)
						}
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
	
}


/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

extension TimelineViewController : SnippetsScrollContentProtocol {
	func prepareToDisplay() {
		self.navigationController?.navigationBar.topItem?.title = "Timeline"
		self.setupNotifications()
		self.updateLoggedInStatus()
	}
	
	func prepareToHide() {
		NotificationCenter.default.removeObserver(self)
	}
	
}
