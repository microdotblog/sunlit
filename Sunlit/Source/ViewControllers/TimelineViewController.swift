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

class TimelineViewController: ContentViewController {

	@IBOutlet var tableView : UITableView!
	@IBOutlet var loggedOutView : UIView!
	@IBOutlet var spinner: UIActivityIndicatorView!
		
	var refreshControl = UIRefreshControl()
	var keyboardAccessoryView : UIView!
	var tableViewData : [SunlitPost] = []
	var loadingData = false
    var noMoreToLoad = false
	
    override func viewDidLoad() {
        super.viewDidLoad()

		self.setupNavigation()
		self.setupTableView()
		
		self.loadTimeline()
	}
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        self.loadTimeline()
    }

	func setupTableView() {
		self.refreshControl.addTarget(self, action: #selector(loadTimeline), for: .valueChanged)
		self.tableView.addSubview(self.refreshControl)
		
//		self.loadFrequentlyUsedEmoji()
	}

    override func navbarTitle() -> String {
        return "Timeline"
    }

    override func prepareToDisplay() {
        super.prepareToDisplay()

        self.updateLoggedInStatus()
    }

	override func setupNotifications() {
        super.setupNotifications()

//		NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardShowNotification(_:)), name: .scrollTableViewNotification, object: nil)
//		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShowNotification(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
//		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHideNotification(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
//		NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShowNotification(_:)), name: UIResponder.keyboardDidShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleViewConversationNotification(_:)), name: .viewConversationNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleCurrentUserUpdatedNotification), name: .currentUserUpdatedNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleImageLoadedNotification(_:)), name: .refreshCellNotification, object: nil)
    }

    @objc override func handleScrollToTopGesture() {
        if tableViewData.count > 0 {
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }
    }
	
	func updateLoggedInStatus() {
		self.loggedOutView.isHidden = (SnippetsUser.current() != nil)
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
	
	@objc func keyboardWillShowNotification(_ notification : Notification) {
		if let info : [AnyHashable : Any] = notification.userInfo {
			if let value : NSValue = info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
				// run later outside of animation context
				DispatchQueue.main.async {
					// start at bottom of screen
					var start_r = self.view.bounds
					start_r.origin.y = start_r.size.height + self.keyboardAccessoryView.bounds.size.height
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
					var offset = frame.origin.y - height
					
					if UIDevice.current.userInterfaceIdiom == .phone {
						offset = offset + safeArea
					}

					if let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double {
						let curve_default = 7
						let curve_value = (info[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.intValue ?? curve_default
						let options = UIView.AnimationOptions(rawValue: UInt(curve_value << 16))
						UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
							self.keyboardAccessoryView.frame = CGRect(x: 0, y: offset, width: frame.size.width, height: height)
						})
					}
				}
			}
		}
	}

	@objc func keyboardWillHideNotification(_ notification : Notification) {
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

		// Don't do anything if we aren't onscreen...
		if !self.isPresented {
			return
		}

        if let indexPath = notification.object as? IndexPath {
			//if indexPath.row < self.tableViewData.count {
			if indexPath.row < self.tableView.numberOfRows(inSection: 0) {
				if let visibleCells = self.tableView.indexPathsForVisibleRows {
					if visibleCells.contains(indexPath) {
						self.tableView.reloadData()
						//self.tableView.reloadRows(at: [ IndexPath(row: indexPath.row, section: 0) ], with: .fade)
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
		scrollView.showsHorizontalScrollIndicator = false
		self.keyboardAccessoryView = scrollView
		self.keyboardAccessoryView.alpha = 0.0
	}

	func setupBlurHashes(_ postObjects : [SnippetsPost]) {
		for object in postObjects {
			let defaultPhoto = object.defaultPhoto
			let hash : String = defaultPhoto["blurhash"] as? String ?? ""
			let width : Int = (defaultPhoto["width"] as? Int ?? 0) / 10
			let height : Int = (defaultPhoto["height"] as? Int ?? 0) / 10
			if hash.count > 0 && width > 0 && height > 0 {
				BlurHash.precalculate(hash, width: width, height: height)
			}
		}
	}

	@objc func loadTimeline() {
		
        self.noMoreToLoad = false
        
		let token = Settings.snippetsToken()
		self.loggedOutView.isHidden = (token != nil)
		self.loggedOutView.superview?.bringSubviewToFront(self.loggedOutView)

		// Safety check for double loads...
		if self.loadingData == true {
			return
		}
		
		self.loadingData = true
		Snippets.Microblog.fetchCurrentUserMediaTimeline { (error, postObjects : [SnippetsPost]) in

			self.loadingData = false
			self.setupBlurHashes(postObjects)

			DispatchQueue.main.async {
                if error == nil && postObjects.count > 0 {
                    self.refreshTableView(postObjects)
                }
                else {
                    self.handleTimelineError(error as NSError?)
                }

				self.spinner.stopAnimating()
			}
		}
	}
	
	@objc func loadMoreTimeline() {
		// Safety check for double loads...
		if self.loadingData == true {
			return
		}
        
        // Don't keep reloading the same stuff over and over again...
        if self.noMoreToLoad == true {
            return
        }

		if let last = self.tableViewData.last {
			self.loadingData = true
	
			var parameters : [String : String] = [:]
			parameters["count"] = "10"
			parameters["before_id"] = last.identifier

			Snippets.Microblog.fetchCurrentUserMediaTimeline(parameters: parameters, completion:
			{ (error, entries : [SnippetsPost]) in

				self.setupBlurHashes(entries)

				DispatchQueue.main.async {
                    print("Preparing to insert rows")
                    if entries.count == 0 {
                        self.noMoreToLoad = true
                        let indexPath = IndexPath(row: self.tableViewData.count, section: 0)
						self.tableView.insertRows(at: [indexPath], with: .none)
                        return
                    }
					
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


	func prefetchPostImages(_ post : SunlitPost, indexPath : IndexPath) {

		for imageSource in post.images {
			if ImageCache.prefetch(imageSource) == nil {
				ImageCache.fetch(imageSource) { (image) in
					if let _ = image {
						DispatchQueue.main.async {
							if self.isPresented {
								if imageSource == post.images.first {
									NotificationCenter.default.post(name: .refreshCellNotification, object: indexPath)
								}
							}
						}
					}
				}
			}
		}
	}

	
	func prefetchImages(_ indexPath : IndexPath) {

		// Don't prefetch images for things that aren't visible...
		if !self.isPresented {
			return
		}

        if indexPath.row >= self.tableViewData.count {
            return
        }
        
		let post = self.tableViewData[indexPath.row]

		let avatarSource = post.owner.avatarURL
		if ImageCache.prefetch(avatarSource) == nil {
			ImageCache.fetch(avatarSource) { (image) in
				self.prefetchPostImages(post, indexPath: indexPath)
			}
		}
		else {
			self.prefetchPostImages(post, indexPath: indexPath)
		}

	}

    func handleTimelineError(_ error : NSError?) {

        if let err = error as NSError? {

            switch err.code {
            case 401, // Not authorized
                 402, // Payment required
                 451: // Unavailable for legal reasonse
                Dialog(self).information(err.localizedDescription)

            case 403: // Forbidden
                break
            case 404: // Not found
                break

            case 408: // Timeout
                // wait a few seconds before re-trying after an error
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    self.loadTimeline()
                }

            case 405, // Method not allowed
                 406, // Not acceptable
                 407, // Proxy authentication required
                 409, // Conflict
                 410, // Gone
                 411, // Length required
                 412, // Precondition failed
                 413, // Payload too large
                 414, // URI too long
                 415, // Unsupported media type
                 416, // Range not satisfiable
                 417, // Expectation failed
                 418: // I'm a teapot

                // wait a few seconds before re-trying after an error
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    //self.loadTimeline()
                }

            default:
                // wait a few seconds before re-trying after an error
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    //self.loadTimeline()
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
        var count = self.tableViewData.count
        if self.noMoreToLoad == true {
            count = count + 1
        }
        
        return count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
        if indexPath.row >= self.tableViewData.count {
            if self.tableViewData.count == 0 {
                return tableView.dequeueReusableCell(withIdentifier: "TimelineFirstTimeCell")!
            }
            else {
                return tableView.dequeueReusableCell(withIdentifier: "TimelineNoMoreCell")!
            }
        }

		let cell = tableView.dequeueReusableCell(withIdentifier: "TimelineTableViewCell", for: indexPath) as! TimelineTableViewCell
		//let cell = tableView.dequeueReusableCell(withIdentifier: "SunlitPostTableViewCell", for: indexPath) as! SunlitPostTableViewCell
		let post = self.tableViewData[indexPath.row]
		cell.setup(indexPath.row, post, parentWidth: tableView.bounds.size.width)
		return cell
	}

	func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {

		//for indexPath in indexPaths {
		//	self.prefetchImages(indexPath)
		//}
	}

	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		self.prefetchImages(indexPath)
		
		if indexPath.row > (self.tableViewData.count - 3) {
			self.loadMoreTimeline()
		}
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row >= self.tableViewData.count {
            NotificationCenter.default.post(name: .showDiscoverNotification, object:nil)
            return
        }
        
		tableView.deselectRow(at: indexPath, animated: true)
		
		let post = self.tableViewData[indexPath.row]
		//let imagePath = post.images[0]
		//var dictionary : [String : Any] = [:]
		//dictionary["imagePath"] = imagePath
		//dictionary["post"] = post
		
		NotificationCenter.default.post(name: .viewConversationNotification, object: post)
	}

	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row >= self.tableViewData.count {
            if self.tableViewData.count == 0 {
                return self.tableView.bounds.size.height - 60.0
            }
            else {
                return 265.0
            }
        }
        
		let post = self.tableViewData[indexPath.row]
		//return SunlitPostTableViewCell.height(post, parentWidth: tableView.bounds.size.width)
		return TimelineTableViewCell.height(post, parentWidth: tableView.bounds.size.width)
	}

	func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		return 60.0
	}

	func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		let footer = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 60.0))
		footer.backgroundColor = .clear
		return footer
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






