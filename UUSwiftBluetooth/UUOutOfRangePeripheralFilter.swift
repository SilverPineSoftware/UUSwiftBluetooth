//
//  UUOutOfRangePeripheralFilter.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 2/26/22.
//

import UIKit

public enum UUOutOfRangePeripheralFilterResult
{
    case inRange
    case outOfRange
}

public protocol UUOutOfRangePeripheralFilter
{
    func checkPeripheralRange(_ peripheral: UUPeripheral) -> UUOutOfRangePeripheralFilterResult
}
