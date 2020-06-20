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

    override func viewDidLoad() {
        super.viewDidLoad()

		self.setupNotifications()
		self.setupNavigationBar()
		self.setupSnippets()
		
		if UIDevice.current.userInterfaceIdiom == .pad {
			self.constructTabletInterface()
		}
		else {
			self.constructPhoneInterface()
		}
	}
		
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	func setupSnippets() {
		let blogIdentifier = PublishingConfiguration.current.getBlogIdentifier()
		if let token = Settings.snippetsToken() {
			Snippets.shared.configure(permanentToken: token, blogUid: blogIdentifier)
		}
	}


	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	func setupNavigationBar() {
		//let hamburgerMenuButton = UIBarButtonItem(image: UIImage(named: "hamburger"), style: .plain, target: self, action: #selector(onToggleHamburgerMenu))
		let postButton = UIBarButtonItem(image: UIImage(named: "post"), style: .plain, target: self, action: #selector(onNewPost))
		let settingsButton = UIBarButtonItem(image: UIImage(named: "settings_icon"), style: .plain, target: self, action: #selector(onSettings))
		self.navigationItem.title = "Timeline"
		self.navigationItem.leftBarButtonItem = settingsButton
		self.navigationItem.rightBarButtonItem = postButton
	}

	
	func setupNotifications() {
		NotificationCenter.default.addObserver(self, selector: #selector(handleOpenURLNotification(_:)), name: NSNotification.Name("OpenURLNotification"), object: nil)
	}

	@objc func handleOpenURLNotification(_ notification : Notification) {
		if let path = notification.object as? String,
			let url = URL(string: path){
			
			let safariViewController = SFSafariViewController(url: url)
			self.present(safariViewController, animated: true, completion: nil)
		}
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
	

	
	@objc func onSettings() {
		let storyBoard: UIStoryboard = UIStoryboard(name: "Settings", bundle: nil)
		let settingsViewController = storyBoard.instantiateViewController(withIdentifier: "SettingsViewController")
		self.navigationController?.pushViewController(settingsViewController, animated: true)
		//let navigationController = UINavigationController(rootViewController: newPostViewController)
		//self.present(navigationController, animated: true, completion: nil)
	}

	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	func constructTabletInterface() {
		let storyBoard: UIStoryboard = UIStoryboard(name: "Main-Tablet", bundle: nil)
		if let viewController = storyBoard.instantiateInitialViewController() {
			self.navigationController?.setViewControllers([viewController], animated: false)
		}
	}
	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	func constructPhoneInterface() {
		let storyBoard: UIStoryboard = UIStoryboard(name: "Main-Phone", bundle: nil)
		let phoneViewController = storyBoard.instantiateViewController(withIdentifier: "MainPhoneViewController")
		self.addChild(phoneViewController)
		self.view.addSubview(phoneViewController.view)
		phoneViewController.view.bounds = self.view.bounds
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


