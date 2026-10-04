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
open class UUPeripheralScannerConfig
{
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
    
    /**
     Passed into the CBCentralManager scanForPeripherals for the CBCentralManagerScanOptionAllowDuplicatesKey options key.  When true,
     Core Bluetooth will give a callback for every BLE advertisement.  When false, Core Bluetooth will aggregate advertisements.  This perameter
     is only valid when the app is in the foreground.
     */
    public var allowDuplicates: Bool = false
    
    /**
     List of BLE services to scan for.
     */
    public var serviceUUIDs: [CBUUID]? = nil
    
    /**
     List of optional filters to apply when scanning.  Typical filters check things like RSSI or manufacturing data.  These filters determine whether or not
     a peripheral is to be added to the 'nearby' peripherals list.  Once a peripheral meets the criteria to be considered 'nearby', then all subsequent advertisements
     are processed.  A peripheral can only be removed from the 'nearby' list by meeting one or more of the out of range filters.
     */
    public var discoveryFilters: [UUPeripheralFilter]? = nil
    
    /**
     TimeInterval used to throttle scanning callbacks
     */
    public var callbackThrottle: TimeInterval = 0.5
    
    /**
     Sorting method used.  Common sorting comparators are provided by UUSwiftBluetooth.  See UUPeripheralRssiSortComparator, UUPeripheralFirstDiscoveryTimeComparator, and UUPeripheralFriendlyNameComparator
     */
    public var peripheralSorting: (any UUPeripheralComparator)? = nil
    
    
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
