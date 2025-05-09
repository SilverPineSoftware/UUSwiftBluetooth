//
//  MockAdvertisement.swift
//  Silvertooth
//
//  Created by Ryan DeVore on 12/17/24.
//

#if DEBUG

import Foundation
import CoreBluetooth
import UUSwiftBluetooth

open class MockAdvertisement: UUAdvertisement
{
    public var localName: String = ""
    public var isConnectable: Bool = false
    public var manufacturingData: Data? = nil
    public var transmitPower: Int? = nil
    public var primaryPhy: Int? = nil
    public var secondaryPhy: Int? = nil
    public var timestamp: Date = Date()
    public var services: [CBUUID]? = nil
    public var serviceData: [CBUUID : Data]? = nil
    public var overflowServices: [CBUUID]? = nil
    public var solicitedServices: [CBUUID]? = nil
    public var identifier: UUID = UUID()
    public var advertisementData: [String : Any] = [:]
    public var rssi: Int = 0
    
    public convenience init(
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
        solicitedServices: [CBUUID]? = nil,
        identifier: UUID = UUID(),
        advertisementData: [String : Any] = [:],
        rssi: Int = 0)
    {
        self.init()
        
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
        self.identifier = identifier
        self.advertisementData = advertisementData
        self.rssi = rssi
    }
    
    var mockCompanyName: String = ""
    {
        didSet
        {
            let uuidData = withUnsafeBytes(of: identifier.uuid) { Data($0) }
        
            if let companyCode = uuidData.uuUInt16(at: 0)
            {
                let companyCodeHex = String(format: "%04X", companyCode)
                UUCoreBluetooth.register(commonName: mockCompanyName, for: companyCodeHex)
                
                advertisementData[CBAdvertisementDataManufacturerDataKey] = uuidData
            }
        }
    }
}

#endif
