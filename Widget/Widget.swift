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

        let widget = SunlitWidgetView(posts: [SunlitPost("Hello world", ["olive"])], family: context.family)
        completion(widget)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SunlitWidgetView>) -> Void) {

        if let token = Settings.object(forKey: "Snippets") as? String {
            Snippets.Configuration.timeline = Snippets.Configuration.microblogConfiguration(token: token)
        }

        Snippets.Microblog.fetchCurrentUserMediaTimeline { (error, postObjects : [SnippetsPost]) in

            if let err = error {
                var entries : [SunlitWidgetView] = []
                let post = SunlitWidgetView(posts: [SunlitPost(err.localizedDescription , [])], family: context.family)
                entries.append(post)

                let timeline = Timeline(entries: entries, policy: .atEnd)
                completion(timeline)

                return
            }

            var entries: [SunlitPost] = []

            for entry in postObjects {

                if entries.count < 4 {
                    let post = SunlitPost.create(entry)

                    if post.images.count > 0 {
                        entries.append(post)

                        if let imagePath = post.images.first {
                            if ImageCache.prefetch(imagePath) == nil {
                                ImageCache.fetch(imagePath) { (image) in
                                    WidgetCenter.shared.reloadTimelines(ofKind: "blog.micro.sunlit.widget")
                                }
                            }
                        }
                    }
                }
            }

            let widgetView = SunlitWidgetView(posts: entries, family: context.family)
            let timeline = Timeline(entries: [widgetView], policy: .atEnd)
            completion(timeline)
        }

    }


    func placeholder(in context: Context) -> SunlitWidgetView {

        let post = SunlitWidgetView(posts: [SunlitPost("Placeholder", ["olive"])], family: context.family)
        return post
    }
}



struct SunlitWidgetView : TimelineEntry, View {

    public var date : Date {
        get {
            return posts.first?.publishedDate ?? Date()
        }
    }

    let posts : [SunlitPost]
    let family : WidgetFamily

    var largeWidget : some View {
        HStack {
            Spacer()
                .frame(width:14.0)

            VStack(alignment: .leading, spacing: 0.0, content: {

                Spacer()
                    .frame(height: 8.0)

                Text("Recent Sunlit Posts")
                    .font(Font.system(.headline).bold())
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.red)

                Spacer()
                    .frame(height:8.0)

                ForEach(posts, id: \.self) { post in


                    HStack(alignment: .center, spacing: 8.0, content: {

                        if let imagePath = post.images.first {
                            Image(uiImage: ImageCache.prefetch(imagePath) ?? UIImage(named: "olive")!)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60.0, height: 60.0)
                                .clipped()
                                .cornerRadius(8.0)
                        }


                        VStack(alignment: .leading, spacing: 0.0, content: {
                            Text(post.owner.fullName)
                                .font(Font.system(.caption).bold().italic())
                                .foregroundColor(.gray)
                                .frame(height:16.0)

                            Text(post.attributedText.string)
                                .font(Font.system(.subheadline))
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                                .frame(height: 42.0)

                            Spacer()
                        })
                    })
                    .frame(height: 64.0)

                    Spacer()

                }

                Spacer()
                   .frame(height:8.0)
            })

            Spacer()
                .frame(width: 16.0)
        }
    }

    var smallWidget: some View {
        HStack {
            if let post = posts.first {
                if let imagePath = post.images.first {
                    Image(uiImage: ImageCache.prefetch(imagePath) ?? UIImage(named: "olive")!)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            }
        }
    }

    var mediumWidget: some View {
        HStack {
            Spacer()
                .frame(width: 12.0)

            if let post = posts.first {
                HStack(alignment: .center, spacing: 8.0, content: {

                    if let imagePath = post.images.first {
                        Image(uiImage: ImageCache.prefetch(imagePath) ?? UIImage(named: "olive")!)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 128.0, height: 128.0)
                            .clipped()
                            .cornerRadius(8.0)
                    }

                    VStack(alignment: .leading, spacing: 0.0, content: {
                        Text(post.owner.fullName)
                            .font(Font.system(.caption).bold().italic())
                            .foregroundColor(.gray)
                            .frame(height:16.0)

                        Spacer()
                            .frame(height: 4.0)

                        Text(post.attributedText.string)
                            .font(Font.system(size: 14.0))
                            //.font(Font.system(.subheadline))
                            .multilineTextAlignment(.leading)
                            .lineLimit(6)
                            .frame(height: 84.0)

                        Spacer()
                            .frame(height: 8.0)

                        Divider()

                        Text(post.publishedDate!.friendlyFormat())
                            .font(Font.system(.footnote))
                            .foregroundColor(.gray)
                            .frame(height: 16.0)
                            .multilineTextAlignment(.leading)

                    })
                })
            }

            Spacer()
                .frame(width: 8.0)
        }
    }

    var body: some View {

        if family == .systemSmall {
            self.smallWidget
        }
        else if family == .systemMedium{
            self.mediumWidget
        }
        else {
            self.largeWidget
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
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct Widget_Previews:
    PreviewProvider {
    static var previews: some View {
        SunlitWidgetView(posts: [SunlitPost("This is some text that will appear in the placeholder Widget. This image is of my lovely dog, Olive.", ["olive", "olive", "olive"])], family: .systemMedium)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
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
}
