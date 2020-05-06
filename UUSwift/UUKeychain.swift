//
//  UUKeychain.swift
//  UUSwift
//
// UUKeychain contains several convenience methods for reading and writing values
// to the iOS keychain.
//

#if os(iOS)

import Foundation
import Security

public let UUKeychainErrorDomain = "UUKeychainErrorDomain"

public class UUKeychain: NSObject
{
    public class func getString(key: String) -> String?
    {
        do
        {
            return try tryGetString(key: key)
        }
        catch
        {
            return nil
        }
    }
    
    public class func saveString(key: String, acceessLevel: CFTypeRef, string: String)
    {
        do
        {
            try trySaveString(key: key, acceessLevel: acceessLevel, string: string)
        }
        catch
        {
        }
    }
    
    public class func getData(key: String) -> Data?
    {
        do
        {
            return try tryGetData(key: key)
        }
        catch
        {
            return nil
        }
        
    }
    
    public class func saveData(key: String, acceessLevel: CFTypeRef, data: Data?)
    {
        do
        {
            try trySaveData(key: key, acceessLevel: acceessLevel, data: data)
        }
        catch
        {
        }
    }
    
    public class func remove(key: String)
    {
        do
        {
            try tryRemove(key: key)
        }
        catch
        {
        }
    }
    
    public class func tryGetString(key: String) throws -> String?
    {
        var result: String? = nil
        
        if let data = try self.tryGetData(key: key)
        {
            result = String(bytes: data, encoding: .utf8)
        }
        
        return result
    }
    
    public class func trySaveString(key: String, acceessLevel: CFTypeRef, string: String) throws
    {
        let data = string.data(using: .utf8)
        try self.trySaveData(key: key, acceessLevel: acceessLevel, data: data)
    }
    
    public class func tryGetData(key: String) throws -> Data?
    {
        var d = commonDictionary(key: key)
        d[kSecReturnData] = true
        
        var outValRaw: CFTypeRef? = nil
        let result = SecItemCopyMatching(d as CFDictionary, &outValRaw)
        if (result == errSecSuccess && outValRaw != nil)
        {
            let outVal = outValRaw as? Data
            return outVal
        }
        else
        {
            throw NSError(domain: UUKeychainErrorDomain, code: Int(result), userInfo: nil)
        }
    }
    
    public class func trySaveData(key: String, acceessLevel: CFTypeRef, data: Data?) throws
    {
        var d = commonDictionary(key: key)
        d[kSecValueData] = data
        d[kSecAttrAccessible] = acceessLevel
        
        var result = SecItemAdd(d as CFDictionary, nil)
        if (result == errSecDuplicateItem)
        {
            let query = commonDictionary(key: key)
            d.removeValue(forKey: kSecClass)
            result = SecItemUpdate(query as CFDictionary, d as CFDictionary)
        }
        
        if (result != errSecSuccess)
        {
            throw NSError(domain: UUKeychainErrorDomain, code: Int(result), userInfo: nil)
        }
    }
    
    public class func tryRemove(key: String) throws
    {
        let d = commonDictionary(key: key)
        
        let result = SecItemDelete(d as CFDictionary)
        switch (result)
        {
            case errSecSuccess, errSecItemNotFound:
            break
            
            default:
            
                throw NSError(domain: UUKeychainErrorDomain, code: Int(result), userInfo: nil)
        }
    }
    
    // Private
    
    private class func keychainIdentifier() -> String
    {
        return Bundle.main.bundleIdentifier!.appending("-UUKeychain")
    }
    
    private class func commonDictionary(key: String) -> [AnyHashable:Any]
    {
        var d: [AnyHashable:Any] = [:]
        d[kSecClass] = kSecClassGenericPassword
        d[kSecAttrService] = self.keychainIdentifier()
        
        let encodedIdentifier = key.data(using: .utf8)
        d[kSecAttrGeneric] = encodedIdentifier
        d[kSecAttrAccount] = encodedIdentifier
        
        return d
    }
}

#endif
