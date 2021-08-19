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
    @IBOutlet var previousButton : UIButton!
    @IBOutlet var nextButton : UIButton!
	@IBOutlet var bookmarkButton : UIButton!
	
	var pathToImage = ""
	var post : SunlitPost!
    var swipeNextGesture = UISwipeGestureRecognizer(target: self, action: #selector(onNextButton))
    var swipePreviousGesture = UISwipeGestureRecognizer(target: self, action: #selector(onPreviousButton))

	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

    override func viewDidLoad() {
        super.viewDidLoad()

		self.setupNavigationBar()
		self.setupScrollView()
		self.setupGestures()
		self.setupPostInfo()
        self.setupImage()
        self.updateNavigationButtons()
        
        self.deleteButton.isHidden = self.post.owner.userName != SnippetsUser.current()?.userName
		
		self.navigationController?.setNavigationBarHidden(true, animated: true)
	}

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

		// This is needed to "lock" the image into place so it won't bounce-scroll when it initially appears
        self.scrollView.zoomScale = 1.0

		if let bookmarkButton = self.bookmarkButton {
			bookmarkButton.isSelected = self.post.isBookmark
		}
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
        self.swipeNextGesture.direction = .right
        self.swipePreviousGesture.direction = .left

		let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(onDoubleTap))
		doubleTapGesture.numberOfTapsRequired = 2
		self.scrollView.addGestureRecognizer(doubleTapGesture)
		
		let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(onSingleTap))
		singleTapGesture.require(toFail: doubleTapGesture)
		self.scrollView.addGestureRecognizer(singleTapGesture)
		
        let userProfileGesture = UITapGestureRecognizer(target: self, action: #selector(onViewUserProfile))
        self.userAvatar.addGestureRecognizer(userProfileGesture)
        self.userAvatar.isUserInteractionEnabled = true

        self.scrollView.addGestureRecognizer(self.swipeNextGesture)
        self.scrollView.addGestureRecognizer(self.swipePreviousGesture)
	}

    func indexOfCurrentPath() -> Int {
        var index = 0
        for image in self.post.images {
            if self.pathToImage == image {
                return index
            }

            index = index + 1
        }

        return index
    }

    func updateNavigationButtons() {
        let currentIndex = self.indexOfCurrentPath()

        self.previousButton.isHidden = false
        self.nextButton.isHidden = false

        if currentIndex == 0 {
            self.previousButton.isHidden = true
        }
        if currentIndex >= (self.post.images.count - 1) {
            self.nextButton.isHidden = true
        }

        self.updateSwipeGestures()
    }

    func setupImage() {
        ImageCache.fetch(self.pathToImage) { (image) in
            DispatchQueue.main.async {
                self.image.image = image
            }
        }
    }

	func setupPostInfo() {
		// Recreate the post with white text...
		self.post = SunlitPost.create(self.post, textColor: .white)
		
		self.postText.attributedText = self.post.attributedText
		self.userHandle.text = "@" + self.post.owner.userName
		self.fullUserName.text = self.post.owner.fullName
		
		ImageCache.fetch(self.post.owner.avatarURL) { (image) in
			DispatchQueue.main.async {
				self.userAvatar.image = image
			}
		}

		self.userAvatar.layer.cornerRadius = (self.userAvatar.bounds.size.height / 2.0) - 1.0
	}
	
	@objc func onDoubleTap() {
		if self.scrollView.zoomScale > 1.0 {
			UIView.animate(withDuration: 0.15) {
				self.scrollView.zoomScale = 1.0

                if self.topInfoView.alpha > 0.0 {
                    self.nextButton.alpha = 0.6
                    self.previousButton.alpha = 0.6
                }
                
                self.updateSwipeGestures()
			}
		}
		else {
			UIView.animate(withDuration: 0.15) {
                self.nextButton.alpha = 0.0
                self.previousButton.alpha = 0.0
                self.updateSwipeGestures()

				self.scrollView.zoomScale = self.scrollView.maximumZoomScale
			}
		}
	}
	
	@objc func onSingleTap() {
		var alpha : CGFloat = 0.0
        var buttonAlpha : CGFloat = 0.0

        self.swipeNextGesture.isEnabled = false
        self.swipePreviousGesture.isEnabled = false

		if self.topInfoView.alpha == 0.0 {
			alpha = 1.0
            buttonAlpha = 0.6
		}

		UIView.animate(withDuration: 0.15, delay: 0.35, options: .curveLinear, animations: {
			self.topInfoView.alpha = alpha
			self.bottomInfoView.alpha = alpha
            self.nextButton.alpha = buttonAlpha
            self.previousButton.alpha = buttonAlpha

//			self.scrollView.zoomScale = 1.0
		}) { (complete) in
            self.updateSwipeGestures()
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

        // Make sure that this is set before trying to delete...
        Snippets.Configuration.publishing = BlogSettings.blogForPublishing().snippetsConfiguration!

        Dialog(self).warning(title: nil, question: "Are you sure you want to delete this post? It cannot be undone.", action: "Delete", cancel: "Cancel") {
            _ = Snippets.shared.delete(post: self.post) { (error) in
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

    @IBAction func onNextButton() {
        let index = self.indexOfCurrentPath() + 1
        self.pathToImage = self.post.images[index]

        self.setupImage()
        self.updateNavigationButtons()
    }

    @IBAction func onPreviousButton() {
        let index = self.indexOfCurrentPath() - 1
        self.pathToImage = self.post.images[index]

        self.setupImage()
        self.updateNavigationButtons()
    }

	@IBAction func onBookmark() {
		if !self.post.isBookmark {
			if let bookmarkButton = self.bookmarkButton {
				bookmarkButton.isSelected = true
			}
			Snippets.Microblog.addBookmark(post: self.post) { (error) in
				if error == nil {
					self.post.isBookmark = true
				}

				if let bookmarkButton = self.bookmarkButton {
					bookmarkButton.isSelected = self.post.isBookmark
				}
			}
		}
		else {
			if let bookmarkButton = self.bookmarkButton {
				bookmarkButton.isSelected = false
			}

			Snippets.Microblog.removeBookmark(post: self.post) { (error) in
				if error == nil {
					self.post.isBookmark = false
				}

				if let bookmarkButton = self.bookmarkButton {
					bookmarkButton.isSelected = self.post.isBookmark
				}
			}
		}

		if let bookmarkButton = self.bookmarkButton {
			bookmarkButton.isSelected = !bookmarkButton.isSelected
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

    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        self.nextButton.alpha = 0.0
        self.previousButton.alpha = 0.0
        self.swipeNextGesture.isEnabled = false
        self.swipePreviousGesture.isEnabled = false
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        if scale == 1.0 && self.topInfoView.alpha > 0.0 {
            self.nextButton.alpha = 0.6
            self.previousButton.alpha = 0.6
            self.updateSwipeGestures()
        }
    }

    func updateSwipeGestures() {
        self.swipeNextGesture.isEnabled = !self.nextButton.isHidden && self.nextButton.alpha > 0.0
        self.swipePreviousGesture.isEnabled = !self.previousButton.isHidden && self.previousButton.alpha > 0.0
    }
}

