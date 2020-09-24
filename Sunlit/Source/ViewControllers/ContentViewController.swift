//
//  ContentViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 9/24/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class ContentViewController : UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupNotifications()
    }

    dynamic func navbarTitle() -> String {
        return "Timeline"
    }

    dynamic func setupNavigation() {

        let button = UIButton(type: .custom)
        button.backgroundColor = .clear
        button.setTitle(self.navbarTitle(), for: .normal)
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
        self.setupNavigation()
        self.setupNotifications()
    }

    dynamic func prepareToHide() {
        NotificationCenter.default.removeObserver(self)
    }


    @objc dynamic func handleScrollToTopGesture() {
    }
}
