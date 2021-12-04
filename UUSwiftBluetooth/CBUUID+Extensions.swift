//
//  CBUUID+Extensions.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 8/17/21.
//

import UIKit
import CoreBluetooth
import UUSwiftCore


fileprivate var uuCommonNameMap: [String:String] = [:]
fileprivate let uuCommonNameMapLock = NSRecursiveLock()

public extension CBUUID
{
    // Some UUID's have a common name, if UUIDString does not match, it is returned,
    // otherwise 'Unknown'.
    var uuCommonName: String
    {
        let name = "\(self)"
        if (name == uuidString)
        {
            if let registeredName = uuGetMappedCommonName()
            {
                return registeredName
            }
            
            return "Unknown"
        }
        else
        {
            return name
        }
    }
    
    static func uuRegisterCommonName(_ name: String, _ uuid: CBUUID)
    {
        defer { uuCommonNameMapLock.unlock() }
        uuCommonNameMapLock.lock()
        
        uuCommonNameMap[uuid.uuidString] = name
    }

    fileprivate func uuGetMappedCommonName() -> String?
    {
        defer { uuCommonNameMapLock.unlock() }
        uuCommonNameMapLock.lock()
        
        return uuCommonNameMap[uuidString]
    }
}

