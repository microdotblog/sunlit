//
//  TimelineProvider.swift
//  Sunlit
//
//  Created by Jonathan Hays on 10/21/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import WidgetKit
import SwiftUI
import Intents
import Snippets
import UIKit

struct SunlitTimelineProvider: IntentTimelineProvider {

    typealias Entry = SunlitWidgetView
    typealias Intent = SunlitFeedConfigurationIntent


    func getSnapshot(for configuration: SunlitFeedConfigurationIntent, in context: Context, completion: @escaping (SunlitWidgetView) -> Void) {
        let widget = SunlitWidgetView(posts: placeholderPosts, family: context.family, configuration: configuration)
        completion(widget)
    }

    func handleTimeline(error : Error?, postObjects: [SnippetsPost], context: Context, configuration: SunlitFeedConfigurationIntent, completion: @escaping (Timeline<SunlitWidgetView>) -> Void) {
        if let err = error {
            var entries : [SunlitWidgetView] = []
            let post = SunlitWidgetView(posts: [SunlitPost(err.localizedDescription , [])], family: context.family, configuration: configuration)
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
                        posts.append(post)
                    }
                }
            }
        }

        // If the context is large, we want to leave only 4 posts in the list...
        if context.family == .systemLarge {
            while posts.count > 4 {

                // Because random is a setting, we need to randomly remove posts until there are only 4 left...
                let index = (configuration.random == true) ? Int.random(in: 0..<posts.count) : posts.count - 1
                posts.remove(at: index)
            }
        }

        let widgetView = SunlitWidgetView(posts: posts, family: context.family, configuration: configuration)
        let date = Date(timeIntervalSinceNow: 5 * 60.0)
        let timeline = Timeline(entries: [widgetView], policy: .after(date))
        completion(timeline)
    }


    func getTimeline(for configuration: SunlitFeedConfigurationIntent, in context: Context, completion: @escaping (Timeline<SunlitWidgetView>) -> Void) {

        if let token = Settings.snippetsToken() {
            Snippets.Configuration.timeline = Snippets.Configuration.microblogConfiguration(token: token)
        }

        if configuration.feed == .discover {
            if configuration.tagmoji == .art {
                Snippets.Microblog.fetchDiscoverTimeline(collection: "art", parameters: [:]) { (error, posts, tagmoji) in
                    handleTimeline(error: error, postObjects: posts, context: context, configuration: configuration, completion: completion)
                }
            }
            else if configuration.tagmoji == .cats {
                Snippets.Microblog.fetchDiscoverTimeline(collection: "cats", parameters: [:]) { (error, posts, tagmoji) in
                    handleTimeline(error: error, postObjects: posts, context: context, configuration: configuration, completion: completion)
                }
            }
            else if configuration.tagmoji == .dogs {
                Snippets.Microblog.fetchDiscoverTimeline(collection: "dogs", parameters: [:]) { (error, posts, tagmoji) in
                    handleTimeline(error: error, postObjects: posts, context: context, configuration: configuration, completion: completion)
                }
            }
            else {
                Snippets.Microblog.fetchDiscoverTimeline { (error, posts, tagmoji) in
                    handleTimeline(error: error, postObjects: posts, context: context, configuration: configuration, completion: completion)
                }
            }
        }
        else {
            Snippets.Microblog.fetchCurrentUserMediaTimeline { (error, postObjects : [SnippetsPost]) in
                handleTimeline(error: error, postObjects: postObjects, context: context, configuration : configuration, completion: completion)
            }
        }
    }


    func placeholder(in context: Context) -> SunlitWidgetView {
        let post = SunlitWidgetView(posts: placeholderPosts, family: context.family, configuration: SunlitFeedConfigurationIntent())
        return post
    }
}
