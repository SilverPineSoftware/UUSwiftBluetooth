//
//  UUPeripheralFilter.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 8/13/21.
//

import Foundation

public protocol UUPeripheralFilter
{
    func shouldDiscover(_ peripheral: UUPeripheral) -> Bool
}
