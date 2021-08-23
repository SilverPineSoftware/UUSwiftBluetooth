//
//  UUCentralManagerFactory.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 8/22/21.
//

import UIKit
import CoreBluetooth
import UUSwiftCore

class UUCentralManagerFactory
{
    private static var _sharedCentralManager: UUCentralManager? = nil
    private static var _sharedCentralManagerInitOptions: [String:Any]? = nil
    
    
    private static func defaultOptions() -> [String:Any]
    {
        var md: [String:Any] = [:]
        md[CBCentralManagerOptionShowPowerAlertKey] = false
        return md
    }
    
    public static var sharedCentralManager: UUCentralManager
    {
        if (_sharedCentralManager == nil)
        {
            let opts = _sharedCentralManagerInitOptions ?? defaultOptions()
            _sharedCentralManager = UUCentralManager(opts)
        }
        
        return _sharedCentralManager!
    }
    
    public static func setSharedCentralManagerInitOptions(_ options: [String:Any]?)
    {
        let existingOptions = _sharedCentralManagerInitOptions
        
        _sharedCentralManagerInitOptions = options
        
        if (_sharedCentralManager != nil)
        {
            let existingRestoreId = existingOptions?.uuSafeGetString(CBCentralManagerOptionRestoreIdentifierKey) ?? ""
            let incomingRestoreId = options?.uuSafeGetString(CBCentralManagerOptionRestoreIdentifierKey) ?? ""
            if (existingRestoreId != incomingRestoreId)
            {
                NSLog("UUCoreBluetooth init options have changed! Setting theSharedInstance to nil");
                _sharedCentralManager = nil
            }
        }
    }

}
