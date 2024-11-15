//
//  UUBluetoothScanSettings.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 11/13/24.
//

import UIKit
import CoreBluetooth

/**
 Contains BLE scanning settings
 */
public struct UUBluetoothScanSettings
{
    /**
     Creates an instance of UUBluetoothScanSettings
     */
    public init()
    {
        
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
     List of optional filters to apply when determining if a peripheral is 'out of range'.  These are often related to the discovery filters.  These filters are evaluated
     on a timer while scanning.  If any peripherals change from in range to out of range, the nearby devices callback is invoked with the updated list.
     */
    public var outOfRangeFilters: [UUOutOfRangePeripheralFilter]? = nil
    
    /**
     Frequency (in seconds) at which the out of range filters are evaluated
     
     Note: if this value is less than or equal to zero, the out of range filter logic is disabled.
     */
    public var outOfRangeFilterEvaluationFrequency: TimeInterval = 0.5
    
    /**
     Simulated ranging makes UUSwiftBluetooth stop and re-start the BLE scan under the hood as a way attempt to collect
     real time advertisements from BLE peripherals.  When allowDuplicates is false, a normal CoreBluetooth scan will aggregate
     BLE advertisements, so each invocation of scanForPeripherals might only report a single advertisement per peripheral.
     
     Note: when allowDuplicates is true, simulatedRanging is ignored
     */
    public var simulatedRanging: Bool = false
    
    /**
     Simulated ranging involves stopping and restarting the CoreBluetooth scan.  This watchdog timeout value controls how often that
     restart occurs.  Each time a peripheral is discovered, this watchdog timer is kicked.  If the timer fires, then the scan is stopped and
     restarted.  If this value is less than or equal to zero, simulated ranging is ignored.
     
     Note: when allowDuplicates is true, simulatedRanging is ignored
     */
    public var simulatedRangingWatchdogTimeout: TimeInterval = 0.0
}
