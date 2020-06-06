//
//  UUDictionary.swift
//  Useful Utilities - Extensions for Dictionary
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


public extension Dictionary
{
    func uuBuildQueryString() -> String
    {
        let sb : NSMutableString = NSMutableString()
        
        for key in keys
        {
            guard let stringKey = key as? String else
            {
                continue
            }
            
            let formattedKey = stringKey.uuUrlEncoded()
            
            var prefix = "&"
            if ((sb as String).count == 0)
            {
                prefix = "?"
            }
            
            let rawVal = self[key]
            var val : String? = nil
            
            if (rawVal is String)
            {
                val = rawVal as? String
            }
            else if (rawVal is NSNumber)
            {
                val = (rawVal as? NSNumber)?.stringValue
            }
            else if let arrayVal = rawVal as? [String]
            {
                let arrayKey = "\(formattedKey)[]"
                
                for strVal in arrayVal
                {
                    let formattedVal = strVal.uuUrlEncoded()
                    sb.appendFormat("%@%@=%@", prefix, arrayKey, formattedVal)
                    prefix = "&"
                }
                
                continue
            }
            
            if (val != nil)
            {
                let formattedVal = val!.uuUrlEncoded()
                
                sb.appendFormat("%@%@=%@", prefix, formattedKey, formattedVal)
            }
        }
        
        return sb as String
    }
    
    func uuSafeGetDate(_ key: Key, formatter: DateFormatter) -> Date?
    {
        guard let stringVal = self[key] as? String else
        {
            return nil
        }
        
        return formatter.date(from: stringVal)
    }
    
    func uuSafeGetString(_ key: Key) -> String?
    {
        return self[key] as? String
    }
    
    func uuSafeGetNumber(_ key: Key) -> NSNumber?
    {
        var val = self[key] as? NSNumber
        
        if (val == nil)
        {
            if let str = uuSafeGetString(key)
            {
                let nf = NumberFormatter()
                nf.numberStyle = .decimal
                val = nf.number(from: str)
            }
        }
        
        return val
    }
    
    func uuSafeGetNumberArray(_ key: Key) -> [NSNumber]
    {
        guard let arr = self[key] as? [Any] else
        {
            return []
        }
        
        var result: [NSNumber] = []
        
        for obj in arr
        {
            let d = ["val": obj ]
            if let num = d.uuSafeGetNumber("val")
            {
                result.append(num)
            }
        }
        
        return result
    }
    
    func uuSafeGetBool(_ key: Key) -> Bool?
    {
        guard let num = uuSafeGetNumber(key) else
        {
            return nil
        }
        
        return num.boolValue
    }
    
    func uuSafeGetInt(_ key: Key) -> Int?
    {
        guard let num = uuSafeGetNumber(key) else
        {
            return nil
        }
        
        return num.intValue
    }
    
    func uuSafeGetUInt8(_ key: Key) -> UInt8?
    {
        guard let num = uuSafeGetNumber(key) else
        {
            return nil
        }
        
        return num.uint8Value
    }
    
    func uuSafeGetUInt16(_ key: Key) -> UInt16?
    {
        guard let num = uuSafeGetNumber(key) else
        {
            return nil
        }
        
        return num.uint16Value
    }
    
    func uuSafeGetUInt32(_ key: Key) -> UInt32?
    {
        guard let num = uuSafeGetNumber(key) else
        {
            return nil
        }
        
        return num.uint32Value
    }
    
    func uuSafeGetUInt64(_ key: Key) -> UInt64?
    {
        guard let num = uuSafeGetNumber(key) else
        {
            return nil
        }
        
        return num.uint64Value
    }
    
    func uuSafeGetInt8(_ key: Key) -> Int8?
    {
        guard let num = uuSafeGetNumber(key) else
        {
            return nil
        }
        
        return num.int8Value
    }
    
    func uuSafeGetInt16(_ key: Key) -> Int16?
    {
        guard let num = uuSafeGetNumber(key) else
        {
            return nil
        }
        
        return num.int16Value
    }
    
    func uuSafeGetInt32(_ key: Key) -> Int32?
    {
        guard let num = uuSafeGetNumber(key) else
        {
            return nil
        }
        
        return num.int32Value
    }
    
    func uuSafeGetInt64(_ key: Key) -> Int64?
    {
        guard let num = uuSafeGetNumber(key) else
        {
            return nil
        }
        
        return num.int64Value
    }
    
    func uuSafeGetFloat(_ key: Key) -> Float?
    {
        guard let num = uuSafeGetNumber(key) else
        {
            return nil
        }
        
        return num.floatValue
    }
    
    func uuSafeGetDouble(_ key: Key) -> Double?
    {
        guard let num = uuSafeGetNumber(key) else
        {
            return nil
        }
        
        return num.doubleValue
    }
    
    func uuSafeGetDictionary(_ key: Key) -> [AnyHashable:Any]?
    {
        return self[key] as? [AnyHashable:Any]
    }
    
    func uuSafeGetObject<T: UUDictionaryConvertible>(type: T.Type, key: Key, context: Any? = nil) -> UUDictionaryConvertible?
    {
        guard let d = uuSafeGetDictionary(key) else
        {
            return nil
        }
        
        return T.create(from: d, context: context)
    }
    
    func uuSafeGetDictionaryArray(_ key: Key) -> [[AnyHashable:Any]]?
    {
        return self[key] as? [[AnyHashable:Any]]
    }
    
    func uuSafeGetObjectArray<T: UUDictionaryConvertible>(type: T.Type, key: Key, context: Any? = nil) -> [UUDictionaryConvertible]?
    {
        guard let array = uuSafeGetDictionaryArray(key) else
        {
            return nil
        }
        
        var list: [T] = []
        for d in array
        {
            list.append(T.create(from: d, context: context))
        }
        
        return list
    }
}

public protocol UUDictionaryConvertible
{
    init()
    
    func fill(from dictionary: [AnyHashable:Any], context: Any?)
    func toDictionary() -> [AnyHashable:Any]
}

public extension UUDictionaryConvertible
{
    static func create(from dictionary : [AnyHashable:Any], context: Any?) -> Self
    {
        let obj = self.init()
        obj.fill(from: dictionary, context: context)
        return obj
    }
}
