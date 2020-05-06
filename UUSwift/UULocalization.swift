//
//  UULocalization.swift
//  UUSwift
//
//  Created by Ryan DeVore on 7/11/19.
//
#if os(iOS)

import UIKit


public extension UILabel
{
    @IBInspectable var uuLocalizedTextKey: String
    {
        get
        {
            return text ?? ""
        }
        
        set (key)
        {
            text = NSLocalizedString(key, comment: "")
        }
    }
}

public extension UIButton
{
    @IBInspectable var uuLocalizedTextKey: String
    {
        get
        {
            return title(for: .normal) ?? ""
        }
        
        set (key)
        {
            setTitle(NSLocalizedString(key, comment: ""), for: .normal)
        }
    }
}

public extension UITextField
{
    @IBInspectable var uuLocalizedTextKey: String
    {
        get
        {
            return text ?? ""
        }
        
        set (key)
        {
            text = NSLocalizedString(key, comment: "")
        }
    }
    
    @IBInspectable var uuLocalizedPlaceholderTextKey: String
    {
        get
        {
            return placeholder ?? ""
        }
        
        set (key)
        {
            placeholder = NSLocalizedString(key, comment: "")
        }
    }
}

public extension UITabBarItem
{
    @IBInspectable var uuLocalizedTextKey: String
    {
        get
        {
            return title ?? ""
        }
        
        set (key)
        {
            title = NSLocalizedString(key, comment: "")
        }
    }
}

public extension UINavigationItem
{
    @IBInspectable var uuLocalizedTextKey: String
        {
        get
        {
            return title ?? ""
        }
        
        set (key)
        {
            title = NSLocalizedString(key, comment: "")
        }
    }
}

public extension UISearchBar
{
    @IBInspectable var uuLocalizedPlaceholderTextKey: String
    {
        get
        {
            return placeholder ?? ""
        }
        
        set (key)
        {
            placeholder = NSLocalizedString(key, comment: "")
        }
    }
}

#endif
