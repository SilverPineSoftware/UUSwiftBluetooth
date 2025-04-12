//
//  DispatchQueue+Extensions.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 8/22/21.
//

import UIKit

private var theBluetoothDispatchQueue = DispatchQueue(label: "UUCoreBluetoothDispatchQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .inherit, target: nil)

extension DispatchQueue
{
    static var uuBluetooth: DispatchQueue
    {
        return theBluetoothDispatchQueue
    }
}
