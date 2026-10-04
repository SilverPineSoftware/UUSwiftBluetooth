//
//  UUBluetoothConfig.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 9/30/26.
//

import Foundation
import CoreBluetooth

///
/// UUBluetoothConfig is a simple struct that contains startup values for the UUSwiftBluetooth library.  This is meant
/// for initial condition configuration of the library.
///
public struct UUBluetoothConfig: Codable
{
    public var centralOptions: UUCentralManagerOptions
    
    public init(centralOptions: UUCentralManagerOptions)
    {
        self.centralOptions = centralOptions
    }
}
