//
//  UUCoreBluetooth.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 8/13/21.
//

import UIKit
import CoreBluetooth
import UUSwiftCore

public class UUCoreBluetooth
{

}



public func UUCBManagerStateToString(_ state: CBManagerState) -> String
{
    switch (state)
    {
        case .unknown:
            return "Unknown"
            
        case .resetting:
            return "Resetting"
            
        case .unsupported:
            return "Unsupported"
            
        case .unauthorized:
            return "Unauthorized"
            
        case .poweredOff:
            return "PoweredOff"
            
        case .poweredOn:
            return "PoweredOn"
            
        default:
            return "CBManagerState-\(state)"
    }
}

public func UUCBPeripheralStateToString(_ state: CBPeripheralState) -> String
{
    switch (state)
    {
        case .disconnected:
            return "Disconnected"
            
        case .connecting:
            return "Connecting"
            
        case .connected:
            return "Connected"
            
        case .disconnecting:
            return "Disconnecting"
            
        default:
            return "CBPeripheralState-\(state)"
    }
}
