//
//  Dialogs.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/3/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class Dialog {
	
	static func information(_ string : String, _ viewController : UIViewController, completion: (()->Void)? = nil) {
		
		// Make sure we aren't on a background thread...
		DispatchQueue.main.async {
			let alertController = UIAlertController(title: nil, message: string, preferredStyle: .alert)
			alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
				if let done = completion {
					done()
				}
			}))
			
			viewController.present(alertController, animated: true, completion: nil)
		}
	}
	
}
