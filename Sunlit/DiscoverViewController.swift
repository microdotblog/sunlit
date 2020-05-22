//
//  DiscoverViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/17/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import SafariServices

class DiscoverViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UITextViewDelegate {
	
	@IBOutlet var tableView : UITableView!
	@IBOutlet var scrollView : UIScrollView!
	@IBOutlet var stackView : UIStackView!
	var keyboardAccessoryView : UIView!

	@IBOutlet var stackViewWidthConstraint : NSLayoutConstraint!
	var selectedButton : UIButton? = nil
	
	var refreshControl = UIRefreshControl()
	var tableViewData : [SunlitPost] = []
	var tagmojiDictionary : [String : String] = [:]
	

    override func viewDidLoad() {
        super.viewDidLoad()
        
		self.setupTableView()
		self.loadFrequentlyUsedEmoji()
		self.title = "Discover photos"
		self.navigationItem.title = "Discover photos"
		
		Tagmoji.shared.refresh { (updated) in
			self.loadTagmoji()
		}
		
		self.setupSnippets()
	}
	
	
	func setupTableView() {
		self.refreshControl.addTarget(self, action: #selector(setupSnippets), for: .valueChanged)
		self.tableView.addSubview(self.refreshControl)
	}

	func setupNotifications() {
		NotificationCenter.default.addObserver(self, selector: #selector(handleImageLoadedNotification(_:)), name: NSNotification.Name("Feed Image Loaded"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleUserProfileSelectedNotification), name: NSNotification.Name("Display User Profile"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardShowNotification(_:)), name: NSNotification.Name("Keyboard Appear"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleReplyResponseNotification(_:)), name: NSNotification.Name("Reply Response"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleViewConversationNotification(_:)), name: NSNotification.Name("View Conversation"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardOnScreenNotification(_:)), name: UIResponder.keyboardDidShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardOffScreenNotification(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.setupNotifications()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		NotificationCenter.default.removeObserver(self)
	}

	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */
	

	func refreshTableView(_ entries : [SnippetsPost]) {
		
		var posts : [SunlitPost] = []
		
		for entry in entries {
			let post = SunlitPost.create(entry)
			if post.images.count > 0 {
				posts.append(post)
			}
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
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		let post = self.tableViewData[indexPath.row]

		let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
		let imageViewController = storyBoard.instantiateViewController(withIdentifier: "ImageViewerViewController") as! ImageViewerViewController
		imageViewController.pathToImage = post.images[0]
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
	
	@objc func tagmojiSelected(_ button : UIButton) {
		if let selected = self.selectedButton {
			selected.isSelected = false
		}
		
		self.selectedButton = button
		button.isSelected = true
		
		if let emoji = button.title(for: .normal),
			let title = Tagmoji.shared.tileFor(tagmoji: emoji),
			let collection = Tagmoji.shared.routeFor(tagmoji: emoji) {

			DispatchQueue.main.async {
				self.navigationController?.navigationBar.topItem?.title = "Discover " + title
				self.refreshTableView([])
			}
			
			Snippets.shared.fetchDiscoverTimeline(collection: collection) { (error, postObjects, tagmoji) in
				DispatchQueue.main.async {
					self.refreshTableView(postObjects)
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
		if let offset = notification.object as? CGFloat {
			self.tableView.setContentOffset(CGPoint(x: 0, y: offset + 100.0), animated: true)
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
		
		Dialog.information(message, self)
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

	func loadTimeline() {
		Snippets.shared.fetchDiscoverTimeline(collection: "photos") { (error, postObjects, tagmoji) in
			DispatchQueue.main.async {
				self.navigationController?.navigationBar.topItem?.title = "Discover photos"
				self.refreshTableView(postObjects)
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
						
					let button = UIButton(type: .system)
					button.frame = CGRect(x: buttonOffset.x, y: buttonOffset.y, width: 44, height: 44)
					button.setTitle(tagmoji, for: .normal)
						
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
		let post = self.tableViewData[indexPath.row]
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

}
