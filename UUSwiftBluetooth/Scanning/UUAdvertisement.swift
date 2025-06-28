//
//  UUAdvertisement.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 12/16/24.
//

import Foundation
import CoreBluetooth

public class UUAdvertisement
{
    public var identifier: UUID = UUID()
    public var advertisementData: [String:Any] = [:]
    public var rssi: Int = 0
    public var localName: String = ""
    public var isConnectable: Bool = false
    public var manufacturingData: Data? = nil
    public var transmitPower: Int? = nil
    public var primaryPhy: Int? = nil
    public var secondaryPhy: Int? = nil
    public var timestamp: Date = Date()
    public var services: [CBUUID]? = nil
    public var serviceData: [CBUUID: Data]? = nil
    public var overflowServices: [CBUUID]? = nil
    public var solicitedServices: [CBUUID]? = nil
    
    public init(
        identifier: UUID = UUID(),
        advertisementData: [String : Any] = [:],
        rssi: Int = 0,
        localName: String = "",
        isConnectable: Bool = false,
        manufacturingData: Data? = nil,
        transmitPower: Int? = nil,
        primaryPhy: Int? = nil,
        secondaryPhy: Int? = nil,
        timestamp: Date = Date(),
        services: [CBUUID]? = nil,
        serviceData: [CBUUID : Data]? = nil,
        overflowServices: [CBUUID]? = nil,
        solicitedServices: [CBUUID]? = nil)
    {
        self.identifier = identifier
        self.advertisementData = advertisementData
        self.rssi = rssi
        self.localName = localName
        self.isConnectable = isConnectable
        self.manufacturingData = manufacturingData
        self.transmitPower = transmitPower
        self.primaryPhy = primaryPhy
        self.secondaryPhy = secondaryPhy
        self.timestamp = timestamp
        self.services = services
        self.serviceData = serviceData
        self.overflowServices = overflowServices
        self.solicitedServices = solicitedServices
    }
}


public extension UUAdvertisement // CoreBluetooth Construction
{
    convenience init(_ identifier: UUID, _ advertisementData: [String:Any], _ rssi: Int)
    {
        self.init(
            identifier: identifier,
            advertisementData: advertisementData,
            rssi: rssi,
            localName: advertisementData.uuLocalName,
            isConnectable: advertisementData.uuIsConnectable,
            manufacturingData: advertisementData.uuManufacturingData,
            transmitPower: advertisementData.uuTransmitPower,
            primaryPhy: advertisementData.uuPrimaryPhy,
            secondaryPhy: advertisementData.uuSecondaryPhy,
            timestamp: advertisementData.uuTimestamp,
            services: advertisementData.uuServices,
            serviceData: advertisementData.uuServiceData,
            overflowServices: advertisementData.uuOverflowServices,
            solicitedServices: advertisementData.uuSolicitedServices
        )
    }
}

public extension Dictionary where Key == String, Value == Any
{
    ///
    /// Returns the value of CBAdvertisementDataLocalNameKey from the advertisement data.
    var uuLocalName: String
    {
        return self.uuSafeGetString(CBAdvertisementDataLocalNameKey, "")
    }
    
    // Returns value of CBAdvertisementDataIsConnectable from advertisement data.  Default
    // value is NO if value is not present. Per the CoreBluetooth documentation, this
    // value indicates if the peripheral is connectable "right now", which implies
    // it may change in the future.
    var uuIsConnectable: Bool
    {
        return self.uuSafeGetBool(CBAdvertisementDataIsConnectable, false)
    }
    
    // Returns value of CBAdvertisementDataManufacturerDataKey from advertisement data.
    var uuManufacturingData: Data?
    {
        return self[CBAdvertisementDataManufacturerDataKey] as? Data
    }
    
    ///
    ///Returns the value of CBAdvertisementDataTxPowerLevelKey from the advertisement data.
    var uuTransmitPower: Int?
    {
        return self.uuGetInt(CBAdvertisementDataTxPowerLevelKey)
    }
    
    /**
     * Returns the value of kCBAdvDataRxPrimaryPHY from the advertisment data.  This is an undocumented value that represents
     * the Primary Phy value for the peripheral
     */
    var uuPrimaryPhy: Int?
    {
        return self.uuGetInt(UUCoreBluetooth.Constants.AdvertisementDataKeys.rxPrimaryPHY)
    }
    
    /**
     * Returns the value of kCBAdvDataRxSecondaryPHY from the advertisment data.  This is an undocumented value that represents
     * the secondary Phy value for the peripheral
     */
    var uuSecondaryPhy: Int?
    {
        return self.uuGetInt(UUCoreBluetooth.Constants.AdvertisementDataKeys.rxSecondaryPHY)
    }
    
    /**
     * Returns the value of kCBAdvDataTimestamp from the advertisment data.  This is an undocumented value that represents
     * the timestamp of when the operating system received the advertisement.
     */
    var uuTimestamp: Date
    {
        guard let num = self.uuGetDouble(UUCoreBluetooth.Constants.AdvertisementDataKeys.timestamp) else
        {
            return Date()
        }
        
        return Date(timeIntervalSinceReferenceDate: num)
    }
    
    var uuServices: [CBUUID]?
    {
        return self[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]
    }
    
    var uuServiceData: [CBUUID: Data]?
    {
        return self[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data]
    }
    
    var uuOverflowServices: [CBUUID]?
    {
        return self[CBAdvertisementDataOverflowServiceUUIDsKey] as? [CBUUID]
    }
    
    var uuSolicitedServices: [CBUUID]?
    {
        return self[CBAdvertisementDataSolicitedServiceUUIDsKey] as? [CBUUID]
    }
}
