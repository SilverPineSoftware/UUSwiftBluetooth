//
//  UUBluetoothProvider.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 5/10/25.
//

import Foundation
import CoreBluetooth

/// A provider interface for Core Bluetooth functionality.
/// Conforming types supply initialization, state monitoring, and scanning capabilities.
public protocol UUBluetoothProvider
{
    /// Sets up the Bluetooth stack, including the central manager and related services.
    func initialize()
    
    /// The central manager responsible for discovering and connecting to BLE peripherals.
    var centralManager: UUCentralManager { get }
    
    /// Observes and reports changes to the Bluetooth manager’s state.
    var managerStateMonitor: UUManagerStateMonitor { get }
    
    /// Scans for and manages discovered Bluetooth peripherals.
    var scanner: UUPeripheralScanner { get }
    
    /// The current authorization status
    var authorizationStatus: CBManagerAuthorization { get }
}

public extension UUBluetoothProvider
{
    /// Default implementation retrieving the current authorization status from CoreBluetooth.
    var authorizationStatus: CBManagerAuthorization
    {
        return CBCentralManager.authorization
    }
}
