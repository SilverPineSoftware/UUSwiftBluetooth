//
//  CBUUID+Extensions.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 8/17/21.
//

import UIKit
import CoreBluetooth
import UUSwiftCore

public extension CBUUID
{
    // Some UUID's have a common name, if UUIDString does not match, it is returned,
    // otherwise 'Unknown'.
    var uuCommonName: String
    {
        let name = "\(self)"
        if (name == uuidString)
        {
            return "Unknown"
        }
        else
        {
            return name;
        }
    }
}
