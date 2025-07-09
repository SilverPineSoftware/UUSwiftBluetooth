//
//  UUMockCBPeripheral.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 7/8/25.
//

import Foundation
import CoreBluetooth

public class UUMockCBPeripheral: UUCBPeripheral
{
    public var delegate: (any CBPeripheralDelegate)? = nil
    public var identifier: UUID = UUID()
    public var name: String? = nil
    public var state: CBPeripheralState = .disconnected
    
    public var services: [CBService]?
    {
        return backingPeripheral.services
    }
    
    public var canSendWriteWithoutResponse: Bool = true
    public var ancsAuthorized: Bool = true
    
    public var backingPeripheral: CBPeripheral
    
    
    
    // Configuration
    public var mockDispatchQueue: DispatchQueue = DispatchQueue(label: "UUMockCBPeripheral_DispatchQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .inherit, target: nil)
    
    // Mocked Values
    
    ///
    /// The mocked GATT database.  Fill Services and Characteristics
    ///
    public var mockServices: [CBMutableService] = []
    
    ///
    /// Number of seconds each api call will delay before returning an async result
    ///
    public var mockCallbackTime: TimeInterval = 0.01
    
    ///
    /// Mock result
    ///
    public var mockCallbackError: Error? = nil
    
    public var mockMaximumWriteValueLengths: [CBCharacteristicWriteType:Int] = [.withResponse: 20, .withoutResponse: 20]
    
    public var mockRssi: Int = 0
    
    public var mockL2CapChannel: CBL2CAPChannel? = nil
    
    
    
    
    public init(
        identifier: UUID = UUID(),
        name: String = "",
        state: CBPeripheralState = .disconnected,
        services: [CBMutableService]? = nil)
    {
        self.identifier = identifier
        self.name = name
        self.state = state
        //self.services = services
        
        backingPeripheral = UUMockCBPeripheral.makeCBPeripheral(
            uuid: identifier,
            name: name,
            services: services
        )!
    }
    
    
    private class func makeCBPeripheral(
        uuid: UUID? = nil,
        name: String? = nil,
        services: [CBMutableService]? = nil) -> CBPeripheral?
    {
        let peripheralClass = NSClassFromString("CBPeripheral") as? NSObject.Type
        guard let peripheral = peripheralClass?.init() as? CBPeripheral else
        {
            return nil
        }

        peripheral.addObserver(peripheral, forKeyPath: "delegate", options: [], context: nil)
        
        // Use KVC to set some properties
        
        if let uuid = uuid
        {
            peripheral.setValue(uuid, forKey: "identifier")
        }
        
        if let name = name
        {
            peripheral.setValue(name, forKey: "name")
        }
        
        if let services = services
        {
            peripheral.setValue(services, forKey: "services")
        }
        
        return peripheral
    }
    
    public func readRSSI()
    {
        dispatch
        {
            self.delegate?.peripheral?(self.backingPeripheral, didReadRSSI: NSNumber(integerLiteral: self.mockRssi), error: self.mockCallbackError)
        }
    }
    
    public func discoverServices(_ serviceUUIDs: [CBUUID]?)
    {
        dispatch
        {
            if let err = self.mockCallbackError
            {
                self.backingPeripheral.setValue(nil, forKey: "services")
                self.delegate?.peripheral?(self.backingPeripheral, didDiscoverServices: err)
            }
            else
            {
                let servicesWithNoChars = self.mockServices.map { CBMutableService(type: $0.uuid, primary: $0.isPrimary) }
                
                // Fill in the services of the backing peripheral with our 'mock' services, but exclude any characteristics because
                // they have not been discovered yet.
                self.backingPeripheral.setValue(servicesWithNoChars, forKey: "services")
                self.delegate?.peripheral?(self.backingPeripheral, didDiscoverServices: nil)
            }
        }
    }
    
    public func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, for service: CBService)
    {
        dispatch
        {
            self.delegate?.peripheral?(self.backingPeripheral, didDiscoverIncludedServicesFor: service, error: self.mockCallbackError)
        }
    }
    
    public func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBService)
    {
        dispatch
        {
            if let err = self.mockCallbackError
            {
                self.delegate?.peripheral?(self.backingPeripheral, didDiscoverCharacteristicsFor: service, error: err)
            }
            else
            {
                let svc = self.mockServices.first { $0.uuid == service.uuid }
                
                let chars = svc?.characteristics
                let resultChars = chars?.map { CBMutableCharacteristic(type: $0.uuid, properties: $0.properties, value: nil, permissions: []) }
                
                let resultService = CBMutableService(type: service.uuid, primary: service.isPrimary)
                resultService.characteristics = resultChars
                
                
                self.delegate?.peripheral?(self.backingPeripheral, didDiscoverCharacteristicsFor: resultService, error: nil)
            }
        }
    }
    
    public func readValue(for characteristic: CBCharacteristic)
    {
        dispatch
        {
            self.delegate?.peripheral?(self.backingPeripheral, didUpdateValueFor: characteristic, error: self.mockCallbackError)
        }
    }
    
    public func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int
    {
        return self.mockMaximumWriteValueLengths[type] ?? 0
    }
    
    public func writeValue(_ data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType)
    {
        dispatch
        {
            self.delegate?.peripheral?(self.backingPeripheral, didWriteValueFor: characteristic, error: self.mockCallbackError)
        }
    }
    
    public func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristic)
    {
        dispatch
        {
            self.delegate?.peripheral?(self.backingPeripheral, didUpdateNotificationStateFor: characteristic, error: self.mockCallbackError)
        }
    }
    
    public func discoverDescriptors(for characteristic: CBCharacteristic)
    {
        dispatch
        {
            self.delegate?.peripheral?(self.backingPeripheral, didDiscoverDescriptorsFor: characteristic, error: self.mockCallbackError)
        }
    }
    
    public func readValue(for descriptor: CBDescriptor)
    {
        dispatch
        {
            self.delegate?.peripheral?(self.backingPeripheral, didUpdateValueFor: descriptor, error: self.mockCallbackError)
        }
    }
    
    public func writeValue(_ data: Data, for descriptor: CBDescriptor)
    {
        dispatch
        {
            self.delegate?.peripheral?(self.backingPeripheral, didWriteValueFor: descriptor, error: self.mockCallbackError)
        }
    }
    
    public func openL2CAPChannel(_ PSM: CBL2CAPPSM)
    {
        dispatch
        {
            self.delegate?.peripheral?(self.backingPeripheral, didOpen: self.mockL2CapChannel, error: self.mockCallbackError)
        }
    }
    
    
    /*
    public func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, _ service: any UUCBService) -> (any Error)?
    {
        return nil
    }
    
    public func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, _ service: any UUCBService) -> (any Error)?
    {
        return nil
    }
    
    public func discoverDescriptors(_ characteristic: any UUCBCharacteristic) -> (any Error)?
    {
        return nil
    }
    
    public func setNotifyValue(_ enabled: Bool, for characteristic: any UUCBCharacteristic) -> (any Error)?
    {
        return nil
    }
    
    public func readValue(_ characteristic: any UUCBCharacteristic) -> (any Error)?
    {
        return nil
    }
    
    public func readValue(_ descriptor: any UUCBDescriptor) -> (any Error)?
    {
        return nil
    }
    
    public func writeCharacteristicValue(_ data: Data, _ characteristic: any UUCBCharacteristic, _ type: CBCharacteristicWriteType) -> (any Error)?
    {
        return nil
    }
    
    public func writeDescriptorValue(_ data: Data, _ descriptor: any UUCBDescriptor) -> (any Error)?
    {
        return nil
    }*/
    
    
    
    
    
    private func dispatch(_ block: @escaping ()->Void)
    {
        mockDispatchQueue.asyncAfter(deadline: .now() + .milliseconds(Int(self.mockCallbackTime * 1000.0)), execute: block)
    }
}
