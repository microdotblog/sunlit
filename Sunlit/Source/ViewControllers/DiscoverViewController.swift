//
//  DiscoverViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/17/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import SafariServices
import Snippets

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
	var isShowingCollectionView = true
	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

    override func viewDidLoad() {
        super.viewDidLoad()
        
		self.setupTableViewAndCollectionView()
		self.loadFrequentlyUsedEmoji()
		self.setupSnippets()
	}

	func setupNavigation() {
		var items: [ UIImage ]  = []
		if let grid_image = UIImage(systemName: "square.grid.2x2") {
			items.append(grid_image)
		}
		if let list_image = UIImage(systemName: "rectangle.grid.1x2") {
			items.append(list_image)
		}
		let segmented_control = UISegmentedControl(items: items)
		
		if self.isShowingCollectionView {
			segmented_control.selectedSegmentIndex = 0
		}
		else {
			segmented_control.selectedSegmentIndex = 1
		}
		
		segmented_control.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
		self.navigationController?.navigationBar.topItem?.titleView = segmented_control
	}
	
	@IBAction func segmentChanged(_ sender: UISegmentedControl) {
		if sender.selectedSegmentIndex == 0 {
			self.isShowingCollectionView = true
		}
		else {
			self.isShowingCollectionView = false
		}
		
		self.refresh(self.posts)

		if self.isShowingCollectionView {
			self.collectionView.isHidden = false
			self.tableView.isHidden = true
		}
		else {
			self.collectionView.isHidden = true
			self.tableView.isHidden = false
		}
	}

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        self.loadTimeline()
    }

		
	func setupTableViewAndCollectionView() {
		self.tableViewRefreshControl.addTarget(self, action: #selector(setupSnippets), for: .valueChanged)
		self.tableView.addSubview(self.tableViewRefreshControl)
		
		self.collectionViewRefreshControl.addTarget(self, action: #selector(setupSnippets), for: .valueChanged)
		self.collectionView.addSubview(self.collectionViewRefreshControl)
	}

	func setupNotifications() {
		// Clear out any old notification registrations...
		NotificationCenter.default.removeObserver(self)

		NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardShowNotification(_:)), name: .scrollTableViewNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleImageLoadedNotification(_:)), name: .refreshCellNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleViewConversationNotification(_:)), name: .viewConversationNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardOnScreenNotification(_:)), name: UIResponder.keyboardDidShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardOffScreenNotification(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
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
		
		if self.isShowingCollectionView {
			self.collectionView.reloadData()
		}
		else {
			self.tableView.reloadData()
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
				if self.isShowingCollectionView {
					self.collectionView.isHidden = false
				}

				self.refresh(postObjects)
				self.loadingData = false
                
				if let tagmojiData = tagmoji {
					if Tagmoji.shared.updateFromServerResponse(tagmojiData) {
						self.loadTagmoji()
					}
				}
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
		self.keyboardAccessoryView.isHidden = false
		self.view.addSubview(self.keyboardAccessoryView)
	}


	func loadTagmoji() {
		
		DispatchQueue.main.async {
			
			for subview in self.stackView.arrangedSubviews {
				subview.removeFromSuperview()
			}
			
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
			ImageCache.fetch(self, imageSource) { (image) in
				if let _ = image {
					DispatchQueue.main.async {
						NotificationCenter.default.post(name: .refreshCellNotification, object: indexPath)
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
	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	@objc func emojiSelected(_ button : UIButton) {
		if let emoji = button.title(for: .normal) {
			NotificationCenter.default.post(name: .emojiSelectedNotification, object: emoji)
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
				self.setupNavigation()
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
		UIView.animate(withDuration: 0.25) {
			self.keyboardAccessoryView.alpha = 0.0
		}
	}
	
	
	@objc func handleKeyboardShowNotification(_ notification : Notification) {
		if let dictionary = notification.object as? [String : Any] {
			let keyboardRect = dictionary["keyboardOffset"] as! CGRect
			let keyboardTop = keyboardRect.origin.y - self.keyboardAccessoryView.frame.size.height
			var tableViewLocation = dictionary["tableViewLocation"] as! CGFloat
			tableViewLocation = tableViewLocation - self.keyboardAccessoryView.frame.size.height
			let screenOffset = self.tableView.frame.origin.y + (tableViewLocation - self.tableView.contentOffset.y)
			let visibleOffset = self.tableView.contentOffset.y + (screenOffset - keyboardTop) + 60.0
			
			self.tableView.setContentOffset(CGPoint(x: 0, y: visibleOffset), animated: true)
		}
	}
	
	@objc func handleImageLoadedNotification(_ notification : Notification) {
		DispatchQueue.main.async {
            if !self.tableView.isHidden {
                if let indexPath = notification.object as? IndexPath,
                   let visibleIndexPaths = self.tableView.indexPathsForVisibleRows {
                    
                    if visibleIndexPaths.contains(indexPath) {
                        self.tableView.performBatchUpdates {
                            self.tableView.reloadRows(at: [indexPath], with: .fade)
                        }
                        completion: { (complete) in
                            
                        }
                    }
                }
            }
            
            if !self.collectionView.isHidden {
                if let indexPath = notification.object as? IndexPath {
                    
                    let visibleIndexPaths = self.collectionView.indexPathsForVisibleItems
                    if visibleIndexPaths.contains(indexPath) {
                        self.collectionView.performBatchUpdates {
                            self.collectionView.reloadItems(at: [indexPath])
                        }
                        completion: { (complete) in
                
                        }
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

extension DiscoverViewController : UITableViewDelegate, UITableViewDataSource, UITableViewDataSourcePrefetching {
	
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
		
		let imagePath = post.images[indexPath.item]
		var dictionary : [String : Any] = [:]
		dictionary["imagePath"] = imagePath
		dictionary["post"] = post
		
		NotificationCenter.default.post(name: .viewPostNotification, object: dictionary)
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		let post = self.posts[indexPath.row]
		return SunlitPostTableViewCell.height(post, parentWidth: tableView.bounds.size.width)
	}
}

/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

extension DiscoverViewController : UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDataSourcePrefetching, UICollectionViewDelegateFlowLayout {
	
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
		let imagePath = post.images[0]
		var dictionary : [String : Any] = [:]
		dictionary["imagePath"] = imagePath
		dictionary["post"] = post
		
		NotificationCenter.default.post(name: .viewPostNotification, object: dictionary)
	}
	
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

		var collectionViewWidth = collectionView.bounds.size.width
		
		if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
			collectionViewWidth = collectionViewWidth - flowLayout.sectionInset.left
			collectionViewWidth = collectionViewWidth - flowLayout.sectionInset.right
			
			collectionViewWidth = collectionViewWidth - collectionView.contentInset.left
			collectionViewWidth = collectionViewWidth - collectionView.contentInset.right
		}
		
		let size = PhotoEntryCollectionViewCell.sizeOf(collectionViewWidth: collectionViewWidth)
		return size
	}
	
	func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        self.prefetchImages(indexPath)
	}
	
	func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
		for indexPath in indexPaths {
            self.prefetchImages(indexPath)
        }
	}
	
	func configurePhotoCell(_ cell : PhotoEntryCollectionViewCell, _ indexPath : IndexPath) {
		if indexPath.item < self.posts.count {
			let post = self.posts[indexPath.item]
			cell.date.text = "@\(post.owner.userName)"

			cell.photo.image = nil
			if let image = ImageCache.prefetch(post.images.first ?? "") {
				cell.photo.image = image
			}
			cell.contentView.clipsToBounds = true
		}
	}
	
}


/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

extension DiscoverViewController : SnippetsScrollContentProtocol {
	func prepareToDisplay() {
		self.setupNavigation()
		self.setupNotifications()
		self.loadTagmoji()
	}
	
	func prepareToHide() {
		NotificationCenter.default.removeObserver(self)
	}
	
}
