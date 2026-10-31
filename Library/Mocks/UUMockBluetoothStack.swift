//
//  UUMockBluetoothStack.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 10/31/26.
//

#if DEBUG

import Foundation
import CoreBluetooth

///
/// Non Functional Bluetooth stack for use in building out mocked objects for Swift UI previews
///
public class UUMockBluetoothStack: UUBluetoothStack
{
    public required init(configuration: UUBluetoothConfiguration = UUBluetoothConfiguration())
    {
        self.configuration = configuration
        
        let central = UUCentralManager.mocked()
        centralManager = central
        managerStateMonitor = central
        scanner = UUMockPeripheralScanner()
    }
    
    public func initialize()
    {
    }
    
    public var configuration: UUBluetoothConfiguration
    
    public var centralManager: UUCentralManager
    
    public var managerStateMonitor: UUManagerStateMonitor
    
    public var scanner: UUPeripheralScanner
    
    public var authorizationStatus: CBManagerAuthorization = .allowedAlways
}

#endif
