//
//  UUCoreBluetoothStack.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 5/10/25.
//

import Foundation
import UUSwiftCore
import CoreBluetooth

/// The Core Bluetooth implementation of ``UUBluetoothStack``.
///
/// Creating this stack stores its configuration without creating a central manager. Call
/// ``initialize()`` when the app is ready to create the manager and, if authorization has not
/// yet been determined, allow the system to present its Bluetooth authorization prompt.
/// Accessing ``centralManager``, ``managerStateMonitor``, or ``scanner`` first also creates the
/// manager and may cause the prompt. Manager and scanner creation is synchronized so repeated
/// or concurrent access reuses the same instances.
public class UUCoreBluetoothStack: UUBluetoothStack
{
    private let LOG_TAG = "UUCoreBluetoothStack"
    private let creationLock = NSRecursiveLock()
    private var _centralManager: UUCentralManager? = nil
    private var _scanner: UUPeripheralScanner? = nil
    
    public private(set) var configuration: UUBluetoothConfiguration
    
    /// Creates a Core Bluetooth stack with the supplied startup configuration.
    ///
    /// This initializer does not create a central manager. Call ``initialize()`` or access a
    /// manager-backed property when the app is ready to begin Bluetooth work.
    /// - Parameter configuration: The options to use when creating the central manager.
    public required init(configuration: UUBluetoothConfiguration = UUBluetoothConfiguration())
    {
        self.configuration = configuration
    }
    
    /// Creates the central manager before it is otherwise needed.
    ///
    /// Creating the manager may cause the system to present its Bluetooth authorization prompt
    /// if authorization has not yet been determined. Repeated or concurrent calls reuse the
    /// same manager.
    public func initialize()
    {
        _ = centralManager
    }
    
    /// The central manager used by this stack.
    ///
    /// The manager is created on first access using ``configuration``. Creation may cause the
    /// system to present its Bluetooth authorization prompt. Concurrent first accesses are
    /// synchronized and return the same manager.
    public var centralManager: UUCentralManager
    {
        creationLock.withLock
        {
            if let central = _centralManager
            {
                return central
            }
            
            let central = UUCentralManager(options: self.configuration.centralOptions)
            _centralManager = central
            return central
        }
    }
    
    /// The scanner used by this stack.
    ///
    /// The scanner is created on first access and uses this stack's ``centralManager``. If the
    /// manager has not yet been created, scanner access creates it and may cause the system to
    /// present its Bluetooth authorization prompt. Concurrent first accesses return the same
    /// scanner.
    public var scanner: UUPeripheralScanner
    {
        creationLock.withLock
        {
            if let scanner = _scanner
            {
                return scanner
            }
            
            let scanner = UUCoreBluetoothPeripheralScanner(centralManager: self.centralManager)
            _scanner = scanner
            return scanner
        }
    }
    
    /// Monitors state changes from this stack's central manager.
    ///
    /// Accessing this property creates the central manager if needed and may cause the system to
    /// present its Bluetooth authorization prompt.
    public var managerStateMonitor: any UUManagerStateMonitor
    {
        return centralManager
    }
    
    /// The current Core Bluetooth authorization status.
    ///
    /// Reading this value does not create the central manager.
    public var authorizationStatus: CBManagerAuthorization
    {
        return CBCentralManager.authorization
    }
}
