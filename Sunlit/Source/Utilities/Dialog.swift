//
//  Dialogs.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/3/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import Snippets

class Dialog {
	
	init (_ viewController : UIViewController) {
		self.viewController = viewController
	}
	
	func information(_ string : String, completion: (()->Void)? = nil) {
		
		self.completion = completion
		
		// Make sure we aren't on a background thread...
		DispatchQueue.main.async {
			let alertController = UIAlertController(title: nil, message: string, preferredStyle: .alert)
			alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
				if let completion = self.completion {
					completion()
				}
			}))
			
			self.viewController.present(alertController, animated: true, completion: nil)
		}
	}
	
	func question(title : String?, question : String, accept : String, cancel : String, _ onAccept: @escaping (()->Void)) {
		let alertViewController = UIAlertController(title: title, message: question, preferredStyle: .alert)
		let acceptAction = UIAlertAction(title: accept, style: .default) { (action) in
			DispatchQueue.main.async {
				onAccept()
			}
		}

		let cancelAction = UIAlertAction(title: cancel, style: .cancel) { (action) in
		}
		
		alertViewController.addAction(cancelAction)
		alertViewController.addAction(acceptAction)

		self.viewController.present(alertViewController, animated: true, completion: completion)
	}
	
	func warning(title : String?, question : String, action : String, cancel : String, _ onAccept: @escaping (()->Void)) {
		let alertViewController = UIAlertController(title: title, message: question, preferredStyle: .alert)
		let acceptAction = UIAlertAction(title: action, style: .destructive) { (action) in
			DispatchQueue.main.async {
				onAccept()
			}
		}

		let cancelAction = UIAlertAction(title: cancel, style: .cancel) { (action) in
		}
		
		alertViewController.addAction(cancelAction)
		alertViewController.addAction(acceptAction)

		self.viewController.present(alertViewController, animated: true, completion: completion)
	}

	func selectBlog(completion: (()->Void)? = nil) {
		
		self.completion = completion
		
		Snippets.Microblog.fetchCurrentUserConfiguration { (error, configuration) in
			
			// Check for a media endpoint definition...
            let mediaEndPoint : String = configuration["media-endpoint"] as? String ?? ""
            let micropubEndPoint = Snippets.Configuration.timeline.micropubEndpoint
            let micropubToken = Snippets.Configuration.timeline.micropubToken
			
			DispatchQueue.main.async {

				if let destinations = configuration["destination"] as? [[String : Any]] {
					
                    for destination in destinations {
                        if let title = destination["name"] as? String,
                           let blogId = destination["uid"] as? String {
                            
                            let config = Snippets.Configuration.fromDictionary(destination)
                            config.micropubUid = blogId
                            config.micropubEndpoint = micropubEndPoint
                            config.micropubMediaEndpoint = mediaEndPoint
                            config.micropubToken = micropubToken
                        
                            let blogSettings = BlogSettings(title)
                            blogSettings.blogName = title
                            blogSettings.snippetsConfiguration = config
                            blogSettings.save()
                            
                            BlogSettings.addPublishedBlog(blogSettings)
                        }
                    }
                    
                    let blogList = BlogSettings.publishedBlogs()
					if blogList.count > 1 {
						self.selectBlogConfiguration(blogList)
						return
					}
				
					if let destination = destinations.first {
                        if let blogId = destination["uid"] as? String {
                            BlogSettings.setBlogForPublishing(BlogSettings(blogId))
                        }
					}
				}
			}
		}

	}
	
	private func selectBlogConfiguration(_ blogList : [BlogSettings]) {

		let actionSheet = UIAlertController(title: nil, message: "Please select which Micro.blog to use when publishing.", preferredStyle: .actionSheet)

		for blog in blogList {
            let action = UIAlertAction(title: blog.blogName, style: .default) { (action) in

                BlogSettings.setBlogForPublishing(blog)

                if let completion = self.completion {
                    completion()
                }
            }
            
            actionSheet.addAction(action)
		}
		
		if let popoverController = actionSheet.popoverPresentationController {
			popoverController.sourceView = self.viewController.view
			popoverController.sourceRect = CGRect(x: self.viewController.view.center.x, y: self.viewController.view.center.y, width: 0, height: 0)
			popoverController.permittedArrowDirections = [] 
		}
		
		self.viewController.present(actionSheet, animated: true) {
		}

	}
	
	private var viewController : UIViewController!
	private var completion : (()->Void)? = nil
}
