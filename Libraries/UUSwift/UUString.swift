//
//  UUString.swift
//  Useful Utilities - Extensions for String
//
//	License:
//  You are free to use this code for whatever purposes you desire.
//  The only requirement is that you smile everytime you use it.
//

#if os(macOS)
	import AppKit
#else
	import UIKit
#endif

public extension String
{
    // Access a sub string based on integer start index and integer length.
    //
    // If the end index is out of bounds, will return as many characters as
    // available up to the end of the string.
    //
    // Out of bounds indices are clamped to fit within range of the string.
    //
    func uuSubString(_ from: Int, _ length: Int) -> String
    {
        var adjustedFrom = from
        if (adjustedFrom < 0)
        {
            adjustedFrom = 0
        }
        
        var adjustedLength = length
        if (adjustedLength > self.count)
        {
            adjustedLength = self.count
        }
        
        let start = self.index(self.startIndex, offsetBy: adjustedFrom, limitedBy: self.endIndex)
        var end = self.index(self.startIndex, offsetBy: (adjustedFrom + adjustedLength), limitedBy: self.endIndex)
        if (end == nil)
        {
            end = self.endIndex
        }
        
        if (start != nil && end != nil)
        {
            return String.init(self[start! ..< end!])
        }
        
        return ""
    }
    
    // Returns the first N characters of the string
    func uuFirstNChars(_ count: Int) -> String
    {
        return uuSubString(0, count)
    }
    
    // Returns the last N characters of the string
    func uuLastNChars(_ count: Int) -> String
    {
        return uuSubString(self.count - count, count)
    }
    
    private static let kUrlEncodingChars = "!*'();:@&=+$,/?%#[] "
    private static let kUrlEncodingCharSet = CharacterSet.init(charactersIn: kUrlEncodingChars).inverted
    
    // Percent encodes the following characters:
    //
    // !*'();:@&=+$,/?%#[]
    //
    func uuUrlEncoded() -> String
    {
        var encoded : String? = addingPercentEncoding(withAllowedCharacters: String.kUrlEncodingCharSet)
        if (encoded == nil)
        {
            encoded = self
        }
        
        return encoded!
    }
    
    // Trim whitespace from beginning and end of string
    func uuTrimWhitespace() -> String
    {
        return trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    // Parses this string as a decimal number
    func uuAsDecimalNumber() -> NSNumber?
    {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f.number(from: self)
    }
    
    func uuToJsonObject(_ encoding : String.Encoding = .utf8) -> Any?
    {
        let encodedData = data(using: encoding)
        if (encodedData != nil)
        {
            return encodedData!.uuToJson()
        }
        else
        {
            return nil
        }
    }
    
    func uuToHexData() -> NSData?
    {
        let length:Int = self.count
        
        // Must greater than zero and be divisible by two
        if (length <= 0 || (length % 2) != 0)
        {
            return nil;
        }
        
        let data:NSMutableData = NSMutableData()
        
        for i in stride(from: 0, to: length, by: 2)
        {
            let sc:Scanner = Scanner(string: self.uuSubString(i, 2)) //Substring was deprecated, so using uu
            
            var hex:UInt64 = 0
            if (sc.scanHexInt64(&hex))
            {
                var tmp:UInt8 = UInt8(hex)
                data.append(&tmp, length: MemoryLayout<UInt8>.size) //sizeof deprecated
            }
            else
            {
                return nil
            }
        }
        
        return data
    }
    
    func uuBase64UrlDecode() -> Data?
    {
        // Base64 URL mode swaps '-' with '+' and '_' with '/'
        var tmp = self
        tmp = tmp.replacingOccurrences(of: "-", with: "+")
        tmp = tmp.replacingOccurrences(of: "_", with: "/")
        
        let currentLength = tmp.lengthOfBytes(using: .utf8)
        let multipleOfFourLength = 4 * Int(ceil(Double(currentLength) / 4.0))
        
        // Base64 also requires padding to a multiple of four
        tmp = tmp.padding(toLength: multipleOfFourLength, withPad: "=", startingAt: 0)
        
        return Data(base64Encoded: tmp, options: .ignoreUnknownCharacters)
    }
    
    func uuIsValidEmail() -> Bool
    {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format:"SELF MATCHES %@", regex)
        return predicate.evaluate(with: self)
    }
    
    // Converts a string assumed to be snake_case into camelCase
    func uuToCamelCase() -> String
    {
        let parts = split(separator: "_")
        var capitalizedParts = parts.map({ $0.capitalized })
        
        if (capitalizedParts.count > 0)
        {
            capitalizedParts[0] = capitalizedParts[0].lowercased()
        }
        
        return capitalizedParts.joined()
    }
    
    // Converts a string assumed to be camelCase into snake_case
    func uuToSnakeCase() -> String
    {
        var working = ""
        
        for c in self
        {
            if (c.isUppercase)
            {
                working.append("_")
            }
            
            working.append(c)
        }
        
        return working.lowercased()
    }
    
}

