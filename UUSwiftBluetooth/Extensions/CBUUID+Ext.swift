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
fileprivate let kUnknownName = "Unknown"

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
            
            return kUnknownName
        }
        else
        {
            return name
        }
    }
    
    static func uuCreate(from uuidString: String?) -> CBUUID?
    {
        guard let uuid = uuidString else
        {
            return nil
        }
        
        // If the input is a valid 4 digit hex string, return
        if uuid.count == 4 && uuid.uuToHexData() != nil
        {
            return CBUUID(string: uuid)
        }
        
        guard UUID(uuidString: uuid) != nil else
        {
            return nil
        }
        
        return CBUUID(string: uuid)
    }
    
    fileprivate func uuGetMappedCommonName() -> String?
    {
        defer { uuCommonNameMapLock.unlock() }
        uuCommonNameMapLock.lock()
        
        return uuCommonNameMap[uuidString]
    }
}

public extension UUCoreBluetooth
{
    static func register(commonName: String?, for uuidString: String?)
    {
        guard   let name = commonName,
                let uuid = uuidString,
                name != kUnknownName,
                let cbuuid = CBUUID.uuCreate(from: uuid),
                cbuuid.description != name else
        {
            return
        }
        
        defer { uuCommonNameMapLock.unlock() }
        uuCommonNameMapLock.lock()
        
        uuCommonNameMap[uuid] = name
    }
    
    static var mappedCommonNames: [String:String]
    {
        defer { uuCommonNameMapLock.unlock() }
        uuCommonNameMapLock.lock()
        
        return uuCommonNameMap
    }
}

