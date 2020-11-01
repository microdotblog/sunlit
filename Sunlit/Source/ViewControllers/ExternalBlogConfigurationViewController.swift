//
//  ExternalBlogConfigurationViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 6/10/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import Snippets
import UUSwift
import SafariServices

class ExternalBlogConfigurationViewController: UIViewController {

	@IBOutlet var blogAddress : UITextField!
	@IBOutlet var blogAddressContainer : UIView!
	
	@IBOutlet var username : UITextField!
	@IBOutlet var password : UITextField!
	@IBOutlet var instructions : UILabel!
	@IBOutlet var accountEntryView : UIView!
	@IBOutlet var busyIndicator : UIActivityIndicatorView!
	
	var wordpressRsdPath = ""
	var usernameText = ""
	var passwordText = ""
    var externalServerPath = ""

	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

    override func viewDidLoad() {
        super.viewDidLoad()

		self.setupNavigation()
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		self.blogAddress.becomeFirstResponder()
	}

	func setupNavigation() {
		self.navigationItem.title = "External Blog"
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(back))
	}
		
	@IBAction func back() {
		self.navigationController?.popViewController(animated: true)
	}
		
	func interrogateWordPressURL() {
		
		self.busyIndicator.isHidden = false

		let request = SnippetsRPCDiscovery(url: self.wordpressRsdPath)
		request.discoverEndpointWithCompletion { (xmlrpcEndpoint, blogId) in
			let username = self.usernameText
			let password = self.passwordText
			let methodName = "blogger.getUsersBlogs"
			let appKey = ""
			let params : [String] = [appKey, username, password]
			var is_wordpress = false
			
			if let endpoint = xmlrpcEndpoint {
				is_wordpress = endpoint.contains("/xmlrpc.php")
			}
			
            var identity = Snippets.Configuration.xmlRpcConfiguration(username: username, password: password, endpoint: xmlrpcEndpoint!, blogId: blogId!)
            if is_wordpress {
                identity = Snippets.Configuration.wordpressConfiguration(username: username, password: password, endpoint: xmlrpcEndpoint!, blogId: blogId!)
            }
            //SnippetsXMLRPCIdentity.create(username: username, password: password, endpoint: xmlrpcEndpoint!, blogId: blogId!, wordPress: is_wordpress)
            let request = Snippets.XMLRPC.Request(identity: identity, method: methodName)
			
			_ = Snippets.XMLRPC.execute(request: request, params: params) { (error, responseData) in
				
				if let data = responseData {
					SnippetsXMLRPCParser.parsedResponseFromData(data) { (responseFault, responseParams) in
						DispatchQueue.main.async {
							self.busyIndicator.isHidden = true

							if let fault = responseFault {
								let errorString = fault["faultString"] as! String
								let errorCode = fault["faultCode"] as! NSNumber
								let formattedErrorString = errorString + " (error: " + errorCode.stringValue + ")"
								Dialog(self).information(formattedErrorString)
							}
							else {
								
								// If we have successfully configured the blog, we can tell settings to use it...
                                //let url = URL(string: self.blogAddress.text!)!
                                var name = self.blogAddress.text!
                                name = name.replaceAll(of: "http://", with: "")
                                name = name.replaceAll(of: "https://", with: "")
                                let settings = BlogSettings(name)
                                settings.snippetsConfiguration = identity
                                BlogSettings.addPublishedBlog(settings)
                                BlogSettings.setBlogForPublishing(settings)

                                Dialog(self).information("Successfully configured for publishing!") {
									self.navigationController?.popViewController(animated: true)
								}
							}
						}
					}
				}
			}
		}
	}
	
	func interrogateMicropubURL(path : String, _ data : Data) {
		let links = SnippetsXMLLinkParser.parse(data, relValue: "micropub")
		if links.count > 0 {
			let authStrings = SnippetsXMLLinkParser.parse(data, relValue: "authorization_endpoint")
			let tokenStrings = SnippetsXMLLinkParser.parse(data, relValue: "token_endpoint")
			
			if var authEndpoint = authStrings.first,
               let tokenEndpoint = tokenStrings.first,
               let micropubEndpoint = links.first {

				let micropubState = UUID().uuidString
				
				if !authEndpoint.contains("?") {
					authEndpoint = authEndpoint + "?"
				}
				else {
					authEndpoint = authEndpoint + "&"
				}
				
				authEndpoint = authEndpoint + "me=" + path.uuUrlEncoded()
				authEndpoint = authEndpoint + "&redirect_uri=" + String("https://sunlit.io/micropub/redirect").uuUrlEncoded()
				authEndpoint = authEndpoint + "&client_id=" + (String("https://sunlit.io/").uuUrlEncoded())
				authEndpoint = authEndpoint + "&state=" + micropubState
				authEndpoint = authEndpoint + "&scope=create"
				authEndpoint = authEndpoint + "&response_type=code"

                let blogName : String = URL(string:self.externalServerPath)?.host ?? ""
                let settings = BlogSettings(blogName)
                settings.tokenEndpoint = tokenEndpoint
                settings.stateKey = micropubState
                settings.authEndpoint = authEndpoint
                settings.blogPublishingAddress = micropubEndpoint

                settings.save()

                MicropubState.save(state: micropubState, name: blogName)
            
				DispatchQueue.main.async {
					UIApplication.shared.open(URL(string: authEndpoint)!)
					self.navigationController?.popViewController(animated: true)
				}
				
			}
		}
	}
	
	func interrogateURL() {
		
		// Sanity checking...
		var path = self.blogAddress.text
		if !(path?.contains(".") ?? false) {
			Dialog(self).information("Please enter a valid URL")
			return
		}

		// Make sure we have a valid, qualified domain
		path = path!.uuTrimWhitespace()
		if !path!.contains("http:") && !path!.contains("https:") {
			path = "http://" + path!
		}

        self.externalServerPath = path!
		let fullURL = path!
		
		let request = UUHttpRequest(url: path!)
		request.processMimeTypes = false
		self.busyIndicator.isHidden = false

		_ = UUHttpSession.executeRequest(request) { (response) in
			if let rawResponse = response.rawResponse {
				// uncomment to force Micropub testing
//				self.interrogateMicropubURL(path: fullURL, rawResponse)
//				return

				let links = SnippetsXMLLinkParser.parse(rawResponse, relValue: "EditURI")
				if let link = links.first {
					
					self.wordpressRsdPath = link
					DispatchQueue.main.async {
						self.busyIndicator.isHidden = true
						self.accountEntryView.isHidden = false
						self.accountEntryView.alpha = 0.0

						UIView.animate(withDuration: 0.15) {
							self.accountEntryView.alpha = 1.0
							self.blogAddressContainer.alpha = 0.0
						}
					}
					return
				}
				else {
					self.interrogateMicropubURL(path: fullURL, rawResponse)
					return
				}
			}
			
			Dialog(self).information("Error discovering settings. Unable to find EditURI or micropub link data.")
		}
	}
}

extension ExternalBlogConfigurationViewController : UITextFieldDelegate {
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		
		if textField == self.blogAddress {
			self.interrogateURL()
            textField.resignFirstResponder()
		}
		else if textField == self.username || textField == self.password {
			if let username = self.username.text,
				let password = self.password.text {
				
                if username.count > 0 && password.count > 0 {
					self.usernameText = username
					self.passwordText = password

					self.interrogateWordPressURL()
                    textField.resignFirstResponder()
				}
                else if username.count == 0 {
                    self.username.becomeFirstResponder()
                }
                else {
                    self.password.becomeFirstResponder()
                }
			}
		}
		return false
	}
}

extension ExternalBlogConfigurationViewController : SFSafariViewControllerDelegate {
	
	func safariViewController(_ controller: SFSafariViewController, initialLoadDidRedirectTo URL: URL) {
		print("WORK TO DO STILL!!!")
	}
}
