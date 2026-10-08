//
//  UUBluetoothStack.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 5/10/25.
//

import Foundation
import CoreBluetooth

/// A configured Bluetooth runtime that provides access to central management, state monitoring, and scanning.
///
/// Create a stack with its startup configuration, then call ``initialize()`` when the app is ready
/// to begin Bluetooth work. This creates the central manager and may cause the system to present
/// its Bluetooth authorization prompt if authorization has not yet been determined. Accessing
/// ``centralManager``, ``managerStateMonitor``, or ``scanner`` before calling ``initialize()`` may
/// create the central manager and cause the same prompt.
public protocol UUBluetoothStack
{
    /// Creates a stack with its startup configuration.
    ///
    /// Stack construction stores the configuration but does not itself create the central manager.
    /// - Parameter configuration: The options to use when creating the central manager.
    init(configuration: UUBluetoothConfiguration)
    
    /// Creates the central manager before it is otherwise needed.
    ///
    /// Call this when the app is ready to begin Bluetooth work. Creating the manager may cause
    /// the system to present its Bluetooth authorization prompt if authorization has not yet been
    /// determined. This method may be called repeatedly; implementations should reuse their
    /// existing manager. Accessing ``centralManager``, ``managerStateMonitor``, or ``scanner``
    /// before calling this method may create the manager and cause the same prompt.
    func initialize()

    /// The startup configuration supplied when this stack was created.
    ///
    /// This value describes the options used to create the stack's central manager. Modifying
    /// a local copy does not reconfigure this stack or an existing central manager.
    var configuration: UUBluetoothConfiguration { get }
    
    /// The central manager responsible for discovering and connecting to BLE peripherals.
    ///
    /// If the manager has not been created, accessing this property creates it and may cause the
    /// system to present its Bluetooth authorization prompt.
    var centralManager: UUCentralManager { get }
    
    /// Observes and reports changes to the Bluetooth manager’s state.
    ///
    /// Accessing this property may create the central manager and may cause the system to present
    /// its Bluetooth authorization prompt.
    var managerStateMonitor: UUManagerStateMonitor { get }
    
    /// Scans for and manages discovered Bluetooth peripherals.
    ///
    /// Accessing this property creates the scanner if needed. Scanner creation may also create
    /// the central manager and cause the system to present its Bluetooth authorization prompt.
    var scanner: UUPeripheralScanner { get }
    
    /// The current Core Bluetooth authorization status.
    ///
    /// Reading this status does not create the central manager.
    var authorizationStatus: CBManagerAuthorization { get }
}
