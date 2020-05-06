//
//  FeedViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/3/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class FeedViewController: UIViewController, UITableViewDataSource {

	@IBOutlet var tableView : UITableView!
	
	var tableViewData : [[String : Any]] = []
	
    override func viewDidLoad() {
        super.viewDidLoad()

		NotificationCenter.default.addObserver(self, selector: #selector(handleTemporaryTokenReceivedNotification(_:)), name: NSNotification.Name("TemporaryTokenReceivedNotification"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleImageLoadedNotification(_:)), name: NSNotification.Name("Image Loaded"), object: nil)
		self.configureTableView()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		self.setupSnippets()
	}

	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */
	func configureTableView() {
		
	}

	func attachTextStyling(_ string : String, font : UIFont = UIFont.systemFont(ofSize: 14.0), color : UIColor = UIColor.black) -> String {

		let cssString = "<style>" +
		"html *" +
		"{" +
		"font-size: \(font.pointSize)pt !important;" +
		"color: #\(color.uuHexString) !important;" +
		"font-family: \(font.familyName), Helvetica !important;" +
		"}</style>"

		return cssString + string
	}
	
	func createDictionaryFromPost(_ snippetPost : SnippetsPost) -> [String : Any] {
				
		let html = self.attachTextStyling(snippetPost.htmlText)
		
		let post = HTMLParser.parse(html)
		let owner = snippetPost.owner
		
		var dictionary : [String : Any] = [:]
		dictionary["owner"] = owner
		dictionary["post"] = post
		dictionary["html"] = html
		
		return dictionary
	}
	
	func refreshTableView(_ entries : [SnippetsPost]) {
		
		var posts : [[String : Any]] = []
		
		for entry in entries {
			let post = self.createDictionaryFromPost(entry)
			posts.append(post)
		}
		
		self.tableViewData = posts
		
		
		self.tableView.reloadData()
	}
	
	@objc func handleImageLoadedNotification(_ notification : Notification) {
		if let index = notification.object as? Int {
			self.tableView.reloadRows(at: [ IndexPath(row: index, section: 0)], with: .fade)
		}
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.tableViewData.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		let cell = tableView.dequeueReusableCell(withIdentifier: "FeedTableViewCell", for: indexPath) as! FeedTableViewCell
		let dictionary = self.tableViewData[indexPath.row]
		cell.setupFromDictionary(indexPath.row, dictionary)
		
		return cell
	}
	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */
	func configureCollectionView() {
		
	}
	
	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	func loadTimeline() {
		
		Snippets.shared.fetchCurrentUserPhotoTimeline { (error, postObjects : [SnippetsPost]) in
			DispatchQueue.main.async {
				self.refreshTableView(postObjects)
			}
		}
		
	}
	
	
	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	func setupSnippets() {

		if let token = Settings.permanentToken() {
			Snippets.shared.configure(permanentToken: token, blogUid: nil)
			
			self.loadTimeline()
		}
		else {
			self.showLoginDialog()
		}
	}
	
	func showLoginDialog() {
		let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let loginViewController = storyboard.instantiateViewController(identifier: "LoginViewController")

        show(loginViewController, sender: self)
	}

	@objc func handleTemporaryTokenReceivedNotification(_ notification : Notification)
	{
		if let temporaryToken = notification.object as? String
		{
			Snippets.shared.requestPermanentTokenFromTemporaryToken(token: temporaryToken) { (error, token) in
				if let permanentToken = token
				{
					Settings.savePermanentToken(permanentToken)
					Snippets.shared.configure(permanentToken: permanentToken, blogUid: nil)
					
					Dialog.information("You have successfully logged in.", self)
					
					self.loadTimeline()
				}
			}
		}
	}


}

class FeedTableViewCell : UITableViewCell {
	
	//@IBOutlet var collectionView : UICollectionView!
	@IBOutlet var postImage : UIImageView!
	@IBOutlet var textView : UITextView!
	@IBOutlet var dateLabel : UILabel!
	@IBOutlet var userAvatar : UIImageView!
	@IBOutlet var userName : UILabel!
	@IBOutlet var userHandle : UILabel!
	@IBOutlet var heightConstraint : NSLayoutConstraint!
	
	func setupFromDictionary(_ index: Int, _ dictionary : [String : Any]) {
		
		self.userAvatar.clipsToBounds = true
		self.userAvatar.layer.cornerRadius = self.userAvatar.bounds.size.height / 2.0
		
		let owner = dictionary["owner"] as! SnippetsUser
		let post = dictionary["post"] as! Post
		
		self.textView.attributedText = post.text
		self.userHandle.text = "@" + owner.userHandle
		self.userName.text = owner.fullName
		
		let width : CGFloat = UIApplication.shared.windows.first!.bounds.size.width
		let maxHeight = UIApplication.shared.windows.first!.bounds.size.height - 100
		var height : CGFloat = width * CGFloat(post.aspectRatio)
		if height > maxHeight {
			height = maxHeight
		}
		self.heightConstraint.constant = height
		
		let imageSource = post.images[0]
		if let image = ImageCache.prefetch(imageSource) {
			self.postImage.image = image
		}
		else {
			ImageCache.fetch(imageSource) { (image) in
				if let _ = image {
					NotificationCenter.default.post(name: NSNotification.Name(rawValue: "Image Loaded"), object: index)
				}
			}
		}
		
		let avatarSource = owner.pathToUserImage
		if let avatar = ImageCache.prefetch(avatarSource) {
			self.userAvatar.image = avatar
		}
		else {
			ImageCache.fetch(avatarSource) { (image) in
				if let _ = image {
					NotificationCenter.default.post(name: NSNotification.Name(rawValue: "Image Loaded"), object: index)
				}
			}
		}
	}
}

class FeedCollectionViewCell : UICollectionViewCell {
	
}


