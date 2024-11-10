//
//  UUPeripheralFilter.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 8/13/21.
//

import UIKit

public protocol UUPeripheralFilter
{
    func shouldDiscover(_ peripheral: any UUPeripheral) -> Bool
}
