//
//  UURemoteImage.swift
//  Useful Utilities - An extension to Useful Utilities
//  UURemoteData that exposes the cached data as UIImage/NSImage objects
//
//	License:
//  You are free to use this code for whatever purposes you desire.
//  The only requirement is that you smile everytime you use it.
//
//  NOTE: This class depends on the following toolbox classes:
//
//  UUHttpSession
//  UUDataCache
//  UURemoteData
//
#if os(macOS)
	import AppKit
	public typealias UUImage = NSImage
#else
	import UIKit
	public typealias UUImage = UIImage
#endif

public typealias UUImageLoadedCompletionBlock = (UUImage?, Error?) -> Void


public class UURemoteImage: NSObject
{
    public struct Notifications
    {
        public static let ImageDownloaded = Notification.Name("UUImageDownloadedNotification")
    }
    
    public static let shared = UURemoteImage()

    public func imageSize(for path: String) -> CGSize?
    {
        let md = UUDataCache.shared.metaData(for: path)
        return md[MetaData.ImageSize] as? CGSize
    }
    
    public func clearCache()
    {
        systemImageCache.removeAllObjects()
    }
    
    public func local(_ path : String) -> Bool
    {
        if let _ = self.systemImageCache.object(forKey: path as NSString)
        {
            return true
        }
        if UUDataCache.shared.doesDataExist(for: path)
        {
            return true
        }
        
        return false
    }

    public func image(for path : String, remoteLoadCompletion : UUImageLoadedCompletionBlock? = nil) -> UUImage?
    {
        // Check the local cache...
        if let image = self.systemImageCache.object(forKey: path as NSString) as? UUImage
        {
            return image
        }
        else
        {
            let data = UURemoteData.shared.data(for: path)
            { (data, error) in
                
                let image = self.processData(path, data: data)
                remoteLoadCompletion?(image, error)
            }
            
            let image = processData(path, data: data)
            return image
        }
    }
    
    private func processData(_ path: String, data: Data?) -> UUImage?
    {
        var image : UUImage? = nil
        
        if let imageData = data
        {
            image = UUImage(data: imageData)
            if let img = image
            {
                self.systemImageCache.setObject(img, forKey: path as NSString)
                
                var md = UUDataCache.shared.metaData(for: path)
                md[MetaData.ImageSize] = img.size
                UUDataCache.shared.set(metaData: md, for: path)
                
                var metaData : [String:Any] = [:]
                metaData[UURemoteData.NotificationKeys.RemotePath] = path
                notifyImageDownloaded(metaData: metaData)
            }
        }
        
        return image
    }
    
    private func notifyImageDownloaded(metaData: [String:Any])
    {
        DispatchQueue.main.async
        {
            NotificationCenter.default.post(name: Notifications.ImageDownloaded, object: nil, userInfo: metaData)
        }
    }
    
    ////////////////////////////////////////////////////////////////////////////
    // Private implementation
    ////////////////////////////////////////////////////////////////////////////
    private let systemImageCache = NSCache<AnyObject, AnyObject>()
    
    private struct MetaData
    {
        static let ImageSize = "ImageSize"
    }

}
