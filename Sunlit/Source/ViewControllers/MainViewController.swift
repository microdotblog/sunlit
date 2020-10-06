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
import UUSwift
import PhotosUI

class MainViewController: UIViewController {
	

	@IBOutlet var menuVersionLabel : UILabel!
	@IBOutlet var menuView : UIView!

	var loginViewController : LoginViewController?
	var phoneViewController : MainPhoneViewController?
	var discoverViewController : DiscoverViewController!
	var timelineViewController : TimelineViewController!
	var profileViewController : MyProfileViewController!
	var mentionsViewController : MentionsViewController!
    var bookmarksViewController : BookmarksViewController!

	var currentContentViewController : ContentViewController? = nil

	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */
	
    override func viewDidLoad() {
        super.viewDidLoad()

		self.setupNotifications()
		self.setupNavigationBar()
		self.setupSnippets()
		self.loadContentViews()
		
		if UIDevice.current.userInterfaceIdiom == .pad {
			self.onTabletShowTimeline()
		}
		else {
			self.constructPhoneInterface()
		}
	}
		
	func setupSnippets() {
		if let token = Settings.snippetsToken() {
            Snippets.Configuration.timeline = Snippets.Configuration.microblogConfiguration(token: token)
			
			SunlitMentions.shared.update {
			}
		}
	}


	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	func setupNavigationBar() {

		if UIDevice.current.userInterfaceIdiom == .phone {

            var postButton = UIBarButtonItem(image: UIImage(systemName: "square.and.pencil"), style: .plain, target: self, action: #selector(onNewPost))

            if #available(iOS 14, *) {
                postButton = UIBarButtonItem(image: UIImage(systemName: "square.and.pencil"), style: .plain, target: self, action: nil)

                let libraryAction = UIAction(title: "Photo Library", image: UIImage(systemName: "photo")) { (action) in
                    self.onNewPost()
                }

                let filesAction = UIAction(title: "Uploads", image: UIImage(systemName: "folder")) { (action) in
                    self.onUploads()
                }

                let menu = UIMenu(children: [libraryAction, filesAction])
                postButton.menu = menu
            }

            var settingsSymbol = "gear"
			if #available(iOS 14, *) {
				settingsSymbol = "gearshape"
			}
			let settingsButton = UIBarButtonItem(image: UIImage(systemName: settingsSymbol), style: .plain, target: self, action: #selector(onSettings))
			self.navigationItem.title = "Timeline"
            
            if SnippetsUser.current() != nil {
                self.navigationItem.rightBarButtonItem = postButton
                self.navigationItem.leftBarButtonItem = settingsButton
            }
            else {
                self.navigationItem.rightBarButtonItem = nil
                self.navigationItem.leftBarButtonItem = nil
            }
		}
		else if UIDevice.current.userInterfaceIdiom == .pad {
			self.navigationController?.setNavigationBarHidden(false, animated: false)
			
			let postButton = UIBarButtonItem(image: UIImage(systemName: "square.and.pencil"), style: .plain, target: self, action: #selector(onNewPost))
			if SnippetsUser.current() != nil {
				self.navigationItem.rightBarButtonItem = postButton
			}
			else {
				self.navigationItem.rightBarButtonItem = nil
			}

		}

		self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
	}

	
	func loadContentViews() {
		let storyboard = UIStoryboard(name: "Content", bundle: nil)
		self.timelineViewController = storyboard.instantiateViewController(identifier: "TimelineViewController")
		self.profileViewController = storyboard.instantiateViewController(identifier: "MyProfileViewController")
		self.discoverViewController = storyboard.instantiateViewController(identifier: "DiscoverViewController")

        let bookmarksStoryBoard: UIStoryboard = UIStoryboard(name: "Bookmarks", bundle: nil)
        self.bookmarksViewController = bookmarksStoryBoard.instantiateViewController(identifier: "BookmarksViewController")

        let mentionsStoryBoard: UIStoryboard = UIStoryboard(name: "Mentions", bundle: nil)
		self.mentionsViewController = mentionsStoryBoard.instantiateViewController(identifier: "MentionsViewController")
	}
	
	func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleUserUpdatedNotification(_:)), name: .currentUserUpdatedNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleTemporaryTokenReceivedNotification(_:)), name: .temporaryTokenReceivedNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleMicropubTokenReceivedNotification(_:)), name: .micropubTokenReceivedNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleShowLoginNotification), name: .showLoginNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleOpenURLNotification(_:)), name: .openURLNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleShowCurrentUserProfileNotification), name: .showCurrentUserProfileNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleShowTimelineNotification), name: .showTimelineNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleShowDiscoverNotification), name: .showDiscoverNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleShowBookmarksNotification), name: .showBookmarksNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleShowComposeNotification), name: .showComposeNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleShowMentionsNotification), name: .showMentionsNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleShowSettingsNotification), name: .showSettingsNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleViewPostNotification(_:)), name: .viewPostNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleViewUserProfileNotification(_:)), name: .viewUserProfileNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleReplyResponseNotification(_:)), name: .notifyReplyPostedNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleSplitViewWillCollapseNotification(_:)), name: .splitViewWillCollapseNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleSplitViewWillExpandNotification(_:)), name: .splitViewWillExpandNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleShowFollowingNotification(_:)), name: .showFollowingNotification, object: nil)
	}

	@objc func handleViewPostNotification(_ notification : Notification) {
		if let dictionary = notification.object as? [String : Any] {
			let imagePath = dictionary["imagePath"] as! String
			let post = dictionary["post"] as! SunlitPost
			let storyBoard: UIStoryboard = UIStoryboard(name: "ImageViewer", bundle: nil)
			let imageViewController = storyBoard.instantiateViewController(withIdentifier: "ImageViewerViewController") as! ImageViewerViewController
			imageViewController.pathToImage = imagePath
			imageViewController.post = post
			
			self.present(imageViewController, animated: true, completion: nil)
		}
	}
	
    @objc func handleUserUpdatedNotification(_ notification : Notification) {
        self.setupNavigationBar()
    }
    
	@objc func handleViewUserProfileNotification(_ notification : Notification) {
		if let owner = notification.object as? SnippetsUser {
            if let profileController = self.navigationController?.topViewController as? ProfileViewController {
                if profileController.user.userName == owner.userName {
                    return
                }
            }
            
			let storyBoard: UIStoryboard = UIStoryboard(name: "Profile", bundle: nil)
			let profileViewController = storyBoard.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
			profileViewController.user = owner
			self.navigationController?.pushViewController(profileViewController, animated: true)
		}
	}
	
	@objc func handleShowFollowingNotification(_ notification : Notification) {
		let storyBoard: UIStoryboard = UIStoryboard(name: "Following", bundle: nil)
		let followingViewController = storyBoard.instantiateViewController(withIdentifier: "FollowingViewController") as! FollowingViewController
		
		if let following = notification.object as? [SnippetsUser] {
			followingViewController.following = following
		}
		
		self.navigationController?.pushViewController(followingViewController, animated: true)
	}
	
	@objc func handleReplyResponseNotification(_ notification : Notification) {
		var message = "Reply posted!"
		
		if let error = notification.object as? Error {
			message = error.localizedDescription
		}
		
		Dialog(self).information(message)
	}

	
	@objc func handleOpenURLNotification(_ notification : Notification) {
		if let path = notification.object as? String,
			let url = URL(string: path){
			
			let safariViewController = SFSafariViewController(url: url)
			self.present(safariViewController, animated: true, completion: nil)
		}
	}
	
	@objc func handleShowLoginNotification() {
		let storyboard = UIStoryboard(name: "Login", bundle: nil)
		self.loginViewController = storyboard.instantiateViewController(identifier: "LoginViewController")
		let nav_controller = UINavigationController(rootViewController: self.loginViewController!)
		self.present(nav_controller, animated: true, completion: nil)
	}

	@objc func handleTemporaryTokenReceivedNotification(_ notification : Notification) {
		if let temporaryToken = notification.object as? String
		{
			Snippets.Microblog.requestPermanentTokenFromTemporaryToken(token: temporaryToken) { (error, token) in
                if let err = error {
                    DispatchQueue.main.async {
                        Dialog(self).information("Error - " + err.localizedDescription)
                    }

                    return
                }
                
                if let permanentToken = token
				{
					// Save our info and setup Snippets
					Settings.saveSnippetsToken(permanentToken)
                    
                    // Save to user prefs...
                    let blogSettings = BlogSettings(BlogSettings.timelinePath)
                    blogSettings.snippetsConfiguration = Snippets.Configuration.microblogConfiguration(token: permanentToken)
                    blogSettings.save()
                    
                    // Update the Snippets library...
                    Snippets.Configuration.timeline = blogSettings.snippetsConfiguration!

					// We can hide the login view now...
					DispatchQueue.main.async {
						self.loginViewController?.dismiss(animated: true, completion: nil)
						self.timelineViewController.prepareToDisplay()
					}
					
					Snippets.Microblog.fetchCurrentUserInfo { (error, updatedUser) in
						
						if let user = updatedUser {
							_ = SnippetsUser.saveAsCurrent(user)
							
							DispatchQueue.main.async {
								Dialog(self).selectBlog()
								NotificationCenter.default.post(name: .currentUserUpdatedNotification, object: nil)
							}
						}
					}
				}
			}
		}
	}

	@objc func handleMicropubTokenReceivedNotification(_ notification : Notification) {
		if let url = notification.object as? URL {
			if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
				var code = ""
				var state = ""
				
				if let items = components.queryItems {
					for q in items {
						if let val = q.value {
							if q.name == "code" {
								code = val
							}
							else if q.name == "state" {
								state = val
							}
						}
					}
				}

				if (code.count > 0) && (state.count > 0) {
                    let me = BlogSettings.publishingPath
                    let token_endpoint = BlogSettings(me).tokenEndpoint
					
					var params = ""
					params = params + "grant_type=authorization_code"
					params = params + "&code=" + code
					params = params + "&client_id=" + String("https://sunlit.io/").uuUrlEncoded()
					params = params + "&redirect_uri=" + String("https://sunlit.io/micropub/redirect").uuUrlEncoded()
					params = params + "&me=" + me.uuUrlEncoded()
					
					let d = params.data(using: .utf8)

					UUHttpSession.post(url: token_endpoint, queryArguments: [ : ], body: d, contentType: "application/x-www-form-urlencoded") { (parsedServerResponse) in
						if let dictionary = parsedServerResponse.parsedResponse as? [ String : Any ] {
							if let access_token = dictionary["access_token"] as? String {
								DispatchQueue.main.async {
                                    
                                    let settings = BlogSettings(BlogSettings.publishingPath)
                                    settings.microblogToken = access_token
                                    settings.save()
                                    BlogSettings.addPublishedBlog(settings)

                                    if settings.snippetsConfiguration!.type == .micropub {
										Dialog(self).selectBlog()
									}

									NotificationCenter.default.post(name: .finishedExternalConfigNotification, object: self)
								}
							}
						}
					}
				}
			}
		}
	}

	@objc func handleShowCurrentUserProfileNotification() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.onTabletShowProfile()
        }
        else {
            self.phoneViewController!.onShowProfile()
        }
	}

	@objc func handleShowTimelineNotification() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.onTabletShowTimeline()
        }
        else {
            self.phoneViewController!.onShowTimeline()
        }
	}

	@objc func handleShowDiscoverNotification() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.onTabletShowDiscover()
        }
        else {
            self.phoneViewController!.onShowDiscover()
        }
	}

    @objc func handleShowBookmarksNotification() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.onTabletShowBookmarks()
        }
        else {
            self.phoneViewController!.onShowBookmarks()
        }
    }

	@objc func handleShowComposeNotification() {
		self.onNewPost()
	}

	@objc func handleShowSettingsNotification() {
		self.onSettings()
	}
	
	@objc func handleShowMentionsNotification() {
		if UIDevice.current.userInterfaceIdiom == .phone {
            self.phoneViewController?.onShowMentions()
		}
		else {
			self.onTabletShowMentions()
		}
	}

	@objc func onExpandSplitViewController() {
		if let splitViewController = self.splitViewController {

			NotificationCenter.default.post(name: .splitViewWillExpandNotification, object: nil)

			UIView.animate(withDuration: 0.15) {
				splitViewController.preferredDisplayMode = .allVisible
			}
		}
	}
	
	@objc func handleSplitViewWillCollapseNotification(_ notification : Notification) {
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "sidebar.left"), style: .plain, target: self, action: #selector(onExpandSplitViewController))
		self.navigationController?.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "sidebar.left"), style: .plain, target: self, action: #selector(onExpandSplitViewController))
	}

	@objc func handleSplitViewWillExpandNotification(_ notification : Notification) {
		self.navigationItem.leftBarButtonItem = nil
		self.navigationController?.navigationItem.leftBarButtonItem = nil
		
	}

    @available(iOS 14, *)
    func iOS14PhotoPicker() -> UIViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .any(of: [.images, .videos])
        configuration.selectionLimit = 0
        configuration.preferredAssetRepresentationMode = .automatic

        let pickerController = PHPickerViewController(configuration: configuration)
        pickerController.delegate = self
        return pickerController
    }

    func defaultPhotoPicker() -> UIViewController {
        let pickerController = UIImagePickerController()
        pickerController.modalPresentationCapturesStatusBarAppearance = true
        pickerController.delegate = self
        pickerController.allowsEditing = false
        pickerController.mediaTypes = ["public.image", "public.movie"]
        pickerController.sourceType = .savedPhotosAlbum
        return pickerController
    }

	@IBAction @objc func onNewPost() {
        if let _ = SnippetsUser.current() {

            var pickerController : UIViewController!

            if #available(iOS 14, *) {
                pickerController = iOS14PhotoPicker()
            }
            else {
                pickerController = defaultPhotoPicker()
            }

            self.present(pickerController, animated: true, completion: nil)
        }
	}

    @IBAction @objc func onUploads() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Uploads", bundle: nil)
        let uploadsViewController = storyBoard.instantiateViewController(withIdentifier: "UploadsViewController") as! UploadsViewController
        uploadsViewController.delegate = self

        let navigationController = UINavigationController(rootViewController: uploadsViewController)
        self.present(navigationController, animated: true, completion: nil)
    }

	
	@IBAction @objc func onSettings() {
		let storyBoard: UIStoryboard = UIStoryboard(name: "Settings", bundle: nil)
		let settingsViewController = storyBoard.instantiateViewController(withIdentifier: "SettingsViewController")
		
		let navigationController = UINavigationController(rootViewController: settingsViewController)
		self.present(navigationController, animated: true, completion: nil)
	}
	
	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	func activateContentViewController(_ viewController : ContentViewController) {
		
		self.navigationController?.popToRootViewController(animated: false)
		self.deactivateContentViewController(self.currentContentViewController)

        self.addChild(viewController)
        self.view.addSubview(viewController.view)
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.constrainAllSides(self.view)
        viewController.view.setNeedsLayout()

		self.currentContentViewController = viewController
		self.currentContentViewController?.prepareToDisplay()
	}
	
	func deactivateContentViewController(_ viewController : ContentViewController?) {
		
		if let previousViewController = viewController {
			previousViewController.removeFromParent()
			previousViewController.view.removeFromSuperview()
			viewController!.prepareToHide()
		}
	}
	
	func onTabletShowTimeline() {
		self.activateContentViewController(self.timelineViewController)
	}
	
	func onTabletShowDiscover() {
		self.activateContentViewController(self.discoverViewController)
	}

    func onTabletShowBookmarks() {
        self.activateContentViewController(self.bookmarksViewController)
    }

	func onTabletShowProfile() {
		self.activateContentViewController(self.profileViewController)
	}

	func onTabletShowMentions() {
		self.activateContentViewController(self.mentionsViewController)
	}
	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	func constructPhoneInterface() {
		let storyBoard: UIStoryboard = UIStoryboard(name: "Main-Phone", bundle: nil)
		
		if let phoneViewController = storyBoard.instantiateViewController(withIdentifier: "MainPhoneViewController") as? MainPhoneViewController{
			self.phoneViewController = phoneViewController
			phoneViewController.timelineViewController = self.timelineViewController
			phoneViewController.discoverViewController = self.discoverViewController
            phoneViewController.bookmarksViewController = self.bookmarksViewController
			phoneViewController.profileViewController = self.profileViewController
			phoneViewController.mentionsViewController = self.mentionsViewController

			self.addChild(phoneViewController)
			self.view.addSubview(phoneViewController.view)
			phoneViewController.view.bounds = self.view.bounds
		}
	}
	
	
}

/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

extension MainViewController : UploadsPickerControllerDelegate {

    func imagePickerController(_ picker: UploadsViewController, didFinishPickingMediaWithInfo info: [SunlitMedia]) {
        self.composeWithMedia(info, picker: picker)
    }

    func imagePickerControllerDidCancel(_ picker: UploadsViewController) {
    }

}

@available(iOS 14, *)
extension MainViewController : PHPickerViewControllerDelegate {

    @available(iOS 14, *)
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {

        var providers : [NSItemProvider] = []
        for result in results {
            providers.append(result.itemProvider)
        }

        let processor = ItemProviderProcessor { (media) in
            if media.count > 0 {
                self.composeWithMedia(media, picker: picker)
            }
            else {
                picker.dismiss(animated: true, completion: nil)
            }
        }

        processor.process(providers)
    }
}

extension MainViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func composeWithMedia(_ media : [SunlitMedia], picker : UIViewController) {

        let storyBoard: UIStoryboard = UIStoryboard(name: "Compose", bundle: nil)
        let postViewController = storyBoard.instantiateViewController(withIdentifier: "ComposeViewController") as! ComposeViewController
        postViewController.modalPresentationStyle = .fullScreen

        for object in media {
            postViewController.addMedia(object)
        }

        picker.dismiss(animated: true) {
            let navigationController = UINavigationController(rootViewController: postViewController)
            navigationController.modalPresentationStyle = .fullScreen
            self.present(navigationController, animated: true, completion: nil)
        }

    }

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
            self.composeWithMedia([media], picker: picker)
		}
		else {
			picker.dismiss(animated: true, completion: nil)
		}
	}
}



/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

extension MainViewController : UISplitViewControllerDelegate {
	func primaryViewController(forCollapsing splitViewController: UISplitViewController) -> UIViewController? {
		return nil
	}

	func primaryViewController(forExpanding splitViewController: UISplitViewController) -> UIViewController? {
		return nil
	}
	
	func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
		return true
	}
	
}

