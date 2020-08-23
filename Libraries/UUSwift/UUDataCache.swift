//  UUDataCache
//  Useful Utilities - UUDataCache is a lightweight facade for caching data.
//
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

import CoreData

// UUDataCacheProtocol defines a lightweight interface for caching of data
// along with a meta data dictionary about each blob of data.
public protocol UUDataCacheProtocol
{
    func data(for key: String) -> Data?
    func set(data: Data, for key: String)
    
    func metaData(for key: String) -> [String:Any]
    func set(metaData: [String:Any], for key: String)
    
    func dataExists(for key: String) -> Bool
    func isDataExpired(for key: String) -> Bool
    
    func removeData(for key: String)
    
    func clearCache()
    func purgeExpiredData()
    
    var dataExpirationInterval : TimeInterval { get set }
    
    func listKeys() -> [String]
}

// Default implementation of UUDataCacheProtocol.  Data objects are persisted
// in an NSCache backed by raw data files.
//
// Meta Data is persisted with CoreData
public class UUDataCache : NSObject, UUDataCacheProtocol
{
    ////////////////////////////////////////////////////////////////////////////
    // Constants
    ////////////////////////////////////////////////////////////////////////////
    public struct Constants
    {
        public static let defaultContentExpirationLength : TimeInterval = (60 * 60 * 24 * 30) // 30 days
    }
    
    public struct MetaDataKeys
    {
        public static let timestamp = "timestamp"
    }
    
    ////////////////////////////////////////////////////////////////////////////
    // Class Data Memebers
    ////////////////////////////////////////////////////////////////////////////
    public static let shared = UUDataCache()
    
    ////////////////////////////////////////////////////////////////////////////
    // Instance Data Memebers
    ////////////////////////////////////////////////////////////////////////////
    public var contentExpirationLength : TimeInterval = Constants.defaultContentExpirationLength
    
    private var cacheFolder : String = ""
    
    ////////////////////////////////////////////////////////////////////////////
    // Initialization
    ////////////////////////////////////////////////////////////////////////////
    required public init(cacheLocation : String = UUDataCache.defaultCacheFolder(),
                         contentExpiration: TimeInterval = Constants.defaultContentExpirationLength)
    {
        super.init()
        
        cacheFolder = cacheLocation
        contentExpirationLength = contentExpiration
        UUDataCache.createFolderIfNeeded(cacheFolder)
    }
    
    ////////////////////////////////////////////////////////////////////////////
    // UUDataCacheProtocol Implementation
    ////////////////////////////////////////////////////////////////////////////
    public func data(for key: String) -> Data?
    {
        removeIfExpired(for: key)
        
        let cached = loadFromDisk(for: key)
        return cached
    }
    
    public func set(data: Data, for key: String)
    {
        saveToDisk(data: data, for: key)
        
        var md = metaData(for: key)
        md[MetaDataKeys.timestamp] = Date()
        set(metaData: md, for: key)
    }
    
    public func moveIntoCache(localData: URL, for key: String)
    {
        guard let pathUrl = diskCacheURL(for: key) else {
            return
        }
        
        do
        {
            let fm = FileManager.default
            try fm.moveItem(at: localData, to: pathUrl)
            
            var md = metaData(for: key)
            md[MetaDataKeys.timestamp] = Date()
            set(metaData: md, for: key)
        }
        catch (let err)
        {
            UUDebugLog("Error moving URL into cache: %@", String(describing: err))
        }
    }
    
    public func metaData(for key: String) -> [String:Any]
    {
        return UUDataCacheDb.shared.metaData(for: key)
    }
    
    public func set(metaData: [String:Any], for key: String)
    {
        UUDataCacheDb.shared.setMetaData(metaData, for: key)
    }
    
    public func dataExists(for key: String) -> Bool
    {
        return dataExistsOnDisk(key: key)
    }
    
    public func isDataExpired(for key: String) -> Bool
    {
        let md = metaData(for: key)
        let timestamp = md[MetaDataKeys.timestamp] as? Date
        if (timestamp != nil)
        {
            let elapsed = Date().timeIntervalSince(timestamp!)
            return (elapsed > contentExpirationLength)
        }
        
        return false
    }
    
    public func removeData(for key: String)
    {
        UUDataCacheDb.shared.clearMetaData(for: key)
        removeFile(for: key)
    }
    
    public func clearCache()
    {
        let fm = FileManager.default
        
        do
        {
            try fm.removeItem(atPath: cacheFolder)
        }
        catch (let err)
        {
            UUDebugLog("Error creating cache path: %@", String(describing: err))
        }
        
        UUDataCache.createFolderIfNeeded(cacheFolder)
        
        UUDataCacheDb.shared.clearAllMetaData()
    }
    
    public func purgeExpiredData()
    {
        let keys : [String] = listKeys()
        
        for key in keys
        {
            removeIfExpired(for: key)
        }
    }
    
    public func listKeys() -> [String]
    {
        var contents : [String] = []
        
        do
        {
            contents = try FileManager.default.contentsOfDirectory(atPath: cacheFolder)
        }
        catch (_)
        {
            //UUDebugLog("Error fetching contents of directory: %@", String(describing: err))
        }
        
        return contents
    }
    
    public var dataExpirationInterval : TimeInterval
    {
        get
        {
            return contentExpirationLength
        }
        
        set
        {
            contentExpirationLength = newValue
        }
    }
    
    ////////////////////////////////////////////////////////////////////////////
    // Private Implementation
    ////////////////////////////////////////////////////////////////////////////
    public static func defaultCacheFolder() -> String
    {
        let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).last!
        let path = (cachePath as NSString).appendingPathComponent("UUDataCache")
        return path
    }
    
    private static func createFolderIfNeeded(_ folder: String)
    {
        let fm = FileManager.default
        if (!fm.fileExists(atPath: folder))
        {
            do
            {
                try fm.createDirectory(atPath: folder, withIntermediateDirectories: true, attributes: nil)
            }
            catch (let err)
            {
                UUDebugLog("Error creating folder: %@", String(describing: err))
            }
        }
    }
    
    public func diskCacheURL(for key: String) -> URL?
    {
        if let fileName = UUDataCacheDb.shared.fileName(for: key) {
            let path = (cacheFolder as NSString).appendingPathComponent(fileName)
            let pathUrl = URL(fileURLWithPath: path)
            return pathUrl
        }
        
        return nil
    }
    
    private func removeIfExpired(for key: String)
    {
        if (isDataExpired(for: key))
        {
            removeData(for: key)
        }
    }
    
    private func loadFromDisk(for key: String) -> Data?
    {
        var data : Data? = nil
        
        guard let pathUrl = diskCacheURL(for: key) else {
            return nil
        }
        
        do
        {
            data = try Data(contentsOf: pathUrl)
        }
        catch (_)
        {
            //UUDebugLog("Error loading data: %@", String(describing: err))
        }
        
        return data
    }
        
    private func removeFile(for key: String)
    {
        guard let pathUrl = diskCacheURL(for: key) else {
            return
        }
        
        do
        {
            try FileManager.default.removeItem(at: pathUrl)
        }
        catch (_)
        {
            //UUDebugLog("Error removing file: %@", String(describing: err))
        }
    }
    
    private func saveToDisk(data: Data, for key: String)
    {
        guard let pathUrl = diskCacheURL(for: key) else {
            return
        }
        
        do
        {
            try data.write(to: pathUrl, options: .atomic)
        }
        catch (let err)
        {
            UUDebugLog("Error saving data: %@", String(describing: err))
        }
    }
        
    private func dataExistsOnDisk(key: String) -> Bool {
        guard let pathUrl = diskCacheURL(for: key) else {
            return false
        }
        
        return FileManager.default.fileExists(atPath:pathUrl.path)
    }
    
}


private class UUDataCacheDb
{
	private static let cacheKeyName = "UUDataCacheDb"
    static let shared = UUDataCacheDb()
	
    let mutex = NSRecursiveLock()
	var metaData : [String : Any] = [:]
	
	init() {
		if let data = UserDefaults.standard.object(forKey: UUDataCacheDb.cacheKeyName) as? [String : Any] {
            mutex.lock()
            defer {
                mutex.unlock()
            }

            self.metaData = data
		}
	}
    
    public func metaData(for key: String) -> [String:Any]
    {
        mutex.lock()
        defer {
            mutex.unlock()
        }

        if let dictionary = self.metaData[key] as? [String:Any] {
            let copy = dictionary
            return copy
        }
        else {
            var metaData : [String : Any] = [:]
            metaData["fileName"] = UUID().uuidString
            metaData["timestamp"] = Date()
            self.metaData[key] = metaData
                
            let copy = self.metaData
            return copy
        }
        
    }
    
    public func fileName(for key: String) -> String?
    {
        mutex.lock()
        defer {
            mutex.unlock()
        }

        let metaData = self.metaData(for: key)
        return metaData["fileName"] as? String
    }
    
    public func setMetaData(_ metaData: [String:Any], for key: String)
    {
        mutex.lock()
        defer {
            mutex.unlock()
        }

        
        self.metaData[key] = metaData
        self.saveCurrentMetaData()
    }
    
    public func clearMetaData(for key: String)
    {
        mutex.lock()
        defer {
            mutex.unlock()
        }

        self.metaData.removeValue(forKey: key)
        self.saveCurrentMetaData()
    }
    
    public func clearAllMetaData()
    {
        mutex.lock()
        defer {
            mutex.unlock()
        }

		UserDefaults.standard.removeObject(forKey: UUDataCacheDb.cacheKeyName)
        self.metaData = [:]
    }

	private func saveCurrentMetaData() {
        mutex.lock()
        defer {
            mutex.unlock()
        }

        UserDefaults.standard.setValue(self.metaData, forKey: UUDataCacheDb.cacheKeyName)
	}
}



