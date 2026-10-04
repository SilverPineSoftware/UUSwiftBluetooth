//
//  UUCoreBluetoothProvider.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 5/10/25.
//

import Foundation

public class UUCoreBluetoothProvider: UUBluetoothProvider
{
    //private lazy var _centralManager = UUCentralManager.shared
    private var _centralManager: UUCentralManager!
    
    private lazy var _scanner: UUPeripheralScanner =
    {
        UUCoreBluetoothPeripheralScanner(centralManager: _centralManager)
    }()
    
    public init()
    {
        
    }
    
    public func initialize(config: UUBluetoothConfig)
    {
        // Just access the lazy var to create the CBCentralManager and force the OS to prompt for permissions if needed
        //_ = _centralManager
        _centralManager = UUCentralManager(options: config.centralOptions)
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
