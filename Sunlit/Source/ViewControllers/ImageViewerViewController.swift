//
//  ImageViewerViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/9/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import Snippets
import SafariServices

class ImageViewerViewController: UIViewController, UIScrollViewDelegate {

	@IBOutlet var image : UIImageView!
	@IBOutlet var scrollView : UIScrollView!
	@IBOutlet var topInfoView : UIView!
	@IBOutlet var bottomInfoView: UIView!
	@IBOutlet var userAvatar : UIImageView!
	@IBOutlet var fullUserName : UILabel!
	@IBOutlet var userHandle : UILabel!
	@IBOutlet var postText : UITextView!
    @IBOutlet var deleteButton : UIButton!
	
	var pathToImage = ""
	var post : SunlitPost!

	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

    override func viewDidLoad() {
        super.viewDidLoad()

		self.setupNavigationBar()
		self.setupScrollView()
		self.setupGestures()
		self.setupPostInfo()
        
        self.deleteButton.isHidden = self.post.owner.userName != SnippetsUser.current()?.userName
		
		self.navigationController?.setNavigationBarHidden(true, animated: true)
	}

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

		// This is needed to "lock" the image into place so it won't bounce-scroll when it initially appears
        self.scrollView.zoomScale = 1.0
    }
    
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
//		self.image.frame = self.scrollView.bounds
	}
	
	func setupNavigationBar() {
		self.navigationItem.rightBarButtonItem?.tintColor = .black
	}
	
	func setupScrollView() {
		self.scrollView.contentSize = self.image.frame.size
		self.image.frame = self.scrollView.bounds
	}
	
	func setupGestures() {
		let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(onDoubleTap))
		doubleTapGesture.numberOfTapsRequired = 2
		self.scrollView.addGestureRecognizer(doubleTapGesture)
		
		let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(onSingleTap))
		singleTapGesture.require(toFail: doubleTapGesture)
		self.scrollView.addGestureRecognizer(singleTapGesture)
		
		let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(dismissViewController))
		swipeGesture.require(toFail: singleTapGesture)
		swipeGesture.require(toFail: doubleTapGesture)
		self.scrollView.addGestureRecognizer(swipeGesture)
        
        let userProfileGesture = UITapGestureRecognizer(target: self, action: #selector(onViewUserProfile))
        self.userAvatar.addGestureRecognizer(userProfileGesture)
        self.userAvatar.isUserInteractionEnabled = true
	}
	
	func setupPostInfo() {
		// Recreate the post with white text...
		self.post = SunlitPost.create(self.post, textColor: .white)
		
		self.postText.attributedText = self.post.attributedText
		self.userHandle.text = "@" + self.post.owner.userName
		self.fullUserName.text = self.post.owner.fullName
		
		ImageCache.fetch(self, self.post.owner.avatarURL) { (image) in
			DispatchQueue.main.async {
				self.userAvatar.image = image
			}
		}

		ImageCache.fetch(self, self.pathToImage) { (image) in
			DispatchQueue.main.async {
				self.image.image = image
			}
		}
		
		self.userAvatar.layer.cornerRadius = (self.userAvatar.bounds.size.height / 2.0) - 1.0
	}
	
	@objc func onDoubleTap() {
		if self.scrollView.zoomScale > 1.0 {
			UIView.animate(withDuration: 0.15) {
				self.scrollView.zoomScale = 1.0
			}
		}
		else {
			UIView.animate(withDuration: 0.15) {
				self.scrollView.zoomScale = self.scrollView.maximumZoomScale
			}
		}
	}
	
	@objc func onSingleTap() {
		var alpha : CGFloat = 0.0
		if self.topInfoView.alpha == 0.0 {
			alpha = 1.0
		}

		UIView.animate(withDuration: 0.15, delay: 0.35, options: .curveLinear, animations: {
			self.topInfoView.alpha = alpha
			self.bottomInfoView.alpha = alpha
//			self.scrollView.zoomScale = 1.0
		}) { (complete) in
			
		}
	}
    
    @objc func onViewUserProfile() {
        
        // They don't need to see their own profile...
        if let current = SnippetsUser.current() {
            if current.userName == self.post.owner.userName {
                return
            }
        }
        
        self.dismiss(animated: true) {
            NotificationCenter.default.post(name: .viewUserProfileNotification, object: self.post.owner)
        }
    }
    
    @IBAction func onDelete() {
        Dialog(self).warning(title: nil, question: "Are you sure you want to delete this post? It cannot be undone.", action: "Delete", cancel: "Cancel") {
            _ = Snippets.shared.deletePost(post: self.post) { (error) in
                DispatchQueue.main.async {
                    if let err = error {
                        Dialog(self).information("There was an error trying to delete this post: " + err.localizedDescription)
                    }
                    else {
                        self.dismissViewController()
                    }
                }
            }
        }
    }
	
	@IBAction @objc func onShare() {
		let url = URL(string: self.post.path)!
		let items : [Any] = [url]
		let activities : [UIActivity]? = nil
		let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: activities)
		self.present(activityViewController, animated: true, completion: nil)
	}

	@IBAction @objc func onConversation() {
		self.dismiss(animated: true) {
			NotificationCenter.default.post(name: .viewConversationNotification, object: self.post)
		}
	}

	@IBAction @objc func dismissViewController() {
		self.dismiss(animated: true, completion: nil)
	}
	
	@IBAction @objc func onViewInSafari() {
		let url = URL(string: self.post.path)!
		let safariViewController = SFSafariViewController(url: url)
		self.present(safariViewController, animated: true, completion: nil)
	}
	
	func viewForZooming(in scrollView: UIScrollView) -> UIView? {
		return self.image
	}
}

