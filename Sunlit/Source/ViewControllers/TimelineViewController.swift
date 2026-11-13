//
//  TimelineViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/3/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import Snippets
import UUSwiftNetworking

class TimelineViewController: ContentViewController {

	@IBOutlet var tableView : UITableView!
	@IBOutlet var loggedOutView : UIView!
	@IBOutlet var spinner: UIActivityIndicatorView!
		
	var refreshControl = UIRefreshControl()
	var tableViewData : [SunlitPost] = []
	private var loadingData = false
	private var refreshPending = false
	private var noMoreToLoad = false
	private var nextPageCursor: String?
	private var tableLayoutWidth: CGFloat = 0
	
    override func viewDidLoad() {
        super.viewDidLoad()

		self.setupNavigation()
		self.setupTableView()
		
		self.loadTimeline()
	}
    
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		let width = self.tableView.bounds.width
		guard width > 0, width != self.tableLayoutWidth else { return }
		self.tableLayoutWidth = width
		self.tableView.reloadData()
	}

	func setupTableView() {
		// Row heights are cheap to calculate exactly; estimates can shift a deep scroll position on reload.
		self.tableView.estimatedRowHeight = 0
		self.tableView.estimatedSectionHeaderHeight = 0
		self.tableView.estimatedSectionFooterHeight = 0
		self.refreshControl.addTarget(self, action: #selector(onPullToRefresh), for: .valueChanged)
		self.tableView.addSubview(self.refreshControl)
		if #available(iOS 26.0, *) {
			self.tableView.topEdgeEffect.isHidden = true
		}
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

		NotificationCenter.default.addObserver(self, selector: #selector(handleViewConversationNotification(_:)), name: .viewConversationNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleCurrentUserUpdatedNotification), name: .currentUserUpdatedNotification, object: nil)
    }

    @objc override func handleScrollToTopGesture() {
        if tableViewData.count > 0 {
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }
    }
	
	func updateLoggedInStatus() {
		self.loggedOutView.isHidden = Settings.isSignedIn
		self.loggedOutView.superview?.bringSubviewToFront(self.loggedOutView)
	}
	
	@IBAction func onShowLogin() {
		NotificationCenter.default.post(name: .showLoginNotification, object: nil)
	}
	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	@objc func handleViewConversationNotification(_ notification : Notification) {
		if let post = notification.object as? SunlitPost {
			let storyBoard: UIStoryboard = UIStoryboard(name: "Conversation", bundle: nil)
			let conversationViewController = storyBoard.instantiateViewController(withIdentifier: "ConversationViewController") as! ConversationViewController
			conversationViewController.sourcePost = post
			self.navigationController?.pushViewController(conversationViewController, animated: true)
		}
	}
		
	@objc func handleCurrentUserUpdatedNotification() {
		if !Settings.isSignedIn {
			self.resetForLogout()
			return
		}

		self.loadTimeline()
	}

	func resetForLogout() {
		self.loadingData = false
		self.refreshPending = false
		self.noMoreToLoad = false
		self.nextPageCursor = nil
		self.tableViewData = []

		guard self.isViewLoaded else {
			return
		}

		self.refreshControl.endRefreshing()
		self.spinner.stopAnimating()
		self.loggedOutView.isHidden = false
		self.loggedOutView.superview?.bringSubviewToFront(self.loggedOutView)
		self.tableView.reloadData()
	}

	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	@objc func onPullToRefresh() {
		self.loadTimeline()
	}

	func loadTimeline() {
		self.fetchTimeline()
	}

	private func loadMoreTimeline() {
		guard !self.noMoreToLoad, let cursor = self.nextPageCursor else { return }
		self.fetchTimeline(before: cursor)
	}

	private func fetchTimeline(before cursor: String? = nil) {
		guard Settings.isSignedIn else {
			self.resetForLogout()
			return
		}
		guard !self.loadingData else {
			if cursor == nil && self.refreshControl.isRefreshing {
				self.refreshPending = true
			}
			return
		}

		self.loadingData = true
		self.loggedOutView.isHidden = true
		if self.tableViewData.isEmpty && !self.refreshControl.isRefreshing {
			self.spinner.startAnimating()
		}
		let accountGeneration = Settings.accountGeneration

		let pageSize = cursor == nil ? 10 : 20
		var parameters = ["count": String(pageSize), "filter": "photos,videos"]
		parameters["before_id"] = cursor

		let configuration = Snippets.Configuration.timeline
		let request = Snippets.secureGet(configuration,
			path: configuration.microBlogPathForRoute("posts/media"), arguments: parameters)
		_ = UUHttpSession.executeRequest(request) { [weak self] response in
			let feed = response.parsedResponse as? [String: Any]
			let items = response.httpError == nil ? feed?["items"] as? [[String: Any]] : nil
			let posts = items?.map { entry in
				SunlitPost.create(SnippetsPost(entry), cacheAuthor: false)
			}

			DispatchQueue.main.async {
				guard let self, accountGeneration == Settings.accountGeneration else { return }
				self.loadingData = false
				self.spinner.stopAnimating()
				if self.refreshPending {
					self.refreshPending = false
					self.loadTimeline()
					return
				}
				self.refreshControl.endRefreshing()

				guard let posts else {
					self.handleTimelineError(response.httpError as NSError?)
					return
				}

				self.applyPage(posts, after: cursor)
			}
		}
	}

	private func applyPage(_ posts: [SunlitPost], after cursor: String?) {
		let lastID = posts.last?.identifier ?? ""
		self.nextPageCursor = lastID.isEmpty ? nil : lastID
		self.noMoreToLoad = self.nextPageCursor == nil || self.nextPageCursor == cursor
		let mediaPosts = posts.filter { !$0.images.isEmpty }

		if cursor == nil {
			self.tableViewData = mediaPosts
			self.tableView.reloadData()
		} else {
			let start = self.tableViewData.count
			self.tableViewData.append(contentsOf: mediaPosts)
			let rows = start..<(self.tableViewData.count + (self.noMoreToLoad ? 1 : 0))
			if !rows.isEmpty {
				self.tableView.insertRows(at: rows.map { IndexPath(row: $0, section: 0) }, with: .automatic)
			}
		}

		// Fetch the next page after showing the first, and skip pages with no displayable media.
		if cursor == nil || mediaPosts.isEmpty {
			self.loadMoreTimeline()
		}
	}

	private func handleTimelineError(_ error: NSError?) {
		guard let error, [401, 402, 451].contains(error.code) else { return }
		Dialog(self).information(error.localizedDescription)
	}

}


/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

extension TimelineViewController : UITableViewDataSource, UITableViewDelegate, UITableViewDataSourcePrefetching {
	
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
		let post = self.tableViewData[indexPath.row]
		cell.setup(indexPath.row, post, parentWidth: tableView.bounds.size.width)
		return cell
	}

	func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
		guard self.isPresented else { return }
		for indexPath in indexPaths where self.tableViewData.indices.contains(indexPath.row) {
			if let image = self.tableViewData[indexPath.row].images.first {
				ImageCache.loadForDisplay(image)
			}
		}
	}

	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		(cell as? TimelineTableViewCell)?.loadImages()
		if indexPath.row >= self.tableViewData.count - 3 {
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
