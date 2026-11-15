//
//  ExternalBlogConfigurationViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 6/10/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import Snippets
import UUSwiftNetworking
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
    var publishingPurpose: BlogSettings.PublishingPurpose = .posts

	
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
		let accountGeneration = Settings.accountGeneration

		let request = SnippetsRPCDiscovery(url: self.wordpressRsdPath)
		request.discoverEndpointWithCompletion { (xmlrpcEndpoint, blogId) in
			guard accountGeneration == Settings.accountGeneration else {
				return
			}
			guard let xmlrpcEndpoint = xmlrpcEndpoint, let blogId = blogId else {
				DispatchQueue.main.async {
					guard accountGeneration == Settings.accountGeneration else { return }
					self.busyIndicator.isHidden = true
					Dialog(self).information("Unable to find the blog's publishing endpoint. Check the address and your internet connection.")
				}
				return
			}

			let username = self.usernameText
			let password = self.passwordText
			let methodName = "blogger.getUsersBlogs"
			let appKey = ""
			let params : [String] = [appKey, username, password]
			let is_wordpress = xmlrpcEndpoint.contains("/xmlrpc.php")
			
            var identity = Snippets.Configuration.xmlRpcConfiguration(username: username, password: password, endpoint: xmlrpcEndpoint, blogId: blogId)
            if is_wordpress {
                identity = Snippets.Configuration.wordpressConfiguration(username: username, password: password, endpoint: xmlrpcEndpoint, blogId: blogId)
            }
            let request = Snippets.XMLRPC.Request(identity: identity, method: methodName)
			
			_ = Snippets.XMLRPC.execute(request: request, params: params) { (error, responseData) in
				guard accountGeneration == Settings.accountGeneration else {
					return
				}
				
				if let data = responseData {
					SnippetsXMLRPCParser.parsedResponseFromData(data) { (responseFault, responseParams) in
						DispatchQueue.main.async {
							guard accountGeneration == Settings.accountGeneration else {
								return
							}

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
                                self.publishingPurpose.select(settings)

                                Dialog(self).information("Successfully configured for publishing!") {
									self.navigationController?.popViewController(animated: true)
								}
							}
						}
					}
				}
				else {
					DispatchQueue.main.async {
						guard accountGeneration == Settings.accountGeneration else { return }
						self.busyIndicator.isHidden = true
						Dialog(self).information(error?.localizedDescription ?? "Unable to connect to the blog's publishing endpoint.")
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
			
			if let me = MicropubClient.endpointURL(path),
               let authString = authStrings.first, let authURL = MicropubClient.endpointURL(authString, relativeTo: me),
               let tokenString = tokenStrings.first, let tokenURL = MicropubClient.endpointURL(tokenString, relativeTo: me),
               let micropubString = links.first, let micropubURL = MicropubClient.endpointURL(micropubString, relativeTo: me) {

				let micropubState = UUID().uuidString
                let verifier = MicropubClient.makeCodeVerifier()
                let authEndpoint = MicropubClient.authorizationURL(endpoint: authURL, me: me, state: micropubState, verifier: verifier)

                let blogName : String = me.host ?? ""
                let settings = BlogSettings(blogName)
                settings.tokenEndpoint = tokenURL.absoluteString
                settings.stateKey = micropubState
                settings.authEndpoint = authEndpoint.absoluteString
                settings.blogPublishingAddress = micropubURL.absoluteString

                settings.save()

                MicropubState.save(state: micropubState, name: blogName, purpose: self.publishingPurpose, verifier: verifier, me: me.absoluteString)
                guard MicropubState.codeVerifier(from: micropubState) == verifier else {
                    MicropubState.remove(state: micropubState)
                    DispatchQueue.main.async {
                        self.busyIndicator.isHidden = true
                        Dialog(self).information("Unable to save the sign-in details. Please try again.")
                    }
                    return
                }
            
				DispatchQueue.main.async {
					UIApplication.shared.open(authEndpoint)
					self.navigationController?.popViewController(animated: true)
				}
				
			}
		}
	}
	
	func interrogateURL() {
		
		// Sanity checking...
		guard let address = self.blogAddress.text, address.contains("."),
              let enteredURL = MicropubClient.blogURL(address) else {
			Dialog(self).information("Please enter a valid URL")
			return
		}

		self.externalServerPath = enteredURL.absoluteString
		let accountGeneration = Settings.accountGeneration
		
		let request = UUHttpRequest(url: enteredURL.absoluteString)
		//request.processMimeTypes = false
		self.busyIndicator.isHidden = false

		_ = UUHttpSession.executeRequest(request) { (response) in
			guard accountGeneration == Settings.accountGeneration else {
				return
			}

			if let rawResponse = response.rawResponse {
                let discoveredURL = MicropubClient.discoveryURL(entered: enteredURL, responseURL: response.httpResponse?.url)

				let links = SnippetsXMLLinkParser.parse(rawResponse, relValue: "EditURI")
				if let link = links.first {
					
					self.wordpressRsdPath = link
					DispatchQueue.main.async {
						guard accountGeneration == Settings.accountGeneration else {
							return
						}

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
					self.interrogateMicropubURL(path: discoveredURL.absoluteString, rawResponse)
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
