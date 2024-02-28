//
//  ContentViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 9/24/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class ContentViewController : UIViewController {

	var isPresented = false

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    dynamic func navbarTitle() -> String {
        return "Timeline"
    }

    dynamic func setupNavigation() {
        let button = UIButton(type: .custom)
        button.backgroundColor = .clear

		var title = self.navigationItem.title
		if (title == nil) || (title?.count == 0) {
			title = self.navbarTitle()
		}
		button.setTitle(title, for: .normal)

		button.setTitleColor(.label, for: .normal)
        button.addTarget(self, action: #selector(handleScrollToTopGesture), for: .touchUpInside)
        self.navigationController?.navigationBar.topItem?.titleView = button
        self.navigationController?.navigationItem.titleView = button
    }

    dynamic func setupNotifications() {
        // Clear out any old notification registrations...
        NotificationCenter.default.removeObserver(self)
    }

    dynamic func prepareToDisplay() {
		self.isPresented = true
        self.setupNavigation()
        self.setupNotifications()
    }

    dynamic func prepareToHide() {
		self.isPresented = false
        NotificationCenter.default.removeObserver(self)
    }


    @objc dynamic func handleScrollToTopGesture() {
    }
}
