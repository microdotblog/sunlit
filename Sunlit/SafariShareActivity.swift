//
//  SafariShareActivity.swift
//  Sunlit
//
//  Created by Jonathan Hays on 2/26/24.
//  Copyright © 2024 Micro.blog, LLC. All rights reserved.
//

import UIKit

class SafariShareActivity: UIActivity {
    
    override var activityType: UIActivity.ActivityType? {
        UIActivity.ActivityType(rawValue: String(describing: type(of: self)))
    }
    
    override var activityTitle: String? {
        "Open in Safari"
    }
    
    override var activityImage: UIImage? {
        UIImage(systemName: "safari")?.applyingSymbolConfiguration(.init(scale: .large))
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        for item in activityItems {
            guard let url = item as? URL, UIApplication.shared.canOpenURL(url) else {
                continue
            }
            return true
        }
        return false
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        for item in activityItems {
            guard let url = item as? URL, UIApplication.shared.canOpenURL(url) else {
                continue
            }
            self.url = url
            return
        }
    }
    
    override func perform() {
        guard let url = url else {
            activityDidFinish(false)
            return
        }
        UIApplication.shared.open(url) { [weak self] completed in
            self?.activityDidFinish(completed)
        }
    }
    
    var url: URL?
}
