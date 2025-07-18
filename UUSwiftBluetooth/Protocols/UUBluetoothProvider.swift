//
//  UUBluetoothProvider.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 5/10/25.
//

import Foundation

public protocol UUBluetoothProvider
{
    func initialize()
    
    var centralManager: UUCentralManager { get }
    var managerStateMonitor: UUManagerStateMonitor { get }
    var scanner: UUPeripheralScanner { get }
}
