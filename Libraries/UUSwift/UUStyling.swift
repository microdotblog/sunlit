//
//  UUStyling.swift
//  Useful Utilities
//
//    License:
//  You are free to use this code for whatever purposes you desire.
//  The only requirement is that you smile everytime you use it.
//
//
//  UUStyling provides some simple category methods for styling and
//  appearance customization
//

#if os(iOS)

import UIKit

public extension UINavigationController
{
    func uuSetNavBarTransparent()
    {
        // Make navigation bar transparent
        let img = UIImage()
        self.navigationBar.setBackgroundImage(img, for: .default)
        self.navigationBar.shadowImage = UIImage()
    }
}

#endif
