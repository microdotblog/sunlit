//
//  ImageViewerViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/9/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class ImageViewerViewController: UIViewController {

	@IBOutlet var image : UIImageView!
	var pathToImage = ""

    override func viewDidLoad() {
        super.viewDidLoad()

		self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(dismissViewController))
    
		if let image = ImageCache.prefetch(pathToImage) {
			self.image.image = image
		}
		else {
			ImageCache.fetch(self.pathToImage) { (image) in
					DispatchQueue.main.async {
						self.image.image = image
					}
			}
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)		
		self.navigationController?.setNavigationBarHidden(false, animated: true)
	}
	
	@objc func dismissViewController() {
		self.navigationController?.popViewController(animated: true)
	}
}
