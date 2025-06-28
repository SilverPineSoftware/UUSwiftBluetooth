//
//  UUMockAdvertisement.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 6/27/25.
//

import Foundation
import CoreBluetooth

public class UUMockAdvertisement: UUAdvertisement
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
