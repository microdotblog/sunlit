//
//  ShareViewController.swift
//  sharing
//
//  Created by Jonathan Hays on 10/6/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import Snippets

class ShareViewController: UINavigationController {

    override func awakeFromNib() {
        super.awakeFromNib()

        if let token = Settings.snippetsToken() {
            Snippets.Configuration.timeline = Snippets.Configuration.microblogConfiguration(token: token)
        }
        else {
            Dialog(self).information("Sunlit setup has not been completed. Please launch Sunlit and login.") {
                self.extensionContext?.cancelRequest(withError: URLError(URLError.cancelled))
            }

            return
        }

        let storyboard = UIStoryboard(name: "Compose", bundle: nil)
        let composeController = storyboard.instantiateViewController(identifier: "ComposeViewController")
        self.pushViewController(composeController, animated: false)
    }
}
