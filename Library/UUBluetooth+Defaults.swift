//
//  UUBluetooth+Defaults.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 12/16/24.
//  Copyright © 2026 Silver Pine Software, LLC. All rights reserved.
//
//  This file is part of UUSwiftCore, distributed under the MIT License.
//  See LICENSE file for details.
//

import Foundation
import CoreBluetooth

public extension UUBluetooth // Constants
{
    struct Defaults
    {
        public static var connectTimeout: TimeInterval = 10.0
        public static var disconnectTimeout: TimeInterval = 10.0
        public static var operationTimeout: TimeInterval = 10.0
    }
}
