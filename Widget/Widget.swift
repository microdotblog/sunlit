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

struct SunlitTimelineProvider: TimelineProvider {

    func getSnapshot(in context: Context, completion: @escaping (SunlitWidgetView) -> Void) {

        let widget = SunlitWidgetView(post: SunlitPost("Hello world", ["olive"]), family: context.family)
        completion(widget)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SunlitWidgetView>) -> Void) {

        if let token = Settings.object(forKey: "Snippets") as? String {
            Snippets.Configuration.timeline = Snippets.Configuration.microblogConfiguration(token: token)
        }

        Snippets.Microblog.fetchCurrentUserMediaTimeline { (error, postObjects : [SnippetsPost]) in

            if let err = error {
                var entries : [SunlitWidgetView] = []
                let post = SunlitWidgetView(post: SunlitPost(err.localizedDescription , []), family: context.family)
                entries.append(post)

                let timeline = Timeline(entries: entries, policy: .atEnd)
                completion(timeline)

                return
            }

            var entries: [SunlitWidgetView] = []

            if let entry = postObjects.first {
                let post = SunlitPost.create(entry)
                entries.append(SunlitWidgetView(post: post, family: context.family))

                ImageCache.fetch(post.images.first!) { (image) in
                    let timeline = Timeline(entries: entries, policy: .atEnd)
                    completion(timeline)
                }
            }

            /*for entry in postObjects {
                let post = SunlitPost.create(entry)
                if post.images.count > 0 {
                    entries.append(SunlitWidgetView(post: post))
                }
            }*/


        }

    }


    func placeholder(in context: Context) -> SunlitWidgetView {

        let post = SunlitWidgetView(post: SunlitPost("Placeholder", ["olive"]), family: context.family)
        return post
    }

}



struct SunlitWidgetView : TimelineEntry, View {

    public var date : Date {
        get {
            return post.publishedDate ?? Date()
        }
    }

    let post : SunlitPost
    let family : WidgetFamily

    var body: some View {

        HStack {
            Image(uiImage: ImageCache.prefetch(post.images.first!) ?? UIImage(named: "olive")!)
                .resizable()
                .aspectRatio(contentMode: .fit)

            if family == .systemMedium {
                Text(post.attributedText.string)
            }
        }

    }
}




@main
struct SunlitWidget: Widget {

    var body: some WidgetConfiguration {

        StaticConfiguration(kind: "blog.micro.sunlit.widget", provider: SunlitTimelineProvider())
        { (entry) in
            entry
        }
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct Widget_Previews:
    PreviewProvider {
    static var previews: some View {
        SunlitWidgetView(post: SunlitPost("Loading...", ["olive", "olive", "olive"]), family: .systemMedium)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}

extension SunlitPost {
    convenience init(_ text : String, _ images : [String]) {
        self.init()
        self.attributedText = NSAttributedString(string: text)
        self.images = images
    }
}
