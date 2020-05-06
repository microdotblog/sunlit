//
//  UUColor.swift
//  Useful Utilities - Extensions for UIColor
//
//	License:
//  You are free to use this code for whatever purposes you desire.
//  The only requirement is that you smile everytime you use it.
//

#if os(macOS)
	import AppKit
	public typealias UUColor = NSColor
#else
	import UIKit
	public typealias UUColor = UIColor
#endif

public extension UUColor
{
    // Creates a UIColor object from a hex string in the form of
    //
    // RRGGBB or RRGGBBAA
    //
    static func uuColorFromHex(_ color: String) -> UUColor
    {
        var rgba : [CGFloat] = [0, 0, 0, 1]
        
        let len = color.lengthOfBytes(using: .utf8)
        if (len == 6 || len == 8)
        {
            var i = 0
            while (i < len)
            {
                let subStr = color.uuSubString(i, 2)
                
                let scanner = Scanner(string: subStr)
                
                var hex : UInt64 = 0
                if (scanner.scanHexInt64(&hex))
                {
                    rgba[i/2] = (CGFloat(hex) / 255.0)
                }
                
                i = i + 2
            }
        }
        
        let c = UUColor(red: rgba[0], green: rgba[1], blue: rgba[2], alpha: rgba[3])
        return c
    }
    
    // Calculates the midpoint value of each color component between two colors
    static func uuCalculateMidColor(startColor: UUColor, endColor: UUColor) -> UUColor
    {
        var r : CGFloat = 0
        var g : CGFloat = 0
        var b : CGFloat = 0
        var a : CGFloat = 0
        startColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let startColors : [CGFloat] = [r, g, b, a]
        
        endColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        let endColors : [CGFloat] = [r, g, b, a]
        
        var midColors : [CGFloat] = [0, 0, 0, 0]
        
        var i = 0
        while (i < midColors.count)
        {
            midColors[i] = (startColors[i] + endColors[i]) / 2.0
            i = i + 1
        }
        
        let midColor = UUColor.init(red: midColors[0], green: midColors[1], blue: midColors[2], alpha: midColors[3])
        return midColor
    }
	
	// Returns a string representing the hex values
    var uuHexString:String {
		var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        
        return NSString(format:"#%06x", rgb) as String
    }
}
