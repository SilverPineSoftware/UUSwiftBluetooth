//
//  Untitled.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 5/10/25.
//  Copyright © 2026 Silver Pine Software, LLC. All rights reserved.
//
//  This file is part of UUSwiftCore, distributed under the MIT License.
//  See LICENSE file for details.
//


/// Convenience namespace for the library's default Bluetooth stack.
///
/// Use ``shared`` for a stack with default configuration. For custom options, previews, or tests,
/// create and inject a configured ``UUBluetoothStack`` implementation instead.
public struct UUBluetooth
{
    // Enforce static namespace usage
    private init() { }
    
    /// The process-wide stack using the default Bluetooth configuration.
    ///
    /// Accessing this property creates the stack object but does not create its central manager.
    /// Call ``UUBluetoothStack/initialize()`` when the app is ready to begin Bluetooth work.
    /// Accessing the stack's ``UUBluetoothStack/centralManager``,
    /// ``UUBluetoothStack/managerStateMonitor``, or ``UUBluetoothStack/scanner`` first also
    /// creates the manager and may cause the system to present its Bluetooth authorization prompt.
    public static let shared: UUBluetoothStack = UUCoreBluetoothStack()
}

     
     
