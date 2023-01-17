//
//  AltTextController.swift
//  Sunlit
//
//  Created by Manton Reece on 8/8/21.
//  Copyright © 2021 Micro.blog, LLC. All rights reserved.
//

import UIKit

class AltTextController: UIViewController {

    @IBOutlet var altTextTextView : UITextView!
    var media : SunlitMedia?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        altTextTextView.text = media?.altText
        altTextTextView.becomeFirstResponder()
    }

	@IBAction func done() {
        media?.altText = altTextTextView.text
		self.presentingViewController?.dismiss(animated: true)
	}

	@IBAction func cancel() {
		self.presentingViewController?.dismiss(animated: true)
	}
	
}
