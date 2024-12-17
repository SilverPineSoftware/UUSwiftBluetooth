//
//  CBCentralManager+Ext.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 12/16/24.
//

import CoreBluetooth

internal extension CBCentralManager
{
    var uuCanStartScanning: Bool
    {
        return state == .poweredOn
    }
}
