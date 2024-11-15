//
//  UUOutOfRangePeripheralFilter.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 2/26/22.
//

import UIKit

public protocol UUOutOfRangePeripheralFilter
{
    func checkPeripheralRange(_ peripheral: UUPeripheral) -> UUPeripheralRange
}
