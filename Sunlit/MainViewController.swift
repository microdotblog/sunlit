//
//  MainViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/22/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import SafariServices
import AVFoundation
import Snippets

class MainViewController: UIViewController {

	@IBOutlet var menuVersionLabel : UILabel!
	@IBOutlet var menuView : UIView!
	var menuDimView : UIButton!

	var tabBar : UIView!
	var contentView : UIView!
	var discoverViewController : DiscoverViewController!
	var timelineViewController : TimelineViewController!
	var profileViewController : MyProfileViewController!
	var loginViewController : LoginViewController?
	var currentViewController : SnippetsScrollContentProtocol? = nil
	
	var scrollView : UIScrollView!
	
	var timelineButton : UIButton!
	var discoverButton : UIButton!
	var profileButton : UIButton!
	
    override func viewDidLoad() {
        super.viewDidLoad()

		self.setupNotifications()
		self.loadPrimaryViewsFromStoryboards()
		
		self.constructPhoneInterface()
		self.setupSnippets()
		
		// Default to the timeline view...
		self.timelineButton.isSelected = true
		self.currentViewController = self.timelineViewController
		self.timelineViewController.prepareToDisplay()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.navigationController?.setNavigationBarHidden(false, animated: true)
	}
	
	override func viewWillLayoutSubviews() {
		
		super.viewWillLayoutSubviews()
		
		var frame = self.scrollView.bounds

		self.timelineViewController.view.frame = frame
		
		frame.origin.x += frame.size.width
		self.discoverViewController.view.frame = frame
		
		frame.origin.x += frame.size.width
		self.profileViewController.view.frame = frame
	}
	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	func setupSnippets() {
		let blogIdentifier = Settings.selectedBlogIdentifier()
		if let token = Settings.permanentToken() {
			Snippets.shared.configure(permanentToken: token, blogUid: blogIdentifier)
		}

		self.onShowTimeline()
	}


	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	func setupNotifications() {
		NotificationCenter.default.addObserver(self, selector: #selector(handleTemporaryTokenReceivedNotification(_:)), name: NSNotification.Name("TemporaryTokenReceivedNotification"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleOpenURLNotification(_:)), name: NSNotification.Name("OpenURLNotification"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(onShowLogin), name: NSNotification.Name("Show Login"), object: nil)
	}

	@objc func handleOpenURLNotification(_ notification : Notification) {
		if let path = notification.object as? String,
			let url = URL(string: path){
			
			let safariViewController = SFSafariViewController(url: url)
			self.present(safariViewController, animated: true, completion: nil)
		}
	}
	
	
	@objc func handleTemporaryTokenReceivedNotification(_ notification : Notification) {
		if let temporaryToken = notification.object as? String
		{
			Snippets.shared.requestPermanentTokenFromTemporaryToken(token: temporaryToken) { (error, token) in
				if let permanentToken = token
				{
					
					// Save our info and setup Snippets
					Settings.savePermanentToken(permanentToken)
					Snippets.shared.configure(permanentToken: permanentToken, blogUid: nil)

					// We can hide the login view now...
					DispatchQueue.main.async {
						self.loginViewController?.dismiss(animated: true, completion: nil)
						self.timelineViewController.prepareToDisplay()
						self.timelineViewController.loadTimeline()
					}
					
					Snippets.shared.fetchCurrentUserInfo { (error, updatedUser) in
						
						if let user = updatedUser {
							_ = SnippetsUser.saveAsCurrent(user)
							
							self.updateInterfaceForLogin()
							self.onSelectBlogConfiguration()
						}
					}
				}
			}
		}
	}
	
	@objc func onToggleHamburgerMenu() {
		let width : CGFloat = 180.0
		let closedRect = CGRect(x: -width, y: 0.0, width: width, height: self.view.bounds.size.height)
		let openRect = CGRect(x: 0.0, y: 0.0, width: width, height: self.view.bounds.size.height)
		
		if self.menuDimView == nil {
			self.menuDimView = UIButton(type: .custom)
			self.menuDimView.backgroundColor = UIColor(white: 0.2, alpha: 0.8)
			self.menuDimView.addTarget(self, action: #selector(onToggleHamburgerMenu), for: .touchUpInside)
		}
		
		if self.menuView.superview == nil {
			self.menuDimView.frame = self.view.bounds
			self.menuView.frame = closedRect
			self.view.addSubview(self.menuDimView)
			self.view.addSubview(self.menuView)
			self.view.updateConstraints()
			self.view.layoutIfNeeded()
			
			self.menuDimView.alpha = 0.0
			
			var frame = self.contentView.frame
			frame.origin.x = frame.origin.x + 15
			self.menuView.isUserInteractionEnabled = true
			let swipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(onToggleHamburgerMenu))
			swipeGestureRecognizer.direction = .left
			self.menuView.addGestureRecognizer(swipeGestureRecognizer)
		
			UIView.animate(withDuration: 0.15) {
				self.menuDimView.alpha = 1.0
				//self.contentView.frame = frame
			}
			
			UIView.animate(withDuration: 0.2, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.7, options: .curveEaseInOut, animations: {
				self.menuView.frame = openRect
				self.contentView.transform = CGAffineTransform(translationX: 10.0, y: 0.0)
			}, completion: nil)
		}
		else {
			var frame = self.contentView.frame
			frame.origin.x = 0
			UIView.animate(withDuration: 0.15, animations: {
				self.menuView.frame = closedRect
				self.menuDimView.alpha = 0.0
				//self.contentView.frame = frame
				self.contentView.transform = CGAffineTransform.identity
			}) { (complete) in
				self.menuView.removeFromSuperview()
				self.menuDimView.removeFromSuperview()
			}
		}
	}
	
	@IBAction func onAbout() {
		let storyBoard: UIStoryboard = UIStoryboard(name: "About", bundle: nil)
		let newPostViewController = storyBoard.instantiateViewController(withIdentifier: "AboutViewController")
		self.present(newPostViewController, animated: true, completion: nil)

		self.onToggleHamburgerMenu()
	}
	
	@IBAction func onDrafts() {
		let storyBoard: UIStoryboard = UIStoryboard(name: "Drafts", bundle: nil)
		let newPostViewController = storyBoard.instantiateViewController(withIdentifier: "DraftsViewController")
		self.present(newPostViewController, animated: true, completion: nil)

		self.onToggleHamburgerMenu()
	}
	
	@IBAction func onSettings() {
		let storyBoard: UIStoryboard = UIStoryboard(name: "Settings", bundle: nil)
		let newPostViewController = storyBoard.instantiateViewController(withIdentifier: "SettingsViewController")
		self.present(newPostViewController, animated: true, completion: nil)

		self.onToggleHamburgerMenu()
	}
	
	@objc func onNewPost() {
		let pickerController = UIImagePickerController()
		pickerController.modalPresentationCapturesStatusBarAppearance = true
		pickerController.delegate = self
		pickerController.allowsEditing = false
		pickerController.mediaTypes = ["public.image", "public.movie"]
		pickerController.sourceType = .savedPhotosAlbum
		self.present(pickerController, animated: true, completion: nil)
	}
	
	@objc func onShowLogin() {
		let storyboard = UIStoryboard(name: "Login", bundle: nil)
		self.loginViewController = storyboard.instantiateViewController(identifier: "LoginViewController")
		self.present(self.loginViewController!, animated: true, completion: nil)
	}
	
	@objc func onShowTimeline() {
		if let loginViewController = self.loginViewController {
			loginViewController.dismiss(animated: true, completion: nil)
			self.loginViewController = nil
		}

		var offset =  self.scrollView.contentOffset
		offset.x = 0.0
		self.scrollView.setContentOffset(offset, animated: true)
		self.timelineViewController.loadTimeline()
	}
	
	@objc func onShowProfile() {
		if let loginViewController = self.loginViewController {
			loginViewController.dismiss(animated: true, completion: nil)
			self.loginViewController = nil
		}
		
		var offset =  self.scrollView.contentOffset
		offset.x = self.scrollView.bounds.size.width * 2.0
		
		self.scrollView.setContentOffset(offset, animated: true)
	}
	
	@objc func onShowDiscover() {
		var offset =  self.scrollView.contentOffset
		offset.x = self.scrollView.bounds.size.width * 1.0
		
		self.scrollView.setContentOffset(offset, animated: true)
	}
	
	@objc func onSelectBlogConfiguration() {
		Dialog(self).selectBlog()
	}
	
	@IBAction func onLogout() {
		
		self.onToggleHamburgerMenu()
		
		let alertController = UIAlertController(title: "Logout", message: "Are you sure you want to logout?", preferredStyle: .alert)
		alertController.addAction(UIAlertAction(title: "Logout", style: .default, handler: { (action) in
			Settings.deletePermanentToken()
			SnippetsUser.deleteCurrentUser()
			
			Snippets.shared.configure(permanentToken: "", blogUid: nil, mediaEndPoint: nil)
			self.timelineViewController.updateLoggedInStatus()
		}))
		
		alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		
		self.present(alertController, animated: true) {
		}
	}
			
	func loadPrimaryViewsFromStoryboards() {
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		self.timelineViewController = storyboard.instantiateViewController(identifier: "TimelineViewController")
		self.profileViewController = storyboard.instantiateViewController(identifier: "MyProfileViewController")
		self.discoverViewController = storyboard.instantiateViewController(identifier: "DiscoverViewController")
	}

	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	func setupPhoneNavigationBar() {
		//let hamburgerMenuButton = UIBarButtonItem(image: UIImage(named: "hamburger"), style: .plain, target: self, action: #selector(onToggleHamburgerMenu))
		let postButton = UIBarButtonItem(image: UIImage(named: "post"), style: .plain, target: self, action: #selector(onNewPost))

		self.navigationItem.title = "Timeline"
		//self.navigationItem.leftBarButtonItem = hamburgerMenuButton
		self.navigationItem.rightBarButtonItem = postButton
	}

	func setupPhoneContentView() {
		
		self.addChild(self.timelineViewController)
		self.addChild(self.discoverViewController)
		self.addChild(self.profileViewController)
		
		self.contentView = UIView()
		self.contentView.clipsToBounds = false
		
		self.view.addSubview(self.contentView)
		
		self.contentView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.self.width, height: self.view.bounds.size.height)
		self.contentView.translatesAutoresizingMaskIntoConstraints = false
		
		self.contentView.constrainTop(view: self.view)
		self.contentView.constrainLeft(view: self.view)
		self.contentView.constrainRight(view: self.view)
		self.tabBar.constrainTop(bottomOfView: self.contentView)
		
		self.scrollView = UIScrollView()
		self.scrollView.translatesAutoresizingMaskIntoConstraints = false
		self.contentView.addSubview(self.scrollView)
		
		self.scrollView.constrainLeft(view: self.contentView)
		self.scrollView.constrainRight(view: self.contentView)
		self.scrollView.constrainBottom(view: self.contentView)
		self.scrollView.constrainTop(view: self.contentView, offset : 88.0)
		
		// Force a layout here...
		self.view.layoutIfNeeded()
		
		var frame = self.scrollView.bounds
		self.scrollView.addSubview(self.timelineViewController.view)
		self.timelineViewController.view.frame = frame
		frame.origin.x += frame.size.width

		self.scrollView.addSubview(self.discoverViewController.view)
		self.discoverViewController.view.frame = frame
		frame.origin.x += frame.size.width

		self.scrollView.addSubview(self.profileViewController.view)
		self.profileViewController.view.frame = frame
		frame.origin.x += frame.size.width

		self.scrollView.isUserInteractionEnabled = true
		self.scrollView.contentSize = CGSize(width: frame.origin.x, height: 0)
		self.scrollView.isPagingEnabled = true
		self.scrollView.delegate = self
	}
	
	func setupPhoneTabBar() {
		
		let tabBarHeight : CGFloat = 120.0
		let tabBarFrame = CGRect(x: 0, y: self.view.bounds.size.height - tabBarHeight, width: self.view.bounds.size.width, height: tabBarHeight)
		self.tabBar = UIView(frame: tabBarFrame)
		self.view.addSubview(self.tabBar)
		self.tabBar.constrainHeight(tabBarHeight)
		self.tabBar.constrainLeft(view: self.view)
		self.tabBar.constrainRight(view: self.view)
		self.tabBar.constrainBottom(view: self.view)

		let stackView = UIStackView(frame: self.tabBar.bounds.inset(by: UIEdgeInsets(top: 16, left: 8, bottom: 16, right: 8)))
		stackView.backgroundColor = .clear
		
		self.timelineButton = UIButton(type: .system)
		self.discoverButton = UIButton(type: .system)
		self.profileButton = UIButton(type: .system)
		self.timelineButton.addTarget(self, action: #selector(onTabBarButtonPressed(_:)), for: .touchUpInside)
		self.discoverButton.addTarget(self, action: #selector(onTabBarButtonPressed(_:)), for: .touchUpInside)
		self.profileButton.addTarget(self, action: #selector(onTabBarButtonPressed(_:)), for: .touchUpInside)
		
		self.timelineButton.constrainHeight(60.0)
		self.discoverButton.constrainHeight(60.0)
		self.profileButton.constrainHeight(60.0)

		self.timelineButton.setTitle("Timeline", for: .normal)
		self.timelineButton.setImage(UIImage(named: "feed")!, for: .normal)
		self.discoverButton.setTitle("Discover", for: .normal)
		self.discoverButton.setImage(UIImage(named: "discover")!, for: .normal)
		self.timelineButton.setTitleColor(.label, for: .normal)
		self.discoverButton.setTitleColor(.label, for: .normal)
		self.profileButton.setTitleColor(.label, for: .normal)
		
		var profileImage : UIImage? = UIImage(named: "login")
		var profileUsername = "Login"
		if let current = SnippetsUser.current() {
			profileUsername = "@" + current.userHandle
			profileImage = ImageCache.prefetch(current.pathToUserImage)
		
			if let image = profileImage {
				profileImage = image.uuScaleAndCropToSize(targetSize: CGSize(width: 32.0, height: 32.0)).withRenderingMode(.alwaysOriginal)
			}
		}
		self.profileButton.setTitle(profileUsername, for: .normal)
		self.profileButton.setImage(profileImage, for: .normal)
		self.profileButton.imageView?.clipsToBounds = true
		self.profileButton.imageView?.layer.cornerRadius = 8.0
		
		self.profileButton.titleLabel?.font = UIFont.systemFont(ofSize: 14.0)
		self.discoverButton.titleLabel?.font = UIFont.systemFont(ofSize: 14.0)
		self.timelineButton.titleLabel?.font = UIFont.systemFont(ofSize: 14.0)

		stackView.addArrangedSubview(self.timelineButton)
		stackView.addArrangedSubview(self.discoverButton)
		stackView.addArrangedSubview(self.profileButton)
		stackView.distribution = .fillEqually
		stackView.axis = .horizontal
		//stackView.alignment = .bottom
		
		self.tabBar.addSubview(stackView)
		stackView.constrainAllSides(self.tabBar)
		stackView.layoutIfNeeded()
		
		self.timelineButton.centerVertically()
		self.discoverButton.centerVertically()
		self.profileButton.centerVertically()
		
		let longpressGesture = UILongPressGestureRecognizer(target: self, action: #selector(onSelectBlogConfiguration))
		self.profileButton.addGestureRecognizer(longpressGesture)
	}
	
	func constructPhoneInterface() {
		self.setupPhoneTabBar()
		self.setupPhoneContentView()
		self.setupPhoneNavigationBar()
		
		// Make sure the tab bar ends up on top...
		self.view.bringSubviewToFront(self.tabBar)
		
		// Update the version label...
		self.menuVersionLabel.text = "Version " + (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String)
	}
	
	func updateInterfaceForLogin() {
		
		if let user = SnippetsUser.current() {
			
			// Update the user name...
			DispatchQueue.main.async {
				self.profileButton.setTitle("@" + user.userHandle, for: .normal)
				self.profileButton.centerVertically()
			}
			
			// Go ahead and go get the avatar for the logged in user
			ImageCache.fetch(user.pathToUserImage) { (image) in
				
				if let image = image {
					let	profileImage = image.uuScaleAndCropToSize(targetSize: CGSize(width: 32.0, height: 32.0)).withRenderingMode(.alwaysOriginal)
					DispatchQueue.main.async {
						self.profileButton.setImage(profileImage, for: .normal)
						self.profileButton.centerVertically()
					}
				}
			}
		}
	}


	@objc func onTabBarButtonPressed(_ button : UIButton) {
		self.profileButton.isSelected = false
		self.timelineButton.isSelected = false
		self.discoverButton.isSelected = false
				
		button.isSelected = true
		
		if button == self.profileButton {
			if let _ = SnippetsUser.current() {
				self.onShowProfile()
			}
			else {
				self.timelineButton.isSelected = true
				self.profileButton.isSelected = false
				self.onShowLogin()
			}
		}
		if button == self.timelineButton {
			self.onShowTimeline()
		}

		if button == self.discoverButton {
			self.onShowDiscover()
		}

	}
}


/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

extension MainViewController : UIScrollViewDelegate {
	
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		let offset = scrollView.contentOffset.x
		let frameSize = scrollView.bounds.size.width

		self.timelineButton.isSelected = false
		self.profileButton.isSelected = false
		self.discoverButton.isSelected = false
		
		let previousViewController = self.currentViewController
		if offset < (frameSize / 2.0) {
			self.timelineButton.isSelected = true
			self.currentViewController = self.timelineViewController
		}
		else if offset < (frameSize + (frameSize / 2.0)) {
			self.discoverButton.isSelected = true
			self.currentViewController = self.discoverViewController
		}
		else {
			self.profileButton.isSelected = true
			self.currentViewController = self.profileViewController
		}
		
		if !(previousViewController === self.currentViewController) {
			previousViewController?.prepareToHide()
			self.currentViewController?.prepareToDisplay()
		}
		
	}
}

/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

extension MainViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		var media : SunlitMedia? = nil

		if let image = info[.editedImage] as? UIImage {
			media = SunlitMedia(withImage: image)
		}
		else if let image = info[.originalImage] as? UIImage {
			media = SunlitMedia(withImage: image)
		}
		else if let video = info[.mediaURL] as? URL {
			media = SunlitMedia(withVideo: video)
		}

		
		if let media = media {
			let storyBoard: UIStoryboard = UIStoryboard(name: "Compose", bundle: nil)
			let postViewController = storyBoard.instantiateViewController(withIdentifier: "ComposeViewController") as! ComposeViewController
			postViewController.addMedia(media)
			picker.pushViewController(postViewController, animated: true)
		}
		else {
			picker.dismiss(animated: true, completion: nil)
		}
	}
}

