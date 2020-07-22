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

class TimelineViewController: UIViewController {

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
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        self.loadTimeline()
    }
		
	func setupTableView() {
		self.refreshControl.addTarget(self, action: #selector(loadTimeline), for: .valueChanged)
		self.tableView.addSubview(self.refreshControl)
		self.loadFrequentlyUsedEmoji()
	}
	
	func setupNotifications() {
		// Clear out any old notification registrations...
		NotificationCenter.default.removeObserver(self)

		NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardShowNotification(_:)), name: .scrollTableViewNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardOnScreenNotification(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardOffScreenNotification(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShowNotification(_:)), name: UIResponder.keyboardDidShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleViewConversationNotification(_:)), name: .viewConversationNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleCurrentUserUpdatedNotification), name: .currentUserUpdatedNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleImageLoadedNotification(_:)), name: .refreshCellNotification, object: nil)
	}
	
	func updateLoggedInStatus() {
		let token = Settings.snippetsToken()
		self.loggedOutView.isHidden = (token != nil)
		self.loggedOutView.superview?.bringSubviewToFront(self.loggedOutView)
	}
	
	@IBAction func onShowLogin() {
		NotificationCenter.default.post(name: .showLoginNotification, object: nil)
	}
	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	@objc func emojiSelected(_ button : UIButton) {
		if let emoji = button.title(for: .normal) {
			NotificationCenter.default.post(name: .emojiSelectedNotification, object: emoji)
		}
	}
	
	@objc func keyboardOnScreenNotification(_ notification : Notification) {
		if let info : [AnyHashable : Any] = notification.userInfo {
			if let value : NSValue = info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
				// run later outside of animation context
				DispatchQueue.main.async {
					// start at bottom of screen
					var start_r = self.view.bounds
					start_r.origin.y = start_r.size.height
					start_r.size.height = self.keyboardAccessoryView.bounds.size.height
					self.keyboardAccessoryView.frame = start_r
					self.view.addSubview(self.keyboardAccessoryView)

					// show it
					self.keyboardAccessoryView.isHidden = false
					self.keyboardAccessoryView.alpha = 1.0

					// animate into position
					let frame = value.cgRectValue
					let height = self.keyboardAccessoryView.frame.size.height
					let safeArea : CGFloat = self.view.safeAreaInsets.bottom
					let offset = frame.origin.y - height + safeArea

					// TODO: this would be better using the UIKeyboard curve
					UIView.animate(withDuration: 0.3, delay: 0.05, options: [ .curveEaseInOut ], animations: {
						self.keyboardAccessoryView.frame = CGRect(x: 0, y: offset, width: frame.size.width, height: height)
					})
				}
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
		
		if let dictionary = notification.object as? [String : Any] {
			let keyboardRect = dictionary["keyboardOffset"] as! CGRect
			var tableViewLocation = dictionary["tableViewLocation"] as! CGFloat
			let keyboardTop = keyboardRect.origin.y - self.keyboardAccessoryView.frame.size.height
			tableViewLocation = tableViewLocation - self.keyboardAccessoryView.frame.size.height
			let screenOffset = self.tableView.frame.origin.y + (tableViewLocation - self.tableView.contentOffset.y)
			let visibleOffset = self.tableView.contentOffset.y + (screenOffset - keyboardTop) + 60.0
			
			self.tableView.setContentOffset(CGPoint(x: 0, y: visibleOffset), animated: true)
		}
	}
	
	@objc func handleImageLoadedNotification(_ notification : Notification) {
        if let indexPath = notification.object as? IndexPath {
			if indexPath.row < self.tableViewData.count {
				if let visibleCells = self.tableView.indexPathsForVisibleRows {
					if visibleCells.contains(indexPath) {
						self.tableView.reloadRows(at: [ indexPath ], with: .none)
					}
				}
			}
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
		
	@objc func handleCurrentUserUpdatedNotification() {
		self.loadTimeline()
	}
	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	func loadFrequentlyUsedEmoji() {
		let emoji = Tagmoji.shared.frequentlyUsedEmoji()
		let scrollView = UIScrollView()
		let contentView = UIView()
		scrollView.addSubview(contentView)
		scrollView.backgroundColor = UIColor(named: "color_emoji_selection")!
		
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
		self.loggedOutView.superview?.bringSubviewToFront(self.loggedOutView)

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
                        
                        if post.images.count > 0 {
                            self.tableViewData.append(post)
                            
                            let indexPath = IndexPath(row: row, section: 0)
                            indexPaths.append(indexPath)
                            row = row + 1
                        }
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
				ImageCache.fetch(self, imageSource) { (image) in
					if let _ = image {
						DispatchQueue.main.async {
							NotificationCenter.default.post(name: .refreshCellNotification, object: indexPath)
						}
					}
				}
			}
		}
		
		let avatarSource = post.owner.avatarURL
		if ImageCache.prefetch(avatarSource) == nil {
			ImageCache.fetch(self, avatarSource) { (image) in
				if let _ = image {
					DispatchQueue.main.async {
						NotificationCenter.default.post(name: .refreshCellNotification, object: indexPath)
					}
				}
			}
		}
	}
	
}


/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

extension TimelineViewController : UITableViewDataSource, UITableViewDelegate, UITableViewDataSourcePrefetching {
	
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
		
		if indexPath.row > (self.tableViewData.count - 3) {
			self.loadMoreTimeline()
		}
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		let post = self.tableViewData[indexPath.row]
		let imagePath = post.images[0]
		var dictionary : [String : Any] = [:]
		dictionary["imagePath"] = imagePath
		dictionary["post"] = post
		
		NotificationCenter.default.post(name: .viewPostNotification, object: dictionary)
	}

	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		let post = self.tableViewData[indexPath.row]
		return SunlitPostTableViewCell.height(post, parentWidth: tableView.bounds.size.width)
	}

}


/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

extension TimelineViewController : UITextViewDelegate {

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


