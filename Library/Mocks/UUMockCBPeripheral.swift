//
//  UUMockCBPeripheral.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 7/8/25.
//

#if DEBUG

import Foundation
import CoreBluetooth

///
/// Mock implemenation of a UUCBPeripheral interface used to simulate a CBPeripheral for Previews
///
public class UUMockCBPeripheral: UUCBPeripheral
{
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    // MARK: UUCBPeripheral implemenation
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    
    public init(
        identifier: UUID,
        name: String? = nil,
        state: CBPeripheralState = .disconnected,
        services: [CBService]? = nil,
        canSendWriteWithoutResponse: Bool = true,
        ancsAuthorized: Bool = false
    )
    {
        self.identifier = identifier
        self.name = name
        self.state = state
        self.services = services
        self.canSendWriteWithoutResponse = canSendWriteWithoutResponse
        self.ancsAuthorized = ancsAuthorized
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    // MARK: UUCBPeripheral implemenation
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    
    public var delegate: (any CBPeripheralDelegate)?
    
    public var name: String? = nil
    
    public var state: CBPeripheralState = .disconnected
    
    public var services: [CBService]? = nil
    
    public var canSendWriteWithoutResponse: Bool = true
    
    public var ancsAuthorized: Bool = false
    
    public func readRSSI()
    {
        
    }
    
    public func discoverServices(_ serviceUUIDs: [CBUUID]?)
    {
    }
    
    public func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, for service: CBService)
    {
        
    }
    
    public func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristic)
    {
        
    }
    
    public func readValue(for descriptor: CBDescriptor) {
        
    }
    
    public func discoverDescriptors(for characteristic: CBCharacteristic)
    {
        
    }
    
    public func readValue(for characteristic: CBCharacteristic)
    {
        
    }
    
    public func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBService)
    {
        
    }
    
    public func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int
    {
        return 20
    }
    
    public func writeValue(_ data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType)
    {
    }
    
    public func writeValue(_ data: Data, for descriptor: CBDescriptor)
    {
    }
    
    public func openL2CAPChannel(_ PSM: CBL2CAPPSM)
    {
    }
    
    public let identifier: UUID
}

#endif
