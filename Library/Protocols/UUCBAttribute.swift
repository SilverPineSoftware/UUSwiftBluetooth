//
//  UUCBAttribute.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 7/7/25.
//

import Foundation
import CoreBluetooth

public protocol UUCBAttribute: AnyObject
{
    /**
     * @property UUID
     *
     * @discussion
     *      The Bluetooth UUID of the attribute.
     *
     */
    var uuid: CBUUID { get }
}
