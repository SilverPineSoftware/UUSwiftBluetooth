//
//  UUDefaultProvider.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 5/10/25.
//

import Foundation

public class UUDefaultProvider: UUBluetoothProvider
{
    private lazy var _centralManager = UUCentralManager.shared
    private lazy var _scanner: UUPeripheralScanner = UUCoreBluetoothPeripheralScanner(centralManager: _centralManager)
    
    public init()
    {
        
    }
    
    public func initialize()
    {
        // Just access the lazy var to create the CBCentralManager and force the OS to prompt for permissions if needed
        _ = _centralManager
    }
    
    public var centralManager: UUCentralManager
    {
        return _centralManager
    }
    
    public var managerStateMonitor: any UUManagerStateMonitor
    {
        return _centralManager
    }
    
    public var scanner: UUPeripheralScanner
    {
        return _scanner
    }
}
