//
//  UUPeripheralScannerConfig.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 11/13/24.
//

import Foundation
import CoreBluetooth

/**
 Contains BLE scanning settings
 */
public struct UUPeripheralScannerConfig
{
    /**
     Passed into the CBCentralManager scanForPeripherals for the CBCentralManagerScanOptionAllowDuplicatesKey options key.  When true,
     Core Bluetooth will give a callback for every BLE advertisement.  When false, Core Bluetooth will aggregate advertisements.  This perameter
     is only valid when the app is in the foreground.
     */
    public let allowDuplicates: Bool
    
    /**
     List of BLE services to scan for.
     */
    public let serviceUUIDs: [CBUUID]?
    
    /**
     List of optional filters to apply when scanning.  Typical filters check things like RSSI or manufacturing data.  These filters determine whether or not
     a peripheral is to be added to the 'nearby' peripherals list.  Once a peripheral meets the criteria to be considered 'nearby', then all subsequent advertisements
     are processed.  A peripheral can only be removed from the 'nearby' list by meeting one or more of the out of range filters.
     */
    public let discoveryFilters: [UUPeripheralFilter]?
    
    /**
     TimeInterval used to throttle scanning callbacks
     */
    public let callbackThrottle: TimeInterval
    
    /**
     Sorting method used.  Common sorting comparators are provided by UUSwiftBluetooth.  See UUPeripheralRssiSortComparator, UUPeripheralFirstDiscoveryTimeComparator, and UUPeripheralFriendlyNameComparator
     */
    public let peripheralSorting: (any UUPeripheralComparator)?

    /**
     Creates an instance of UUPeripheralScannerConfig
     */
    public init(
        allowDuplicates: Bool = false,
        serviceUUIDs: [CBUUID]? = nil,
        discoveryFilters: [UUPeripheralFilter]? = nil,
        callbackThrottle: TimeInterval = 0.5,
        peripheralSorting: (any UUPeripheralComparator)? = nil)
    {
        self.allowDuplicates = allowDuplicates
        self.serviceUUIDs = serviceUUIDs
        self.discoveryFilters = discoveryFilters
        self.callbackThrottle = callbackThrottle
        self.peripheralSorting = peripheralSorting
    }
    
    // Capture the configurable fields for one scan. Filter and comparator
    // objects are caller-owned and must not be mutated during an active scan.
    /*func snapshot() -> UUPeripheralScannerConfig
    {
        UUPeripheralScannerConfig(
            allowDuplicates: allowDuplicates,
            serviceUUIDs: serviceUUIDs,
            discoveryFilters: discoveryFilters,
            callbackThrottle: callbackThrottle,
            peripheralSorting: peripheralSorting)
    }*/
    
    
    /**
     Builds the scanning options used to pass into CBCentralManager
     */
    public var scanOptions: [String:Any]
    {
        var opts: [String:Any] = [:]
        opts[CBCentralManagerScanOptionAllowDuplicatesKey] = allowDuplicates
        return opts
    }
}
