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

let placeholderPost = SunlitPost("This is some text that will appear in the placeholder Widget. ", [])

struct HTMLText: UIViewRepresentable {

    let attributedString : NSAttributedString

    func updateUIView(_ uiView: UILabel, context: Context) {
        uiView.attributedText = attributedString
    }

    func makeUIView(context: UIViewRepresentableContext<Self>) -> UILabel {
        return UILabel()
    }
}

struct SunlitTimelineProvider: TimelineProvider {

    func getSnapshot(in context: Context, completion: @escaping (SunlitWidgetView) -> Void) {
        let widget = SunlitWidgetView(posts: [placeholderPost, placeholderPost, placeholderPost, placeholderPost], family: context.family)
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

                let timeline = Timeline(entries: entries, policy: .after(Date(timeIntervalSinceNow: 60.0)))
                completion(timeline)

                return
            }

            var posts: [SunlitPost] = []

            for entry in postObjects {

                if posts.count < 4 {
                    let post = SunlitPost.create(entry)

                    if post.images.count > 0 {
                        posts.append(post)

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

            let widgetView = SunlitWidgetView(posts: posts, family: context.family)
            let date = Date(timeIntervalSinceNow: 5 * 60.0)
            let timeline = Timeline(entries: [widgetView], policy: .after(date))
            completion(timeline)
        }
    }


    func placeholder(in context: Context) -> SunlitWidgetView {
        let post = SunlitWidgetView(posts: [placeholderPost], family: context.family)
        return post
    }
}


struct SunlitLargeTextView : View {

    let post : SunlitPost

    var body : some View {
        VStack(alignment: .leading, spacing: 0.0, content: {
            Text(post.owner.fullName)
                .font(Font.system(.caption).bold().italic())
                .foregroundColor(.gray)
                .frame(height:16.0)

            //HTMLText(attributedString: post.attributedText)
            Text(post.attributedText.string)
                .font(Font.system(.subheadline))
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .frame(height: 42.0)

            Spacer()
        })
    }
}


struct SunlitMediumTextView : View {

    let post : SunlitPost

    var body : some View {
        VStack(alignment: .leading, spacing: 0.0, content: {
            Text(post.owner.fullName)
                .font(Font.system(.caption).bold().italic())
                .foregroundColor(.gray)
                .frame(height:16.0)

            Spacer()
                .frame(height: 4.0)

            //HTMLText(attributedString: post.attributedText)
            Text(post.attributedText.string)
                .font(Font.system(size: 14.0))
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

                HStack {
                    Text("Recent Sunlit Posts")
                        .font(Font.system(.headline).bold())
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.red)

                    Spacer()
                    Image("welcome_waves")
                        .resizable()
                        .cornerRadius(2.0)
                        .frame(width: 20, height: 20)
                        .clipped()

                }

                Spacer()
                    .frame(height:8.0)

                ForEach(posts, id: \.self) { post in

                    if post != posts.first {
                        Divider()
                        Spacer()
                            .frame(height: 10.0)
                    }
					Link(destination: URL(string: "sunlit://show?id=\(post.identifier)")!) {
						HStack(alignment: .center, spacing: 8.0, content: {

							if let imagePath = post.images.first,
							   let image = ImageCache.prefetch(imagePath) {
									Image(uiImage: image)
										.resizable()
										.aspectRatio(contentMode: .fill)
										.frame(width: 60.0, height: 60.0)
										.clipped()
										.cornerRadius(8.0)

									SunlitLargeTextView(post: post)
							}
							else {
								Image(uiImage: UIImage(named: "welcome_waves")!)
									.resizable()
									.aspectRatio(contentMode: .fill)
									.frame(width: 60.0, height: 60.0)
									.clipped()
									.cornerRadius(8.0)

								SunlitLargeTextView(post: post)
									.redacted(reason: .placeholder)
							}

						})
						.frame(height: 60.0)
					}

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
            let index = Int.random(in: 0..<posts.count)
            if let post = posts[index] {
				Link(destination: URL(string: "sunlit://show?id=\(post.identifier)")!) {
					if let imagePath = post.images.first,
					   let image = ImageCache.prefetch(imagePath){
							Image(uiImage: image)
								.resizable()
								.aspectRatio(contentMode: .fill)
					}
					else {
						Image(uiImage: UIImage(named: "welcome_waves")!)
							.resizable()
							.aspectRatio(contentMode: .fill)
					}
				}
            }
        }
    }

    var mediumWidget: some View {
        HStack {
            Spacer()
                .frame(width: 12.0)

            let index = Int.random(in: 0..<posts.count)
            if let post = posts[index] {
				Link(destination: URL(string: "sunlit://show?id=\(post.identifier)")!) {
					HStack(alignment: .center, spacing: 8.0, content: {

						if let imagePath = post.images.first,
						   let image = ImageCache.prefetch(imagePath) {
							Image(uiImage: image)
								.resizable()
								.aspectRatio(contentMode: .fill)
								.frame(width: 128.0, height: 128.0)
								.clipped()
								.cornerRadius(8.0)

							SunlitMediumTextView(post: post)
						}
						else {
							Image(uiImage: UIImage(named: "welcome_waves")!)
								.resizable()
								.aspectRatio(contentMode: .fill)
								.frame(width: 128.0, height: 128.0)
								.clipped()
								.cornerRadius(8.0)

							SunlitMediumTextView(post: post)
								.redacted(reason: .placeholder)
						}

					})
				}
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
        SunlitWidgetView(posts: [placeholderPost, placeholderPost, placeholderPost, placeholderPost], family: .systemLarge)
            .previewContext(WidgetPreviewContext(family: .systemLarge))
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
