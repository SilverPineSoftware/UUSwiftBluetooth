//
//  UUBluetoothAdvertisement.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 8/22/21.
//

import Foundation
import CoreBluetooth
import UUSwiftCore

// UUBluetoothAdvertisement wraps the data returned from the CoreBluetooth Api during BLE scanning.  Namely
// the peripheral, the advertisement data dictionary, and the signal strength (RSSI).
//
public class UUBluetoothAdvertisement: UUAdvertisement
{
    private(set) public var peripheral: CBPeripheral
    private(set) public var advertisementData: [String:Any]
    private(set) public var rssi: Int
    private(set) public var identifier: UUID
    
    required public init(_ peripheral: CBPeripheral, _ advertisementData: [String:Any], _ rssi: Int)
    {
        self.peripheral = peripheral
        self.advertisementData = advertisementData
        self.rssi = rssi
        self.identifier = peripheral.identifier
    }
    
    ///
    /// Returns the value of CBAdvertisementDataLocalNameKey from the advertisement data.
    public var localName: String
    {
        return advertisementData.uuSafeGetString(CBAdvertisementDataLocalNameKey, "")
    }
    
    // Returns value of CBAdvertisementDataIsConnectable from advertisement data.  Default
    // value is NO if value is not present. Per the CoreBluetooth documentation, this
    // value indicates if the peripheral is connectable "right now", which implies
    // it may change in the future.
    public var isConnectable: Bool
    {
        return advertisementData.uuSafeGetBool(CBAdvertisementDataIsConnectable, false)
    }
    
    // Returns value of CBAdvertisementDataManufacturerDataKey from advertisement data.
    public var manufacturingData: Data?
    {
        return advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
    }
    
    ///
    ///Returns the value of CBAdvertisementDataTxPowerLevelKey from the advertisement data.
    public var transmitPower: Int?
    {
        return advertisementData.uuGetInt(CBAdvertisementDataTxPowerLevelKey)
    }
    
    /**
     * Returns the value of kCBAdvDataRxPrimaryPHY from the advertisment data.  This is an undocumented value that represents
     * the Primary Phy value for the peripheral
     */
    public var primaryPhy: Int?
    {
        return advertisementData.uuGetInt(UUCoreBluetooth.Constants.AdvertisementDataKeys.rxPrimaryPHY)
    }
    
    /**
     * Returns the value of kCBAdvDataRxSecondaryPHY from the advertisment data.  This is an undocumented value that represents
     * the secondary Phy value for the peripheral
     */
    public var secondaryPhy: Int?
    {
        return advertisementData.uuGetInt(UUCoreBluetooth.Constants.AdvertisementDataKeys.rxSecondaryPHY)
    }
    
    /**
     * Returns the value of kCBAdvDataTimestamp from the advertisment data.  This is an undocumented value that represents
     * the timestamp of when the operating system received the advertisement.
     */
    public var timestamp: Date
    {
        guard let num = advertisementData.uuGetDouble(UUCoreBluetooth.Constants.AdvertisementDataKeys.timestamp) else
        {
            return Date()
        }
        
        return Date(timeIntervalSinceReferenceDate: num)
    }
    
    public var services: [CBUUID]?
    {
        return advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]
    }
    
    public var serviceData: [CBUUID: Data]?
    {
        return advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data]
    }
    
    public var overflowServices: [CBUUID]?
    {
        return advertisementData[CBAdvertisementDataOverflowServiceUUIDsKey] as? [CBUUID]
    }
    
    public var solicitedServices: [CBUUID]?
    {
        return advertisementData[CBAdvertisementDataSolicitedServiceUUIDsKey] as? [CBUUID]
    }
}
