//
//  AltTextController.swift
//  Sunlit
//
//  Created by Manton Reece on 8/8/21.
//  Copyright © 2021 Micro.blog, LLC. All rights reserved.
//

import UIKit

class AltTextController: UIViewController {

	@IBOutlet var altTextDialogView : UIView!
	@IBOutlet var altTextTextView : UITextView!
	@IBOutlet var altTextCancelButton : UIButton!
	@IBOutlet var altTextDoneButton : UIButton!

	@IBAction func done() {
		self.presentingViewController?.dismiss(animated: true)
	}

	@IBAction func cancel() {
		self.presentingViewController?.dismiss(animated: true)
	}
	
}
