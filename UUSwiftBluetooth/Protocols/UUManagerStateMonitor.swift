//
//  UUManagerStateMonitor.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 7/18/25.
//

import CoreBluetooth

/// A closure that is called whenever the Bluetooth manager’s state changes.
/// - Parameter state: The new `CBManagerState` value reported by the manager.
public typealias UUCBManagerStateBlock = (CBManagerState) -> Void

/// An object that can report and observe the state of a Core Bluetooth manager.
public protocol UUManagerStateMonitor
{    
    /// The current state of the Bluetooth manager.
    var managerState: CBManagerState { get }
    
    /// Begins monitoring for changes to the manager’s state.
    ///
    /// - Parameters:
    ///   - identifier: A unique string used to identify this registration.
    ///                 You can use this to later deregister or distinguish multiple handlers.
    ///   - handler:    A block that will be invoked whenever `managerState` changes.
    ///                 The new state is passed as the `state` parameter.
    func registerForStateChanges(
        identifier: String,
        handler: @escaping UUCBManagerStateBlock
    )
}
