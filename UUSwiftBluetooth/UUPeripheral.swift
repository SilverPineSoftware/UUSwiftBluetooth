//
//  UUPeripheral.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 8/13/21.
//

import UIKit
import CoreBluetooth
import UUSwiftCore

// UUPeripheral is a convenience class that wraps a CBPeripheral and it's
// advertisement data into one object.
//
open class UUPeripheral
{
    // Reference to the underlying CBPeripheral
    private var underlyingPeripheral: CBPeripheral!
    
    // The most recent advertisement data
    private var advertisementData: [String: Any] = [:]
    
    // Timestamp of when this peripheral was first seen
    private(set) public var firstAdvertisementTime: Date = Date()
    
    // Timestamp of when the last advertisement was seen
    private(set) public var lastAdvertisementTime: Date = Date()
    
    // Most recent signal strength
    private(set) public var rssi: Int = 0
    
    // Timestamp of when the RSSI was last updated
    private(set) public var lastRssiUpdateTime: Date = Date()
    
    public required init(_ peripheral: CBPeripheral)
    {
        underlyingPeripheral = peripheral
    }
    
    // Passthrough properties to read values directly from CBPeripheral
    
    public var identifier: String
    {
        return underlyingPeripheral.identifier.uuidString
    }
    
    public var name: String
    {
        return underlyingPeripheral.name ?? ""
    }
    
    public var localName: String
    {
        return advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? ""
    }
    
    public var friendlyName: String
    {
        var result = localName
        if (result.isEmpty)
        {
            result = self.name
        }
        
        return result
    }
    
    public var peripheralState: CBPeripheralState
    {
        return underlyingPeripheral.state
    }
    
    // Returns value of CBAdvertisementDataIsConnectable from advertisement data.  Default
    // value is NO if value is not present. Per the CoreBluetooth documentation, this
    // value indicates if the peripheral is connectable "right now", which implies
    // it may change in the future.
    public var isConnectable: Bool
    {
        return advertisementData.uuSafeGetBool(CBAdvertisementDataIsConnectable) ?? false
    }
    
    // Returns value of CBAdvertisementDataManufacturerDataKey from advertisement data.
    public var manufacturingData: Data?
    {
        return advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
    }
    
    // Hook for derived classes to parse custom manufacturing data during object creation.
    open func parseManufacturingData()
    {
        
    }
}
