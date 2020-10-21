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

struct SunlitTimelineProvider: IntentTimelineProvider {

    typealias Entry = SunlitWidgetView
    typealias Intent = SunlitFeedConfigurationIntent


    func getSnapshot(for configuration: SunlitFeedConfigurationIntent, in context: Context, completion: @escaping (SunlitWidgetView) -> Void) {
        let widget = SunlitWidgetView(posts: [placeholderPost, placeholderPost, placeholderPost, placeholderPost], family: context.family)
        completion(widget)
    }

    func handleTimeline(error : Error?, postObjects: [SnippetsPost], context: Context, completion: @escaping (Timeline<SunlitWidgetView>) -> Void) {
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

            let post = SunlitPost.create(entry)
            if post.images.count > 0 {
                if let imagePath = post.images.first {
                    if ImageCache.prefetch(imagePath) == nil {
                        ImageCache.fetch(imagePath) { (image) in
                            WidgetCenter.shared.reloadTimelines(ofKind: "blog.micro.sunlit.widget")
                        }
                    }
                    else {
                        if posts.count < 4 || context.family != .systemLarge{
                            posts.append(post)
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


    func getTimeline(for configuration: SunlitFeedConfigurationIntent, in context: Context, completion: @escaping (Timeline<SunlitWidgetView>) -> Void) {

        if let token = Settings.object(forKey: "Snippets") as? String {
            Snippets.Configuration.timeline = Snippets.Configuration.microblogConfiguration(token: token)
        }

        if configuration.feed == .discover {
            Snippets.Microblog.fetchDiscoverTimeline { (error, posts, tagmoji) in
                handleTimeline(error: error, postObjects: posts, context: context, completion: completion)
            }
        }
        else {
            Snippets.Microblog.fetchCurrentUserMediaTimeline { (error, postObjects : [SnippetsPost]) in
                handleTimeline(error: error, postObjects: postObjects, context: context, completion: completion)
            }
        }
    }


    func placeholder(in context: Context) -> SunlitWidgetView {
        let post = SunlitWidgetView(posts: [placeholderPost, placeholderPost, placeholderPost, placeholderPost], family: context.family)
        return post
    }
}

struct SunlitWidgetImage : View {

	let post : SunlitPost

	var body : some View {
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

struct SunlitMediumWidgetEntry : View {
	let post : SunlitPost

	var body : some View {
		HStack(alignment: .center, spacing: 8.0, content: {

			SunlitWidgetImage(post: post)
				.frame(width: 128.0, height: 128.0)
				.clipped()
				.cornerRadius(8.0)

			if let imagePath = post.images.first,
			   ImageCache.prefetch(imagePath) != nil {
				SunlitMediumTextView(post: post)
			}
			else {
				SunlitMediumTextView(post: post)
					.redacted(reason: .placeholder)
			}
		})
	}
}

struct SunlitLargeWidgetHeader : View {
	var body : some View {
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

struct SunlitLargeWidgetEntry : View {
	let post : SunlitPost

	var body : some View {
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
}


struct SunlitWidgetView : TimelineEntry, View {

    public var date : Date {
        get {
            return posts.first?.publishedDate ?? Date()
        }
    }

    let posts : [SunlitPost]
    let family : WidgetFamily


    var smallWidget: some View {
		HStack {
			let index = Int.random(in: 0..<posts.count)
			if let post = posts[index] {
				SunlitWidgetImage(post: post)
					.widgetURL(URL(string: "sunlit://show?id=\(post.identifier)"))
			}
		}
    }

    var mediumWidget: some View {
        HStack {
            let index = Int.random(in: 0..<posts.count)
            if let post = posts[index] {
				Link(destination: URL(string: "sunlit://show?id=\(post.identifier)")!) {
					Spacer()
						.frame(width: 12.0)

					SunlitMediumWidgetEntry(post: post)

					Spacer()
						.frame(width: 8.0)
				}
			}
        }
	}


	var largeWidget : some View {
		HStack {
			Spacer()
				.frame(width:14.0)

			VStack(alignment: .leading, spacing: 0.0, content: {

				Spacer()
					.frame(height: 8.0)

				SunlitLargeWidgetHeader()

				Spacer()
					.frame(height:8.0)

				ForEach(posts, id: \.self) { post in

					if post != posts.first {
						Divider()
						Spacer()
							.frame(height: 10.0)
					}

                    Link(destination: URL(string: "sunlit://show?id=\(post.identifier)")!) {
                        SunlitLargeWidgetEntry(post: post)
                        Spacer()
                    }
				}

				Spacer()
				   .frame(height:8.0)
			})

			Spacer()
				.frame(width: 16.0)
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
				.widgetURL(URL(string: "sunlit://"))
        }

    }
}




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
