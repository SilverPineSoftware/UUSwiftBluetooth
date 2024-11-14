//
//  UUBluetoothScanSettings.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 11/13/24.
//

import UIKit
import CoreBluetooth

public struct UUBluetoothScanSettings
{
   public init(allowDuplicates: Bool = false,
                serviceUUIDs: [CBUUID]? = nil,
                discoveryFilters: [UUPeripheralFilter]? = nil,
                outOfRangeFilters: [UUOutOfRangePeripheralFilter]? = nil,
                outOfRangeFilterEvaluationFrequency: TimeInterval = 0.5,
                scanWatchdogTimeout: TimeInterval = 0.5)
    {
        self.allowDuplicates = allowDuplicates
        self.serviceUUIDs = serviceUUIDs
        self.discoveryFilters = discoveryFilters
        self.outOfRangeFilters = outOfRangeFilters
        self.outOfRangeFilterEvaluationFrequency = outOfRangeFilterEvaluationFrequency
        self.scanWatchdogTimeout = scanWatchdogTimeout
    }
    
    public var allowDuplicates: Bool = false
    public var serviceUUIDs: [CBUUID]? = nil
    public var discoveryFilters: [UUPeripheralFilter]? = nil
    public var outOfRangeFilters: [UUOutOfRangePeripheralFilter]? = nil
    public var outOfRangeFilterEvaluationFrequency: TimeInterval = 0.5
    public var scanWatchdogTimeout: TimeInterval = 0.0
}
