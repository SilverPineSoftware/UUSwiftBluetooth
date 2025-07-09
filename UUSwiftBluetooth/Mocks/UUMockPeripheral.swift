//
//  UUMockPeripheral.swift
//  BluetoothExplorer
//
//  Created by Ryan DeVore on 11/10/24.
//

import Foundation
import CoreBluetooth
import UUSwiftCore

fileprivate let LOG_TAG = "UUMockPeripheral"

public class UUMockPeripheral: UUPeripheral
{
    public var identifier: UUID = UUID()
    
    public var advertisement: UUAdvertisement = UUAdvertisement()
    
    public var rssi: Int = 0
    
    public var name: String = ""
    
    public var friendlyName: String = ""
    
    public var firstDiscoveryTime: Date = Date()
    
    public var peripheralState: CBPeripheralState = .disconnected
    
    public var services: [UUCBService]? = nil
    
    public init(identifier: UUID = UUID(),
         advertisement: UUAdvertisement = UUAdvertisement(),
         rssi: Int = 0,
         name: String = "",
         friendlyName: String = "",
         firstDiscoveryTime: Date = Date(),
         peripheralState: CBPeripheralState = .disconnected,
         services: [UUCBService]? = nil)
    {
        self.advertisement = advertisement
        self.rssi = rssi
        self.firstDiscoveryTime = firstDiscoveryTime
        self.identifier = identifier
        self.name = name
        self.friendlyName = friendlyName
        self.peripheralState = peripheralState
        self.services = services
    }
    
    
    
    
    // Configuration
    public var mockDispatchQueue: DispatchQueue = DispatchQueue(label: "UUMockPeripheral_DispatchQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .inherit, target: nil)
    
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
    
    private var disconnectCallback: UUErrorBlock? = nil
    private var notifyHandlers: [CBUUID:UUObjectErrorBlock<Data>] = [:]
    private var charNotifyMap: [CBUUID:Bool] = [:]
    
    public func startTimer(name: String, timeout: TimeInterval, block: @escaping () -> ())
    {
        UUTimerPool.shared.start(identifier: name, timeout: timeout, userInfo: nil)
        { _ in
            block()
        }
    }
    
    public func cancelTimer(name: String)
    {
        UUTimerPool.shared.cancel(by: name)
    }
    
    public func maximumWriteValueLength(for writeType: CBCharacteristicWriteType) -> Int
    {
        return mockMaximumWriteValueLengths[writeType] ?? 0
    }
    
    public func connect(timeout: TimeInterval, connected: @escaping UUVoidBlock, disconnected: @escaping UUErrorBlock)
    {
        self.disconnectCallback = disconnected
        
        dispatch
        {
            if let result = self.mockCallbackError
            {
                disconnected(result)
            }
            else
            {
                connected()
            }
        }
    }
    
    public func disconnect(timeout: TimeInterval)
    {
        dispatch
        {
            let block = self.disconnectCallback
            self.disconnectCallback = nil
            block?(self.mockCallbackError)
        }
    }
    
    public func discoverServices(
        serviceUUIDs: [CBUUID]?,
        timeout: TimeInterval,
        completion: @escaping UUListErrorBlock<UUCBService>)
    {
        dispatch
        {
            // In iOS initial service discovery won't include any characteristics, so we'll extract out just
            // the services and return them here.
            var servicesWithNoChars: [CBMutableService]? = self.mockServices.map { CBMutableService(type: $0.uuid, primary: $0.isPrimary) }
            if (self.mockCallbackError != nil)
            {
                servicesWithNoChars = nil
            }
            
            completion(servicesWithNoChars, self.mockCallbackError)
        }
    }
    
    public func discoverCharacteristics(
        characteristicUUIDs: [CBUUID]?,
        for service: UUCBService,
        timeout: TimeInterval,
        completion: @escaping UUListErrorBlock<UUCBCharacteristic>)
    {
        dispatch
        {
            // In iOS initial characteristic discovery won't include any descriptors, so we'll extract out just
            // the chars and return them here.
            //let servicesWithNoChars = self.mockServices.map { CBMutableService(type: $0.uuid, primary: $0.isPrimary) }
            
            let lookup = self.lookupCharacteristics(service.uuid)
            var result = lookup?.map {
                CBMutableCharacteristic(type: $0.uuid, properties: $0.properties, value: nil, permissions: [])
            }
            
            if (self.mockCallbackError != nil)
            {
                result = nil
            }
            else if (result == nil)
            {
                // core blueooth when no charactistics are found for a service will return no error and an empty array
                result = []
            }
            
            completion(result, self.mockCallbackError)
        }
    }
    
    public func discoverIncludedServices(
        includedServiceUUIDs: [CBUUID]?,
        for service: UUCBService,
        timeout: TimeInterval,
        completion: @escaping UUListErrorBlock<UUCBService>)
    {
        dispatch
        {
            // In iOS initial service discovery won't include any characteristics, so we'll extract out just
            // the services and return them here.
            let filteredServices = self.mockServices.filter { $0.uuid == service.uuid }
            var servicesWithNoChars: [CBMutableService]? = filteredServices.map { CBMutableService(type: $0.uuid, primary: $0.isPrimary) }
            if (self.mockCallbackError != nil)
            {
                servicesWithNoChars = nil
            }
            
            completion(servicesWithNoChars, self.mockCallbackError)
        }
    }
    
    public func discoverDescriptors(
        for characteristic: UUCBCharacteristic,
        timeout: TimeInterval,
        completion: @escaping UUListErrorBlock<UUCBDescriptor>)
    {
        dispatch
        {
            var result = self.lookupDescriptors(characteristic.uuid)
            
            if (self.mockCallbackError != nil)
            {
                result = nil
            }
            
            completion(result, self.mockCallbackError)
        }
    }
    
    public func setNotifyValue(
        enabled: Bool,
        for characteristic: UUCBCharacteristic,
        timeout: TimeInterval,
        notifyHandler: UUObjectErrorBlock<Data>?,
        completion: @escaping UUErrorBlock)
    {
        dispatch
        {
            self.notifyHandlers[characteristic.uuid] = notifyHandler
            
            self.charNotifyMap[characteristic.uuid] = enabled
            
            completion(self.mockCallbackError)
        }
    }
    
    public func readValue(
        for characteristic: UUCBCharacteristic,
        timeout: TimeInterval,
        completion: @escaping UUObjectErrorBlock<Data>)
    {
        dispatch
        {
            completion(characteristic.value, self.mockCallbackError)
        }
    }
    
    public func readValue(
        for descriptor: UUCBDescriptor,
        timeout: TimeInterval,
        completion: @escaping UUObjectErrorBlock<Any>)
    {
        dispatch
        {
            completion(descriptor.value, self.mockCallbackError)
        }
    }
    
    public func writeValue(
        data: Data,
        for characteristic: UUCBCharacteristic,
        timeout: TimeInterval,
        completion: @escaping UUErrorBlock)
    {
        dispatch
        {
            if let mutableChar = characteristic as? CBMutableCharacteristic
            {
                mutableChar.value = data
            }
            
            completion(self.mockCallbackError)
        }
    }
    
    public func writeValueWithoutResponse(
        data: Data,
        for characteristic: UUCBCharacteristic,
        completion: @escaping UUErrorBlock)
    {
        dispatch
        {
            if let mutableChar = characteristic as? CBMutableCharacteristic
            {
                mutableChar.value = data
            }
            
            completion(self.mockCallbackError)
        }
    }
    
    public func writeValue(
        data: Data,
        for descriptor: UUCBDescriptor,
        timeout: TimeInterval,
        completion: @escaping UUErrorBlock)
    {
        dispatch
        {
            self.replaceDescriptor(descriptor, data)
            completion(self.mockCallbackError)
        }
    }
    
    public func readRSSI(timeout: TimeInterval, completion: @escaping UUObjectErrorBlock<Int>)
    {
        dispatch
        {
            self.rssi = self.mockRssi
            completion(self.rssi, self.mockCallbackError)
        }
    }
    
    public func openL2CAPChannel(psm: CBL2CAPPSM)
    {
    }
    
    public func setDidOpenL2ChannelCallback(callback: ((CBPeripheral, CBL2CAPChannel?, (any Error)?) -> Void)?)
    {
    }
    
    
    
    private func dispatch(_ block: @escaping ()->Void)
    {
        mockDispatchQueue.asyncAfter(deadline: .now() + .milliseconds(Int(self.mockCallbackTime * 1000.0)), execute: block)
    }
    
    private func lookupCharacteristics(_ uuid: CBUUID) -> [CBCharacteristic]?
    {
        return self.mockServices.first { $0.uuid == uuid }?.characteristics
    }
    
    private func lookupCharacteristic(_ uuid: CBUUID) -> CBCharacteristic?
    {
        return lookupCharacteristics(uuid)?.first { $0.uuid == uuid }
    }
    
    private func lookupDescriptors(_ uuid: CBUUID) -> [CBDescriptor]?
    {
        return lookupCharacteristic(uuid)?.descriptors
    }
    
    private func replaceDescriptor(_ descriptor: UUCBDescriptor, _ value: Any?)
    {
        for svc in self.mockServices
        {
            for chr in svc.characteristics ?? []
            {
                if let mutableChar = chr as? CBMutableCharacteristic
                {
                    if var descriptors = mutableChar.descriptors
                    {
                        if let index = descriptors.firstIndex(where: {$0.uuid == descriptor.uuid })
                        {
                            //chr.descriptors?[index] = CBMutableDescriptor(type: descriptor.uuid, value: value)
                            descriptors[index] = CBMutableDescriptor(type: descriptor.uuid, value: value)
                        }
                        
                        mutableChar.descriptors = descriptors
                    }
                }
            }
        }
    }
}

public extension UUDescriptorRepresentation // Mock Support
{
    var mockDescriptor: CBMutableDescriptor
    {
        NSLog("descriptor: \(self.uuToJsonString())")
        return CBMutableDescriptor(type: CBUUID(string: self.uuid), value: mockData())
    }
    
    private func mockData() -> Any?
    {
        if (self.uuid == "2904")
        {
            return Data()
        }
        
        if (self.uuid == "2901")
        {
            return String()
        }
        
        return nil
    }
}

public extension UUCharacteristicRepresentation // Mock Support
{
    var mockCharacteristic: CBMutableCharacteristic
    {
        let props = CBCharacteristicProperties(uuDescription: self.properties)
        let char = CBMutableCharacteristic(type: CBUUID(string: self.uuid), properties: props, value: nil, permissions: [])
        char.descriptors = self.descriptors?.compactMap { $0.mockDescriptor }
        return char
    }
}

public extension UUServiceRepresentation // Mock Support
{
    var mockService: CBMutableService
    {
        let svc = CBMutableService(type: CBUUID(string: self.uuid), primary: self.isPrimary ?? false)
        svc.characteristics = self.characteristics?.compactMap { $0.mockCharacteristic }
        svc.includedServices = self.includedServices?.compactMap { $0.mockService }
        return svc
    }
}

public extension UUPeripheralRepresentation // Mock Support
{
    var mockPeripheral: UUMockPeripheral
    {
        let p = UUMockPeripheral()
        p.mockServices = self.services?.compactMap(\.mockService) ?? []
        return p
    }
}


