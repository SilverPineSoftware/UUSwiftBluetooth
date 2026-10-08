//
//  UUBluetoothConfiguration.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 9/30/26.
//

import Foundation
import CoreBluetooth

/// Startup configuration for a ``UUBluetoothStack``.
///
/// The configuration is supplied when a stack is created and provides the options used when
/// its Core Bluetooth central manager is created. Creating or changing this value does not
/// itself create a manager or trigger the Bluetooth authorization prompt.
public struct UUBluetoothConfiguration: Codable
{
    /// Options passed to the central manager when the stack creates it.
    public var centralOptions: UUCentralManagerOptions
    
    /// Creates a Bluetooth configuration.
    /// - Parameter centralOptions: The options to use when creating the central manager.
    public init(centralOptions: UUCentralManagerOptions = UUCentralManagerOptions())
    {
        self.centralOptions = centralOptions
    }
}
