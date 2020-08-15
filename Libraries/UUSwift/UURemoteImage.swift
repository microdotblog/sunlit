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
        
        if let w = md[MetaData.ImageWidth] as? NSNumber,
           let h = md[MetaData.ImageHeight] as? NSNumber
        {
            return CGSize(width: CGFloat(w.floatValue), height: CGFloat(h.floatValue))
        }
        
        return nil
    }
    
    public func clearCache()
    {
        self.systemImageCache.removeAllObjects()
    }
    
    public func isDownloaded( for key: String) -> Bool
    {
        if self.systemImageCache.object(forKey: key as NSString) != nil {
            return true
        }
        
        return UUDataCache.shared.dataExists(for: key)
    }
    
    public func image(for key: String) -> UUImage?
    {
        return image(for: key, remoteLoadCompletion: nil)
    }
    
    public func image(for key: String, remoteLoadCompletion: UUImageLoadedCompletionBlock? = nil) -> UUImage?
    {
        if let image = self.systemImageCache.object(forKey: key as NSString)
        {
            return image
        }
        else {
            let data = UURemoteData.shared.data(for: key, remoteLoadCompletion:
            { (data, error) in
                let image = self.processImageData(for: key, data: data)
                
                if let completion = remoteLoadCompletion {
                    completion(image, error)
                }
            })
            
            if let imageData = data
            {
                let image = self.processImageData(for: key, data: imageData)
                return image
            }
        }
        
        return nil
    }

    private func processImageData(for key: String, data : Data?) -> UUImage?
    {
        if let imageData = data, let image = UUImage(data: imageData)
        {
            self.systemImageCache.setObject(image, forKey: key as NSString)
            
            var md = UUDataCache.shared.metaData(for: key)
            md[MetaData.ImageWidth] = NSNumber(value: Float(image.size.width))
            md[MetaData.ImageHeight] = NSNumber(value: Float(image.size.height))
            UUDataCache.shared.set(metaData: md, for: key)

            var metaData : [String:Any] = [:]
            metaData[UURemoteData.NotificationKeys.RemotePath] = key
            self.notifyImageDownloaded(metaData: metaData)
            
            return image
        }
        
        return nil
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
    private let systemImageCache = NSCache<NSString, UUImage>()
    
    private struct MetaData
    {
        static let ImageWidth = "ImageWidth"
        static let ImageHeight = "ImageHeight"
    }

}
