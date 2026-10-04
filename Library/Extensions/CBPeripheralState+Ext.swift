//
//  CBPeripheralEnums+Extensions.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 11/10/24.
//

import CoreBluetooth

public extension CBPeripheralState
{
    func uuName() -> String
    {
        switch self
        {
            case .disconnected: return "Disconnected"
            case .connecting: return "Connecting"
            case .connected: return "Connected"
            case .disconnecting: return "Disconnecting"
            
        @unknown default:
            return "CBPeripheralState-\(self)"
        }
    }
}
