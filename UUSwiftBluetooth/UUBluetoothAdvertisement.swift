//
//  UUBluetoothAdvertisement.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 8/22/21.
//

import UIKit
import CoreBluetooth
import UUSwiftCore

// UUBluetoothAdvertisement wraps the data returned from the CoreBluetooth Api during BLE scanning.  Namely
// the peripheral, the advertisement data dictionary, and the signal strength (RSSI).
//
public class UUBluetoothAdvertisement
{
    private(set) public var peripheral: CBPeripheral
    private(set) public var advertisementData: [String:Any]? = nil
    private(set) public var rssi: Int? = nil
    
    required public init(_ peripheral: CBPeripheral, _ advertisementData: [String:Any]?, _ rssi: Int?)
    {
        self.peripheral = peripheral
        self.advertisementData = advertisementData
        self.rssi = rssi
    }
    
    ///
    /// Returns the value of CBAdvertisementDataLocalNameKey from the advertisement data.
    public var localName: String?
    {
        guard let d = advertisementData else { return nil }
        
        return d.uuGetString(CBAdvertisementDataLocalNameKey)
    }
    
    // Returns value of CBAdvertisementDataIsConnectable from advertisement data.  Default
    // value is NO if value is not present. Per the CoreBluetooth documentation, this
    // value indicates if the peripheral is connectable "right now", which implies
    // it may change in the future.
    public var isConnectable: Bool?
    {
        guard let d = advertisementData else { return nil }
        
        return d.uuGetBool(CBAdvertisementDataIsConnectable) ?? false
    }
    
    // Returns value of CBAdvertisementDataManufacturerDataKey from advertisement data.
    public var manufacturingData: Data?
    {
        guard let d = advertisementData else { return nil }
        
        return d[CBAdvertisementDataManufacturerDataKey] as? Data
    }
    
    ///
    ///Returns the value of CBAdvertisementDataTxPowerLevelKey from the advertisement data.
    public var transmitPower: Int?
    {
        guard let d = advertisementData else { return nil }
        
        return d.uuGetInt(CBAdvertisementDataTxPowerLevelKey)
    }
    
    /**
     * Returns the value of kCBAdvDataRxPrimaryPHY from the advertisment data.  This is an undocumented value that represents
     * the Primary Phy value for the peripheral
     */
    public var primaryPhy: Int?
    {
        guard let d = advertisementData else { return nil }
        
        return d.uuGetInt(UUBluetoothConstants.AdvertisementDataKeys.rxPrimaryPHY)
    }
    
    /**
     * Returns the value of kCBAdvDataRxSecondaryPHY from the advertisment data.  This is an undocumented value that represents
     * the secondary Phy value for the peripheral
     */
    public var secondaryPhy: Int?
    {
        guard let d = advertisementData else { return nil }
        
        return d.uuGetInt(UUBluetoothConstants.AdvertisementDataKeys.rxSecondaryPHY)
    }
    
    /**
     * Returns the value of kCBAdvDataTimestamp from the advertisment data.  This is an undocumented value that represents
     * the timestamp of when the operating system received the advertisement.
     */
    public var timestamp: Date?
    {
        guard let d = advertisementData else { return nil }
        
        guard let num = d.uuGetDouble(UUBluetoothConstants.AdvertisementDataKeys.timestamp) else
        {
            return nil
        }
        
        return Date(timeIntervalSinceReferenceDate: num)
    }
    
    public var services: [CBUUID]?
    {
        guard let d = advertisementData else { return nil }
        
        return d[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]
    }
    
    public var serviceData: [CBUUID: Data]?
    {
        guard let d = advertisementData else { return nil }
        
        return d[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data]
    }
    
    public var overflowServices: [CBUUID]?
    {
        guard let d = advertisementData else { return nil }
        
        return d[CBAdvertisementDataOverflowServiceUUIDsKey] as? [CBUUID]
    }
    
    public var solicitedServices: [CBUUID]?
    {
        guard let d = advertisementData else { return nil }
        
        return d[CBAdvertisementDataSolicitedServiceUUIDsKey] as? [CBUUID]
    }
}
