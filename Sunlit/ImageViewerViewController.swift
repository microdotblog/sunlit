//
//  ImageViewerViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/9/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
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
	
	var pathToImage = ""
	var post : SunlitPost!

    override func viewDidLoad() {
        super.viewDidLoad()

		self.setupNavigationBar()
		self.setupScrollView()
		self.setupGestures()
		self.setupPostInfo()
		
		self.navigationController?.setNavigationBarHidden(true, animated: true)
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		self.image.frame = self.scrollView.bounds
	}
	
	func setupNavigationBar() {
		//self.navigationItem.leftBarButtonItem = UIBarButtonItem.barButtonWithImage(named: "back_button", target: self, action: #selector(dismissViewController))
		//self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(onShare))
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
	}
	
	func setupPostInfo() {
		// Recreate the post with white text...
		self.post = SunlitPost.create(self.post, textColor: .white)
		
		self.postText.attributedText = self.post.text
		self.userHandle.text = "@" + self.post.owner.userHandle
		self.fullUserName.text = self.post.owner.fullName
		
		ImageCache.fetch(self.post.owner.pathToUserImage) { (image) in
			DispatchQueue.main.async {
				self.userAvatar.image = image
			}
		}

		ImageCache.fetch(self.pathToImage) { (image) in
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
			self.scrollView.zoomScale = 1.0
		}) { (complete) in
			
		}
		
	}
	
	@IBAction @objc func onShare() {
		
		if let image = ImageCache.prefetch(self.pathToImage) {
			let items : [Any] = [image]
			let activities : [UIActivity]? = nil
			let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: activities)
			self.present(activityViewController, animated: true, completion: nil)
		}
	}
	
	@IBAction @objc func dismissViewController() {
		self.navigationController?.popViewController(animated: true)
	}
	
	@IBAction @objc func onViewInSafari() {
		let url = URL(string: self.post.path)!
		let safariViewController = SFSafariViewController(url: url)
		self.navigationController?.pushViewController(safariViewController, animated: true)
	}
	
	func viewForZooming(in scrollView: UIScrollView) -> UIView? {
		return self.image
	}
}

