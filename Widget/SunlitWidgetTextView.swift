//
//  WidgetTextView.swift
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
import WebKit

struct HTMLText: UIViewRepresentable {

    let attributedString : NSAttributedString

    func updateUIView(_ uiView: UILabel, context: Context) {
        uiView.attributedText = attributedString
    }

    func makeUIView(context: UIViewRepresentableContext<Self>) -> UILabel {
        return UILabel()
    }
}

struct HTMLView : UIViewRepresentable {

    let htmlString : String

    init(_ string : String) {
        htmlString = string
    }

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(self.htmlString, baseURL: nil)
    }
}
