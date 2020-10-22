//
//  WidgetView.swift
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


/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */


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

/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */


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


/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */


struct SunlitWidgetView : TimelineEntry, View {

    public var date : Date {
        get {
            return posts.first?.publishedDate ?? Date()
        }
    }

    let posts : [SunlitPost]
    let family : WidgetFamily
    let configuration : SunlitFeedConfigurationIntent


    var smallWidget: some View {
        HStack {
            if posts.count > 0 {
                let index = (configuration.random == true) ? Int.random(in: 0..<posts.count) : 0

                if let post = posts[index] {
                    SunlitWidgetImage(post: post)
                        .widgetURL(URL(string: "sunlit://show?id=\(post.identifier)"))
                }
            }
            else {
                SunlitWidgetImage(post: placeholderPost)
            }
        }
    }

    var mediumWidget: some View {
        HStack {
            let index = (configuration.random == true) ? Int.random(in: 0..<posts.count) : 0

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
