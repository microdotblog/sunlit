//
//  MainPhoneViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 6/20/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import Snippets

class MainPhoneViewController: UIViewController {

	@IBOutlet var contentView : UIView!
	@IBOutlet var scrollView : UIScrollView!
	@IBOutlet var tabBar : UIView!
	@IBOutlet var timelineButton : TabButton!
	@IBOutlet var discoverButton : TabButton!
	@IBOutlet var mentionsButton : TabButton!
	@IBOutlet var profileButton : TabButton!

	var discoverViewController : DiscoverViewController!
	var timelineViewController : TimelineViewController!
	var profileViewController : MyProfileViewController!
	var mentionsViewController : MentionsViewController!
	var currentViewController : SnippetsScrollContentProtocol? = nil

	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	
    override func viewDidLoad() {
        super.viewDidLoad()

		self.setupProfileButton()
		self.loadContentViews()
		self.updateInterfaceForLogin()
		NotificationCenter.default.addObserver(self, selector: #selector(handleCurrentUserUpdatedNotification), name: .currentUserUpdatedNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleUserMentionsUpdated), name: .mentionsUpdatedNotification, object: nil)
	}
    
	override func viewDidLayoutSubviews() {
		
		super.viewDidLayoutSubviews()
				
		var frame = self.scrollView.frame
		frame.size.width = self.view.frame.size.width
		self.scrollView.frame = frame

		self.timelineViewController.view.frame = frame
		
		frame.origin.x += frame.size.width
		self.mentionsViewController.view.frame = frame

		frame.origin.x += frame.size.width
		self.discoverViewController.view.frame = frame
				
		frame.origin.x += frame.size.width
		self.profileViewController.view.frame = frame
		
		let contentSize = CGSize(width: frame.size.width * 4.0, height: 0.0)
		self.scrollView.contentSize = contentSize
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.navigationController?.setNavigationBarHidden(false, animated: true)
		self.reloadTabs()
	}
	
	func loadContentViews() {
		
		self.addChild(self.timelineViewController)
		self.addChild(self.mentionsViewController)
		self.addChild(self.discoverViewController)
		self.addChild(self.profileViewController)

		var frame = self.scrollView.bounds
		self.scrollView.addSubview(self.timelineViewController.view)
		self.timelineViewController.view.frame = frame
		frame.origin.x += frame.size.width

		self.scrollView.addSubview(self.mentionsViewController.view)
		self.mentionsViewController.view.frame = frame
		frame.origin.x += frame.size.width

		self.scrollView.addSubview(self.discoverViewController.view)
		self.discoverViewController.view.frame = frame
		frame.origin.x += frame.size.width
		
		self.scrollView.addSubview(self.profileViewController.view)
		self.profileViewController.view.frame = frame
		frame.origin.x += frame.size.width

		self.scrollView.isUserInteractionEnabled = true
		self.scrollView.contentSize = CGSize(width: frame.origin.x, height: 0)

		self.timelineButton.isSelected = true
		self.timelineButton.isEnabled = false
		self.currentViewController = self.timelineViewController
		self.timelineViewController.prepareToDisplay()
	}
	
	func reloadTabs() {
		self.timelineViewController.tableView.reloadData()
		self.discoverViewController.tableView.reloadData()
		self.discoverViewController.collectionView.reloadData()
		self.profileViewController.collectionView.reloadData()
		self.mentionsViewController.tableView.reloadData()
	}
	
	func setupProfileButton() {
		var profileImage : UIImage? = UIImage(systemName: "person.crop.circle")
		var profileUsername = "Profile"
		if let current = SnippetsUser.current() {
			if current.userName.count < 10 {
				profileUsername = "@" + current.userName
			}
			if let image = ImageCache.prefetch(current.avatarURL) {
				profileImage = image
			}
		}

		if let image = profileImage {
			profileImage = image.uuScaleAndCropToSize(targetSize: CGSize(width: 26, height: 26)).withRenderingMode(.alwaysOriginal)
		}

		self.profileButton.setTitle(profileUsername, for: .normal)
		self.profileButton.setImage(profileImage, for: .normal)
		self.profileButton.setImage(profileImage, for: .selected)
		self.profileButton.setCornerRadius(13)

		let longpressGesture = UILongPressGestureRecognizer(target: self, action: #selector(onSelectBlogConfiguration))
		self.profileButton.addGestureRecognizer(longpressGesture)
	}

	func updateInterfaceForLogin() {
		
		if let user = SnippetsUser.current() {
			
			// Update the user name...
			DispatchQueue.main.async {
                self.scrollView.isScrollEnabled = true

				if user.userName.count < 10 {
					self.profileButton.setTitle("@" + user.userName, for: .normal)
				}
				else {
					self.profileButton.setTitle("Profile", for: .normal)
				}
			}
			
			// Go ahead and go get the avatar for the logged in user
			ImageCache.fetch(self, user.avatarURL) { (image) in
				
				if let image = image {
					let	profileImage = image.uuScaleAndCropToSize(targetSize: CGSize(width: 26, height: 26)).withRenderingMode(.alwaysOriginal)
					DispatchQueue.main.async {
						self.profileButton.setImage(profileImage, for: .normal)
						self.profileButton.setImage(profileImage, for: .selected)
						self.profileButton.setCornerRadius(13)
						self.view.layoutIfNeeded()
					}
				}
			}
		}
		else {
			self.profileButton.setImage(UIImage(systemName: "person.crop.circle"), for: .normal)
			self.profileButton.setTitle("Profile", for: .normal)
			self.onTabBarButtonPressed(self.timelineButton)
            self.scrollView.isScrollEnabled = false
		}
	}

	@objc func handleCurrentUserUpdatedNotification() {
		self.updateInterfaceForLogin()
	}
	
	@objc func handleUserMentionsUpdated() {
		/*let mentionCount = SunlitMentions.shared.newMentionCount()
		
		self.mentionContainer.isHidden = true
		if mentionCount > 0 {
			self.mentionContainer.isHidden = false
			self.mentionIndicator.text = "\(mentionCount)"
		}
		*/
	}

	@IBAction func onTabBarButtonPressed(_ button : UIButton) {

        // If not logged in, show the login screen...
        if button != self.discoverButton {
            if SnippetsUser.current() == nil {
                NotificationCenter.default.post(name: .showLoginNotification, object: nil)
                self.onShowTimeline()
                return
            }
        }
        
        if button == self.profileButton {
            self.onShowProfile()
		}
		if button == self.timelineButton {
			self.onShowTimeline()
		}
		if button == self.discoverButton {
			self.onShowDiscover()
		}
		if button == self.mentionsButton {
			self.onShowMentions()
		}
		
	}
	
	@objc func onSelectBlogConfiguration() {
		Dialog(self).selectBlog()
	}
				
	func onShowTimeline() {
        var animate = false
        if self.currentViewController == self.mentionsViewController {
            animate = true
        }

		var offset =  self.scrollView.contentOffset
		offset.x = 0.0
		self.scrollView.setContentOffset(offset, animated: animate)
		self.timelineViewController.loadTimeline()
        self.updateTabBar(self.scrollView)
        self.updateCurrentViewController(self.scrollView)
	}

	func onShowMentions() {
        var animate = false
        if self.currentViewController == self.timelineViewController ||
            self.currentViewController == self.discoverViewController {
            animate = true
        }
        
		var offset =  self.scrollView.contentOffset
		offset.x = self.scrollView.bounds.size.width * 1.0
		self.scrollView.setContentOffset(offset, animated: animate)
        if !animate {
            self.updateTabBar(self.scrollView)
            self.updateCurrentViewController(self.scrollView)
        }
	}

	func onShowDiscover() {
        var animate = false
        if self.currentViewController == self.mentionsViewController ||
            self.currentViewController == self.profileViewController{
            animate = true
        }

		var offset =  self.scrollView.contentOffset
		offset.x = self.scrollView.bounds.size.width * 2.0
		self.scrollView.setContentOffset(offset, animated: animate)
        self.updateTabBar(self.scrollView)
        self.updateCurrentViewController(self.scrollView)
	}
	
	func onShowProfile() {
        var animate = false
        if self.currentViewController == self.discoverViewController {
            animate = true
        }

		var offset =  self.scrollView.contentOffset
		offset.x = self.scrollView.bounds.size.width * 3.0
		self.scrollView.setContentOffset(offset, animated: animate)
        self.updateTabBar(self.scrollView)
        self.updateCurrentViewController(self.scrollView)
	}

}


/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

extension MainPhoneViewController : UIScrollViewDelegate {

    func updateTabBar(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.x
        let frameSize = scrollView.bounds.size.width

        self.timelineButton.isEnabled = true
        self.profileButton.isEnabled = true
        self.discoverButton.isEnabled = true
        self.mentionsButton.isEnabled = true
        self.timelineButton.isSelected = false
        self.profileButton.isSelected = false
        self.discoverButton.isSelected = false
        self.mentionsButton.isSelected = false
        
        if offset < (frameSize / 2.0) {
            self.timelineButton.isSelected = true
            self.timelineButton.isEnabled = false
        }
        else if offset < (frameSize + (frameSize / 2.0)) {
            self.mentionsButton.isSelected = true
            self.mentionsButton.isEnabled = false
        }
        else if offset < (frameSize * 2.0 + (frameSize / 2.0)) {
            self.discoverButton.isSelected = true
            self.discoverButton.isEnabled = false
        }
        else {
            self.profileButton.isSelected = true
            self.profileButton.isEnabled = false
        }
    }

    
    func updateCurrentViewController(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.x
        let frameSize = scrollView.bounds.size.width

        let previousViewController = self.currentViewController
        if offset < (frameSize / 2.0) {
            self.currentViewController = self.timelineViewController
        }
        else if offset < (frameSize + (frameSize / 2.0)) {
            self.currentViewController = self.mentionsViewController
        }
        else if offset < (frameSize * 2.0 + (frameSize / 2.0)) {
            self.currentViewController = self.discoverViewController
        }
        else {
            self.currentViewController = self.profileViewController
        }
        
        if !(previousViewController === self.currentViewController) {
            previousViewController?.prepareToHide()
            self.currentViewController?.prepareToDisplay()
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.updateCurrentViewController(scrollView)
            self.updateCurrentViewController(self.scrollView)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.updateCurrentViewController(scrollView)
        self.updateCurrentViewController(self.scrollView)
    }
    
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.updateTabBar(scrollView)
	}
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        self.updateTabBar(scrollView)
        self.updateCurrentViewController(self.scrollView)
    }
}

