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


struct HTMLText: UIViewRepresentable {

    let attributedString : NSAttributedString

    func updateUIView(_ uiView: UILabel, context: Context) {
        uiView.attributedText = attributedString
    }

    func makeUIView(context: UIViewRepresentableContext<Self>) -> UILabel {
        return UILabel()
    }
}
