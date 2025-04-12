//
//  CBManagerState+Ext.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 4/12/25.
//

import CoreBluetooth


public extension CBManagerState
{
    func uuName() -> String
    {
        switch (self)
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
                
            @unknown default:
                return "CBManagerState-\(self)"
        }
    }
}
