//
//  UUCoreBluetoothProvider.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 5/10/25.
//

import Foundation
import UUSwiftCore

public class UUCoreBluetoothProvider: UUBluetoothProvider
{
    private let LOG_TAG = "UUCoreBluetoothProvider"
    
    private var _centralManager: UUCentralManager? = nil
    private var _scanner: UUPeripheralScanner? = nil
    private var _config: UUBluetoothConfig? = nil
    
    public var config: UUBluetoothConfig
    {
        if let cfg = _config
        {
            return cfg
        }
        
        let defaultConfig = UUBluetoothConfig()
        _config = defaultConfig
        return defaultConfig
    }
        
    
    public init()
    {
        
    }
    
    public func initialize(config: UUBluetoothConfig)
    {
        if (_config != nil)
        {
            UULog.warn(tag: LOG_TAG, message: "Library already initialized")
            return
        }
        
        _config = config
        
        // Just access the computed property create the CBCentralManager and force the OS
        // to prompt for permissions if needed
        _ = centralManager
    }
    
    public var centralManager: UUCentralManager
    {
        if let central = _centralManager
        {
            return central
        }
        
        let defaultCentral = UUCentralManager(options: self.config.centralOptions)
        _centralManager = defaultCentral
        return defaultCentral
    }
    
    public var managerStateMonitor: any UUManagerStateMonitor
    {
        return centralManager
    }
    
    public var scanner: UUPeripheralScanner
    {
        if let scanner = _scanner
        {
            return scanner
        }
        
        let defaultScanner = UUCoreBluetoothPeripheralScanner(centralManager: centralManager)
        _scanner = defaultScanner
        return defaultScanner
    }
}
