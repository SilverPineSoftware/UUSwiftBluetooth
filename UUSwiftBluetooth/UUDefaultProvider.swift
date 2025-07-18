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
