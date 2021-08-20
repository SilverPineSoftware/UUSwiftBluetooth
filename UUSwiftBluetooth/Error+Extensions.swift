//
//  Error+Extensions.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 8/13/21.
//

import UIKit
import CoreBluetooth
import UUSwiftCore

public let kUUCoreBluetoothErrorDomain = "UUCoreBluetoothErrorDomain"

extension NSError
{
    static func uuCoreBluetoothError(_ errorCode: UUCoreBluetoothErrorCode) -> NSError
    {
        return uuCoreBluetoothError(errorCode, userInfo: nil)
    }
    
    static func uuCoreBluetoothError(_ errorCode: UUCoreBluetoothErrorCode, inner: NSError) -> NSError
    {
        return uuCoreBluetoothError(errorCode, userInfo: [ NSUnderlyingErrorKey: inner ])
    }
    
    static func uuCoreBluetoothError(_ errorCode: UUCoreBluetoothErrorCode, userInfo: [String:Any]?) -> NSError
    {
        var md: [String:Any] = [:]
        md[NSLocalizedDescriptionKey] = errorCode.errorDescription
        md[NSLocalizedRecoverySuggestionErrorKey] = errorCode.recoverySuggestion
        
        if let extra = userInfo
        {
            for e in extra
            {
                md[e.key] = e.value
            }
        }
        
        return NSError(domain: "doo", code: errorCode.rawValue, userInfo: md)
    }
    
    
    static func uuOperationCompleteError(_ error: NSError?)  -> NSError?
    {
        guard let err = error else
        {
            return nil
        }
        
        if (kUUCoreBluetoothErrorDomain == err.domain)
        {
            return error
        }
        
        return uuCoreBluetoothError(.operationFailed, inner: err)
    }

    static func uuConnectionFailedError(_ error: NSError?) -> NSError?
    {
        guard let err = error else
        {
            return nil
        }
        
        return uuCoreBluetoothError(.connectionFailed, inner: err)
    }

    static func uuDisconnectedError(_ error: NSError?) -> NSError?
    {
        guard let err = error else
        {
            return nil
        }
        
        return uuCoreBluetoothError(.disconnected, inner: err)
    }

    static func uuInvalidParamError(_ param: String, _ reason: String) -> NSError
    {
        var md: [String:AnyHashable] = [:]
        md["param"] = param
        md["reason"] = reason
        
        return uuCoreBluetoothError(.invalidParam, userInfo: md)
    }

    static func uuExpectNonNilParamError(_ param: String) -> NSError
    {
        let reason = "\(param) must not be nil."
        return uuInvalidParamError(param, reason)
    }
}

