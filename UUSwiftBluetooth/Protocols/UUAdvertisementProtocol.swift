//
//  UUAdvertisementProtocol.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 12/16/24.
//

import UIKit
import CoreBluetooth

public protocol UUAdvertisementProtocol
{
    var identifier: UUID { get }
    var advertisementData: [String:Any]? { get }
    var rssi: Int? { get }
    
    ///
    /// Returns the value of CBAdvertisementDataLocalNameKey from the advertisement data.
    var localName: String? { get }
    
    // Returns value of CBAdvertisementDataIsConnectable from advertisement data.  Default
    // value is NO if value is not present. Per the CoreBluetooth documentation, this
    // value indicates if the peripheral is connectable "right now", which implies
    // it may change in the future.
    var isConnectable: Bool? { get }
    
    // Returns value of CBAdvertisementDataManufacturerDataKey from advertisement data.
    var manufacturingData: Data? { get }
    
    ///
    ///Returns the value of CBAdvertisementDataTxPowerLevelKey from the advertisement data.
    var transmitPower: Int? { get }
    
    /**
     * Returns the value of kCBAdvDataRxPrimaryPHY from the advertisment data.  This is an undocumented value that represents
     * the Primary Phy value for the peripheral
     */
    var primaryPhy: Int? { get }
    
    /**
     * Returns the value of kCBAdvDataRxSecondaryPHY from the advertisment data.  This is an undocumented value that represents
     * the secondary Phy value for the peripheral
     */
    var secondaryPhy: Int? { get }
    
    /**
     * Returns the value of kCBAdvDataTimestamp from the advertisment data.  This is an undocumented value that represents
     * the timestamp of when the operating system received the advertisement.
     */
    var timestamp: Date? { get }
    
    var services: [CBUUID]? { get }
    
    var serviceData: [CBUUID: Data]? { get }
    
    var overflowServices: [CBUUID]? { get }
    
    var solicitedServices: [CBUUID]? { get }
}


public extension UUAdvertisementProtocol
{
    ///
    /// Returns the value of CBAdvertisementDataLocalNameKey from the advertisement data.
    var localName: String?
    {
        guard let d = advertisementData else { return nil }
        
        return d.uuGetString(CBAdvertisementDataLocalNameKey)
    }
    
    // Returns value of CBAdvertisementDataIsConnectable from advertisement data.  Default
    // value is NO if value is not present. Per the CoreBluetooth documentation, this
    // value indicates if the peripheral is connectable "right now", which implies
    // it may change in the future.
    var isConnectable: Bool?
    {
        guard let d = advertisementData else { return nil }
        
        return d.uuGetBool(CBAdvertisementDataIsConnectable) ?? false
    }
    
    // Returns value of CBAdvertisementDataManufacturerDataKey from advertisement data.
    var manufacturingData: Data?
    {
        guard let d = advertisementData else { return nil }
        
        return d[CBAdvertisementDataManufacturerDataKey] as? Data
    }
    
    ///
    ///Returns the value of CBAdvertisementDataTxPowerLevelKey from the advertisement data.
    var transmitPower: Int?
    {
        guard let d = advertisementData else { return nil }
        
        return d.uuGetInt(CBAdvertisementDataTxPowerLevelKey)
    }
    
    /**
     * Returns the value of kCBAdvDataRxPrimaryPHY from the advertisment data.  This is an undocumented value that represents
     * the Primary Phy value for the peripheral
     */
    var primaryPhy: Int?
    {
        guard let d = advertisementData else { return nil }
        
        return d.uuGetInt(UUBluetoothConstants.AdvertisementDataKeys.rxPrimaryPHY)
    }
    
    /**
     * Returns the value of kCBAdvDataRxSecondaryPHY from the advertisment data.  This is an undocumented value that represents
     * the secondary Phy value for the peripheral
     */
    var secondaryPhy: Int?
    {
        guard let d = advertisementData else { return nil }
        
        return d.uuGetInt(UUBluetoothConstants.AdvertisementDataKeys.rxSecondaryPHY)
    }
    
    /**
     * Returns the value of kCBAdvDataTimestamp from the advertisment data.  This is an undocumented value that represents
     * the timestamp of when the operating system received the advertisement.
     */
    var timestamp: Date?
    {
        guard let d = advertisementData else { return nil }
        
        guard let num = d.uuGetDouble(UUBluetoothConstants.AdvertisementDataKeys.timestamp) else
        {
            return nil
        }
        
        return Date(timeIntervalSinceReferenceDate: num)
    }
    
    var services: [CBUUID]?
    {
        guard let d = advertisementData else { return nil }
        
        return d[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]
    }
    
    var serviceData: [CBUUID: Data]?
    {
        guard let d = advertisementData else { return nil }
        
        return d[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data]
    }
    
    var overflowServices: [CBUUID]?
    {
        guard let d = advertisementData else { return nil }
        
        return d[CBAdvertisementDataOverflowServiceUUIDsKey] as? [CBUUID]
    }
    
    var solicitedServices: [CBUUID]?
    {
        guard let d = advertisementData else { return nil }
        
        return d[CBAdvertisementDataSolicitedServiceUUIDsKey] as? [CBUUID]
    }
}
