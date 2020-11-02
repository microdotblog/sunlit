//
//  Widget.swift
//  Widget
//
//  Created by Jonathan Hays on 10/17/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import WidgetKit
import SwiftUI
import Intents
import Snippets
import UIKit

let placeholderPosts : [SunlitPost] = [
    SunlitPost("This is some text that will appear in the placeholder Widget. ", ["olive1"]),
    SunlitPost("This is some text that will appear in the placeholder Widget. ", ["olive2"]),
    SunlitPost("This is some text that will appear in the placeholder Widget. ", ["olive3"]),
    SunlitPost("This is some text that will appear in the placeholder Widget. ", ["olive4"])
]

@main
struct SunlitWidget: Widget {

    var body: some WidgetConfiguration {

        IntentConfiguration(kind: "blog.micro.sunlit.widget", intent: SunlitFeedConfigurationIntent.self, provider: SunlitTimelineProvider())
        { (entry) in
            entry
        }
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct Widget_Previews:
    PreviewProvider {
    static var previews: some View {
        SunlitWidgetView(posts: placeholderPosts, family: .systemSmall, configuration: SunlitFeedConfigurationIntent())
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

extension SunlitPost {
    convenience init(_ text : String, _ images : [String]) {
        self.init()
        self.attributedText = NSAttributedString(string: text)
        self.images = images
        self.publishedDate = Date()
        self.owner = SnippetsUser()
        self.owner.fullName = "Jonathan Hays"
    }

    func shouldRedact() -> Bool {
        if let path = self.images.first {
            return ImageCache.prefetch(path) == nil
        }
        return true
    }
}
