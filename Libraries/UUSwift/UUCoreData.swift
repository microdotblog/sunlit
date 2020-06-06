//  UUCoreData
//  Useful Utilities - Helpful methods for Core Data
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

open class UUCoreData: NSObject
{
    public var mainThreadContext : NSManagedObjectContext?
    public var storeCoordinator : NSPersistentStoreCoordinator?
    
    public override init()
    {
        super.init()
    }
    
    public init(url: URL, modelDefinitionBundle: Bundle = Bundle.main)
    {
        super.init()
        configure(url: url, modelDefinitionBundle: modelDefinitionBundle)
    }
    
    public init(url: URL, model: NSManagedObjectModel)
    {
        super.init()
        configure(url: url, model: model)
    }
    
    private func configure(url: URL, modelDefinitionBundle: Bundle = Bundle.main)
    {
        let mom : NSManagedObjectModel? = NSManagedObjectModel.mergedModel(from: [modelDefinitionBundle])
        if (mom == nil)
        {
            UUDebugLog("WARNING! Unable to create managed object model!")
            return
        }
        
        configure(url: url, model: mom!)
    }
    
    private func configure(url: URL, model: NSManagedObjectModel)
    {
        let options : [AnyHashable:Any] =
        [
            NSMigratePersistentStoresAutomaticallyOption : true,
            NSInferredMappingModelError: true
        ]
        
        storeCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        
        do
        {
            try storeCoordinator?.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: options)
        }
        catch (let err)
        {
            UUDebugLog("Error setting up CoreData: %@", String(describing: err))
            
            do
            {
                try FileManager.default.removeItem(at: url)
                
                try storeCoordinator?.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: options)
            }
            catch (let innerError)
            {
                UUDebugLog("Error Clearing CoreData: %@", String(describing: innerError))
            }
        }
        
        mainThreadContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        mainThreadContext?.persistentStoreCoordinator = storeCoordinator
        
        NotificationCenter.default.addObserver(self, selector: #selector(otherContextDidSave), name: NSNotification.Name.NSManagedObjectContextDidSave, object: nil)
    }
    
    func shutdown()
    {
        mainThreadContext = nil
        storeCoordinator = nil
    }
    
    @objc public func otherContextDidSave(notification: Notification)
    {
        let destContext : NSManagedObjectContext? = mainThreadContext
        
        if (destContext != nil)
        {
            let savedContext : NSManagedObjectContext? = notification.object as? NSManagedObjectContext
            if (savedContext != nil)
            {
                if (savedContext != destContext && savedContext!.persistentStoreCoordinator == mainThreadContext!.persistentStoreCoordinator)
                {
                    destContext!.perform
                    {
                        UUDebugLog("Merging changes from background context")
                        destContext!.mergeChanges(fromContextDidSave: notification)
                    }
                }
            }
        }
    }
    
    public func workerThreadContext() -> NSManagedObjectContext
    {
        let moc : NSManagedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        moc.persistentStoreCoordinator = storeCoordinator
        return moc
    }
}

public extension NSManagedObjectContext
{
    func uuSubmitChanges() -> Error?
    {
        var error: Error? = nil
        
        performAndWait
        {
            if (hasChanges)
            {
                do
                {
                    try self.save()
                }
                catch (let err)
                {
                    error = err
                    UUDebugLog("Error saving core data: %@", String(describing: err))
                }
            }
        }
        
        return error
    }
    
    func uuDeleteObjects(_ list: [Any])
    {
        performAndWait
        {
            for obj in list
            {
                if (obj is NSManagedObject)
                {
                    self.delete(obj as! NSManagedObject)
                }
            }
        }
    }
    
    func uuDeleteAllObjects()
    {
        performAndWait
        {
            let entityList = self.persistentStoreCoordinator?.managedObjectModel.entitiesByName
            
            for entity in entityList!
            {
                let fr = NSFetchRequest<NSFetchRequestResult>()
                fr.entity = NSEntityDescription.entity(forEntityName: entity.key, in: self)
                
                do
                {
                    let objects = try self.fetch(fr)
                    for obj in objects
                    {
                        if (obj is NSManagedObject)
                        {
                            self.delete(obj as! NSManagedObject)
                        }
                    }
                }
                catch (let err)
                {
                    UUDebugLog("Error deleting all objects: %@", String(describing: err))
                }
            }
        }
    }
}

public extension NSError
{
    func uuLogDetailedErrors()
    {
        UUDebugLog("ERROR: %@", localizedDescription)
        
        let detailedErrors = userInfo[NSDetailedErrorsKey] as? [NSError]
        if (detailedErrors != nil)
        {
            for de in detailedErrors!
            {
                UUDebugLog("  DetailedError: %@", de.userInfo)
            }
        }
        else
        {
            UUDebugLog("  %@", userInfo)
        }
    }
}

public extension NSManagedObject
{
    static var uuEntityName : String
    {
        return String(describing: self)
    }
    
    static func uuFetchRequest(
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor]? = nil,
        offset: Int? = nil,
        limit: Int? = nil,
        context: NSManagedObjectContext) -> NSFetchRequest<NSFetchRequestResult>
    {
        let fr = NSFetchRequest<NSFetchRequestResult>()
        fr.entity = NSEntityDescription.entity(forEntityName: uuEntityName, in: context)
        fr.sortDescriptors = sortDescriptors
        fr.predicate = predicate
        
        if (offset != nil)
        {
            fr.fetchOffset = offset!
        }
        
        if (limit != nil)
        {
            fr.fetchLimit = limit!
        }
        
        return fr
    }
    
    static func uuFetchObjects(
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor]? = nil,
        offset: Int? = nil,
        limit: Int? = nil,
        context: NSManagedObjectContext) -> [Any]
    {
        let fr = uuFetchRequest(predicate: predicate, sortDescriptors: sortDescriptors, offset: offset, limit: limit, context: context)
        return uuExecuteFetch(fetchRequest: fr, context: context)
    }
    
    static func uuFetchDictionaries(
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor]? = nil,
        propertiesToFetch: [Any]? = nil,
        offset: Int? = nil,
        limit: Int? = nil,
        distinct: Bool? = nil,
        context: NSManagedObjectContext) -> [[AnyHashable:Any]]
    {
        let fr = uuFetchRequest(predicate: predicate, sortDescriptors: sortDescriptors, offset: offset, limit: limit, context: context)
        fr.resultType = .dictionaryResultType
        fr.propertiesToFetch = propertiesToFetch
        
        if let queryDistinct = distinct
        {
            fr.returnsDistinctResults = queryDistinct
        }
        
        guard let result = uuExecuteFetch(fetchRequest: fr, context: context) as? [[AnyHashable:Any]] else
        {
            return []
        }
        
        return result
    }
    
    static func uuFetchSingleColumnString(
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor]? = nil,
        propertyToFetch: String,
        offset: Int? = nil,
        limit: Int? = nil,
        distinct: Bool? = nil,
        context: NSManagedObjectContext) -> [String]
    {
        let fetchResults = uuFetchDictionaries(predicate: predicate, sortDescriptors: sortDescriptors, propertiesToFetch: [propertyToFetch], offset: offset, limit: limit, distinct: distinct, context: context)
        
        var results : [String] = []
        for d in fetchResults
        {
            if let val = d[propertyToFetch] as? String
            {
                results.append(val)
            }
        }
        
        return results
    }
    
    static func uuExecuteFetch(
        fetchRequest: NSFetchRequest<NSFetchRequestResult>,
        context: NSManagedObjectContext) -> [Any]
    {
        var results : [Any] = []
        
        context.performAndWait
        {
            do
            {
                results = try context.fetch(fetchRequest)
            }
            catch (let err)
            {
                (err as NSError).uuLogDetailedErrors()
                results = []
            }
        }
        
        return results
    }
    
    class func uuFetchSingleObject(
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor]? = nil,
        context: NSManagedObjectContext) -> Self?
    {
        return uuFetchSingleObjectInternal(predicate: predicate,  sortDescriptors: sortDescriptors, context: context)
    }
    
    class func uuFetchSingleDictionary(
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor]? = nil,
        propertiesToFetch: [Any]? = nil,
        context: NSManagedObjectContext) -> [AnyHashable:Any]?
    {
        let list = uuFetchDictionaries(predicate: predicate, sortDescriptors: sortDescriptors, propertiesToFetch: propertiesToFetch, offset: nil, limit: 1, context: context)
        
        var single : [AnyHashable:Any]? = nil
        
        if (list.count > 0)
        {
            single = list[0]
        }
        
        return single
    }
    
    private class func uuFetchSingleObjectInternal<T>(
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor]? = nil,
        context: NSManagedObjectContext) -> T?
    {
        let list = uuFetchObjects(predicate: predicate, sortDescriptors: sortDescriptors, offset: nil, limit: 1, context: context)
        
        var single : Any? = nil
        
        if (list.count > 0)
        {
            single = list[0]
        }
        
        return single as? T
    }
    
    static func uuFetchOrCreate(
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor]? = nil,
        context: NSManagedObjectContext) -> Self
    {
        var obj = uuFetchSingleObject(predicate: predicate, sortDescriptors: sortDescriptors, context: context)
        
        context.performAndWait
        {
            if (obj == nil)
            {
                obj = uuCreate(context: context)
            }
        }
        
        return obj!
    }
    
    class func uuCreate(
        context: NSManagedObjectContext) -> Self
    {
        return uuCreateInternal(context: context)
    }
    
    class func uuCreateAndFill(
        context: NSManagedObjectContext, dictionary: [AnyHashable:Any]? = nil) -> Self
    {
        let obj = uuCreate(context: context)
        
        if let d = dictionary
        {
            obj.uuFill(from: d, context: context)
        }
        
        return obj
    }
    
    class func uuCreateAndFillMultiple(
        context: NSManagedObjectContext, dictionaryArray: [[AnyHashable:Any]]) -> [NSManagedObject]
    {
        var list: [NSManagedObject] = []
        
        for d in dictionaryArray
        {
            let obj = uuCreateAndFill(context: context, dictionary: d)
            list.append(obj)
        }
        
        return list
    }
    
    private class func uuCreateInternal<T>(context: NSManagedObjectContext) -> T
    {
        var obj : T? = nil
        
        context.performAndWait
        {
            obj = NSEntityDescription.insertNewObject(forEntityName: uuEntityName, into: context) as? T
        }
        
        return obj!
        
    }
    
    static func uuDeleteObjects(
        predicate: NSPredicate? = nil,
        context: NSManagedObjectContext)
    {
        context.performAndWait
        {
            let fr = uuFetchRequest(predicate: predicate, sortDescriptors: nil, offset: nil, limit: nil, context: context)
            fr.includesPropertyValues = false
            
            let list = uuExecuteFetch(fetchRequest: fr, context: context)
            
            for obj in list
            {
                if (obj is NSManagedObject)
                {
                    context.delete(obj as! NSManagedObject)
                }
            }
        }
    }
    
    /*
    public static func uuBatchDeleteObjects(
        predicate: NSPredicate? = nil,
        context: NSManagedObjectContext)
    {
        context.performAndWait
            {
                if #available(iOS 9.0, *)
                {
                    let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: uuEntityName)
                    fetch.predicate = predicate
                    
                    let request = NSBatchDeleteRequest(fetchRequest: fetch)
                    request.resultType = NSBatchDeleteRequestResultType.resultTypeObjectIDs
                    
                    do
                    {
                        if let result = try context.execute(request) as? NSBatchDeleteResult
                        {
                            if let deletedObjectIds = result.result as? [NSManagedObjectID]
                            {
                                UUDebugLog("Deleted Object IDS: \(deletedObjectIds)")
                            }
                        }
                    }
                    catch let err
                    {
                        (err as NSError).uuLogDetailedErrors()
                    }
                }
                else
                {
                    let list = uuFetchObjects(predicate: predicate, context: context)
                    
                    for obj in list
                    {
                        if (obj is NSManagedObject)
                        {
                            context.delete(obj as! NSManagedObject)
                        }
                    }
                }
        }
    }*/
    
    static func uuCountObjects(
        predicate: NSPredicate? = nil,
        context: NSManagedObjectContext) -> Int
    {
        let fr = uuFetchRequest(predicate: predicate, context: context)
        
        var count : Int = 0
        
        context.performAndWait
        {
            do
            {
                count = try context.count(for: fr)
            }
            catch (let err)
            {
                (err as NSError).uuLogDetailedErrors()
            }
        }
        
        return count
    }
    
    static func uuLogTable(
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor]? = nil,
        offset: Int? = nil,
        limit: Int? = nil,
        context: NSManagedObjectContext,
        logMessage: String = "")
    {
#if DEBUG
        UUDebugLog("Log Table -- \(uuEntityName) -- \(logMessage)")
        
        let list = uuFetchObjects(predicate: predicate, sortDescriptors: sortDescriptors, offset: offset, limit: limit, context: context)
        
        UUDebugLog("There are \(list.count) records in \(uuEntityName) table")
        
        var i = 0
        for o in list
        {
            if let odbg = o as? CustomDebugStringConvertible
            {
                UUDebugLog("\(uuEntityName)-\(i): \(odbg.debugDescription)")
            }
            else
            {
                UUDebugLog("\(uuEntityName)-\(i): \(o)")
            }
            
            i = i + 1
        }
#endif
    }
    
    private func getString(_ dictionary: [AnyHashable:Any], _ key: String) -> String?
    {
        var result = dictionary.uuSafeGetString(key)
        
        if (result == nil)
        {
            result = dictionary.uuSafeGetString(key.uuToSnakeCase())
        }
        
        return result
    }
    
    private func getNumber(_ dictionary: [AnyHashable:Any], _ key: String) -> NSNumber?
    {
        var result = dictionary.uuSafeGetNumber(key)
        
        if (result == nil)
        {
            result = dictionary.uuSafeGetNumber(key.uuToSnakeCase())
        }
        
        return result
    }
    
    
    func uuFill(from dictionary: [AnyHashable:Any], context: Any?)
    {
        guard let ctx = context as? NSManagedObjectContext else
        {
            return
        }
        
        ctx.performAndWait
        {
            for attr in entity.attributesByName
            {
                //UUDebugLog("Attribute: \(attr.key) ==> \(attr.value)")
                
                switch (attr.value.attributeType)
                {
                    case .stringAttributeType:
                        
                        let strValue = self.getString(dictionary, attr.key)
                        //UUDebugLog("Found String for \(attr.key): \(strValue ?? "null")")
                        setValue(strValue, forKey: attr.key)
                    
                    case .integer16AttributeType,
                         .integer32AttributeType,
                         .integer64AttributeType,
                         .floatAttributeType,
                         .doubleAttributeType,
                         .booleanAttributeType:
                        
                        let numValue = self.getNumber(dictionary, attr.key)
                        //UUDebugLog("Found Number for \(attr.key): \(String(describing: numValue))")
                        setValue(numValue, forKey: attr.key)
                    
                    case .dateAttributeType:
                        
                        var dateValue: Date? = nil
                        let strValue = self.getString(dictionary, attr.key)
                        
                        if (strValue != nil)
                        {
                            let df = DateFormatter.uuCachedFormatter(UUDate.Formats.iso8601DateTime, timeZone: UUDate.TimeZones.utc, locale: Locale.uuEnUSPosix)
                            dateValue = df.date(from: strValue!)
                        }
                        
                        setValue(dateValue, forKey: attr.key)
                        //UUDebugLog("Found Date for \(attr.key): \(strValue ?? "null")")
                    
                    default:
                        UUDebugLog("Skipping \(attr.key)")
                }
                    
                    
                    /*
                     case undefinedAttributeType
                     
                     case integer16AttributeType
                     
                     case integer32AttributeType
                     
                     case integer64AttributeType
                     
                     case decimalAttributeType
                     
                     case doubleAttributeType
                     
                     case floatAttributeType
                     
                     case stringAttributeType
                     
                     case booleanAttributeType
                     
                     case dateAttributeType
                     
                     case binaryDataAttributeType
                     
                     @available(iOS 11.0, *)
                     case UUIDAttributeType
                     
                     @available(iOS 11.0, *)
                     case URIAttributeType
                     
                     @available(iOS 3.0, *)
                     case transformableAttributeType // If your attribute is of NSTransformableAttributeType, the attributeValueClassName must be set or attribute value class must implement NSCopying.
                     
                     @available(iOS 3.0, *)
                     case objectIDAttributeType*/
            }
            
            customFill(from: dictionary, context: context)
            
            for rel in entity.relationshipsByName
            {
                //UUDebugLog("Relationship: \(rel.key) ==> \(rel.value)")
                
                if let destEntity = rel.value.destinationEntity,
                    let destEntityName = destEntity.name
                {
                    if (rel.value.isToMany)
                    {
                        if let dictionaryArray = dictionary.uuSafeGetDictionaryArray(rel.key)
                        {
                            var relSet : Set<NSManagedObject> = Set()
                            
                            for d in dictionaryArray
                            {
                                let relObj = NSEntityDescription.insertNewObject(forEntityName: destEntityName, into: ctx)
                                relObj.uuFill(from: d, context: ctx)
                                relSet.insert(relObj)
                            }
                            
                            setValue(relSet, forKey: rel.key)
                        }
                    }
                    else
                    {
                        if let d = dictionary.uuSafeGetDictionary(rel.key)
                        {
                            let relObj = NSEntityDescription.insertNewObject(forEntityName: destEntityName, into: ctx)
                            relObj.uuFill(from: d, context: ctx)
                            setValue(relObj, forKey: rel.key)
                        }
                    }
                }
            }
        }
    }
    
    private func customFill(from dictionary: [AnyHashable:Any], context: Any?)
    {
        if let mappableObject = self as? UUObjectMapping
        {
            mappableObject.uuMapFromDictionary(dictionary: dictionary, context: context)
        }
    }
}


public extension UUCoreData
{
    private static var sharedStore : UUCoreData? = nil
    
    static func configure(url: URL, modelDefinitionBundle: Bundle = Bundle.main)
    {
        sharedStore = UUCoreData(url: url, modelDefinitionBundle: modelDefinitionBundle)
    }
    
    static var shared : UUCoreData?
    {
        return sharedStore
    }
    
    static var mainThreadContext: NSManagedObjectContext?
    {
        return shared?.mainThreadContext
    }
    
    static func workerThreadContext() -> NSManagedObjectContext?
    {
        return shared?.workerThreadContext()
    }
    
    static func destroyStore(at url: URL)
    {
        do
        {
            try FileManager.default.removeItem(at: url)
        }
        catch (let err)
        {
            UUDebugLog("Error deleting store file: \(err)")
        }
        
        shared?.shutdown()
    }
}

