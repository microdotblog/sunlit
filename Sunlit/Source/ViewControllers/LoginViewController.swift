//
//  LoginViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/3/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import Snippets

class LoginViewController: UIViewController, UITextFieldDelegate {

	@IBOutlet var emailField : UITextField!
	@IBOutlet var spinner : UIActivityIndicatorView!

	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

    override func viewDidLoad() {
        super.viewDidLoad()
		
		self.navigationItem.title = "Sign In"
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(close))

		self.emailField.becomeFirstResponder()
    }
    
	@IBAction func close() {
		self.dismiss(animated: true)
	}

	func attemptLogin(_ emailAddress : String?) {
		
		if let email = emailAddress {
			self.lockUserInterface()

			if email.uuIsValidEmail() {
				Snippets.Microblog.requestUserLoginEmail(email: email, appName: "Sunlit", redirect: "https://sunlit.io/microblog/redirect/")
				{ error in
					self.unlockUserInterface()

					if let err = error {
						Dialog(self).information(err.localizedDescription)
					}
					else {
						Dialog(self).information("Check your email on this device and tap the \"Open with Sunlit\" button.", completion: {
							self.dismiss(animated: true, completion: nil)
						})
					}
				}
			}
			else {
                // TODO: Need to verify this code path with respect to the micropub path
				Snippets.Microblog.requestPermanentTokenFromTemporaryToken(token: email) { error, token in
					self.unlockUserInterface()
					if let err = error {
						Dialog(self).information(err.localizedDescription)
					}
					else if token?.count == 0 {
						Dialog(self).information("The token was not valid.")
					}
					else {
						NotificationCenter.default.post(name: .temporaryTokenReceivedNotification, object: token)
					}
				}
			}
		}
	}

	func textFieldShouldReturn(_ textField: UITextField) -> Bool {

		if let text = textField.text {
			let email = text.uuTrimWhitespace()
			self.attemptLogin(email)
		}
		
		return false
	}
	
	func lockUserInterface() {
		DispatchQueue.main.async {
			self.emailField.resignFirstResponder()
			self.emailField.isEnabled = false
			self.spinner.isHidden = false
			self.spinner.startAnimating()
		}
	}

	func unlockUserInterface() {
		DispatchQueue.main.async {
			self.emailField.isEnabled = true
			self.spinner.isHidden = true
		}
	}

}

