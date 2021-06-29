//
//  UUThread.swift
//  UUSwift
//
//  Created by Ryan DeVore on 7/12/19.
//

import Darwin
import Foundation

public class UUThreadSafeArray<T:Equatable>: NSObject
{
    private var nativeObject: Array<T> = Array()
    
    public var count: Int
    {
        get
        {
            return uuSynchronized(
            {
                return nativeObject.count
            })
        }
    }
    
    public subscript(index: Int) -> T
    {
        set
        {
            uuSynchronized(
            {
                self.nativeObject[index] = newValue
            })
        }
        
        get
        {
            return uuSynchronized(
            {
                return self.nativeObject[index]
            })
        }
    }
	
	public func contains(_ element: T) -> Bool
	{
		uuSynchronized({
			return self.nativeObject.firstIndex(of: element) != nil
		})
	}
    
    public func remove(_ element: T)
    {
        uuSynchronized({
			while let index = self.nativeObject.firstIndex(of: element) {
				self.nativeObject.remove(at: index)
			}
        })
    }
    
    public func removeAll()
    {
        uuSynchronized(
        {
            self.nativeObject.removeAll()
        })
    }
    
    public func prepend(_ newElement: T)
    {
        uuSynchronized(
        {
            self.nativeObject.insert(newElement, at: 0)
        })
    }
    
    public func append(_ newElement: T)
    {
        uuSynchronized(
        {
            self.nativeObject.append(newElement)
        })
    }
    
    public func removeFirst() -> T
    {
        return uuSynchronized(
        {
            self.nativeObject.removeFirst()
        })
    }
    
    public func removeLast() -> T
    {
        return uuSynchronized(
        {
            self.nativeObject.removeLast()
        })
    }
    
    public func popLast() -> T?
    {
        return uuSynchronized(
        {
            self.nativeObject.popLast()
        })
    }
}

public class UUThreadSafeDictionary<KeyType, ValueType>: NSObject
    where KeyType: Hashable, ValueType: Any
{
    private var nativeObject: Dictionary<KeyType, ValueType> = Dictionary()
    
    public var count: Int
    {
        get
        {
            return uuSynchronized(
            {
                return nativeObject.count
            })
        }
    }
    
    public subscript(key: KeyType) -> ValueType?
    {
        set
        {
            uuSynchronized(
            {
                self.nativeObject[key] = newValue
            })
        }
        
        get
        {
            return uuSynchronized(
            {
                return self.nativeObject[key]
            })
        }
    }
    
    public func removeAll()
    {
        uuSynchronized(
        {
            self.nativeObject.removeAll()
        })
    }
    
    public func removeValue(forKey key: KeyType) -> ValueType?
    {
        return uuSynchronized(
        {
            return self.nativeObject.removeValue(forKey: key)
        })
    }
}

public extension NSObject
{
    func uuThreadMutex() -> UUMutexWrapper
    {
        var mutex: UUMutexWrapper? = uuObject(for: "UUThreadMutex") as? UUMutexWrapper
        if (mutex == nil)
        {
            mutex = UUMutexWrapper()
            uuAttach(object: mutex, for: "UUThreadMutex")
        }
        
        return mutex!
    }
    
    func uuSynchronized<ReturnType>(_ method: () throws -> ReturnType) rethrows -> ReturnType
    {
        let mutex = uuThreadMutex()
        return try mutex.synchronized(method)
    }
}

public class UUMutexWrapper: NSObject
{
    private var mutex = NSRecursiveLock()

	public func synchronized<ReturnType>(_ method: () throws -> ReturnType) rethrows -> ReturnType
	{
        mutex.lock()

		defer
		{
            mutex.unlock()
		}
		
		return try method()
	}
}


