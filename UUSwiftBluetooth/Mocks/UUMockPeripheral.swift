//
//  UUMockPeripheral.swift
//  BluetoothExplorer
//
//  Created by Ryan DeVore on 11/10/24.
//

import Foundation
import CoreBluetooth
import UUSwiftCore


public class UUMockPeripheral: UUPeripheral
{
    public var identifier: UUID = UUID()
    
    public var advertisement: any UUAdvertisement = UUMockAdvertisement()
    
    public var rssi: Int = 0
    
    public var name: String = ""
    
    public var friendlyName: String = ""
    
    public var firstDiscoveryTime: Date = Date()
    
    public var peripheralState: CBPeripheralState = .disconnected
    
    public var services: [CBService]? = nil
    
    init(identifier: UUID = UUID(),
         advertisement: any UUAdvertisement = UUMockAdvertisement(),
         rssi: Int = 0,
         name: String = "",
         friendlyName: String = "",
         firstDiscoveryTime: Date = Date(),
         peripheralState: CBPeripheralState = .disconnected,
         services: [CBService]? = nil)
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
    public var mockCallbackTime: TimeInterval = 1.0
    
    ///
    /// Mock result
    ///
    public var mockCallbackError: Error? = nil
    
    public var mockMaximumWriteValueLengths: [CBCharacteristicWriteType:Int] = [.withResponse: 20, .withoutResponse: 20]
    
    private var disconnectCallback: UUPeripheralDisconnectedBlock? = nil
    private var notifyHandlers: [CBUUID:UUPeripheralCharacteristicErrorBlock] = [:]
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
    
    public func connect(timeout: TimeInterval, connected: @escaping UUPeripheralConnectedBlock, disconnected: @escaping UUPeripheralDisconnectedBlock)
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
    
    public func discoverServices(serviceUUIDs: [CBUUID]?, timeout: TimeInterval, completion: @escaping UUDiscoverServicesCompletionBlock)
    {
        dispatch
        {
            completion(self.mockServices, self.mockCallbackError)
        }
    }
    
    public func discoverCharacteristics(characteristicUUIDs: [CBUUID]?, for service: CBService, timeout: TimeInterval, completion: @escaping UUDiscoverCharacteristicsCompletionBlock)
    {
        dispatch
        {
            let result = self.lookupCharacteristics(service.uuid)
            completion(result, self.mockCallbackError)
        }
    }
    
    public func discoverIncludedServices(includedServiceUUIDs: [CBUUID]?, for service: CBService, timeout: TimeInterval, completion: @escaping UUPeripheralErrorBlock)
    {
        dispatch
        {
            //completion(self.mockIncludedServicesToDiscover?[service.uuid], self.mockIncludedServicesDiscoveryResult)
            completion(self, self.mockCallbackError)
        }
    }
    
    public func discoverDescriptorsForCharacteristic(for characteristic: CBCharacteristic, timeout: TimeInterval, completion: @escaping UUDiscoverDescriptorsCompletionBlock)
    {
        dispatch
        {
            let result = self.lookupDescriptors(characteristic.uuid)
            completion(result, self.mockCallbackError)
        }
    }
    
    public func setNotifyValue(enabled: Bool, for characteristic: CBCharacteristic, timeout: TimeInterval, notifyHandler: UUPeripheralCharacteristicErrorBlock?, completion: @escaping UUPeripheralCharacteristicErrorBlock)
    {
        dispatch
        {
            self.notifyHandlers[characteristic.uuid] = notifyHandler
            
            self.charNotifyMap[characteristic.uuid] = enabled
            
            completion(self, characteristic, self.mockCallbackError)
        }
    }
    
    public func readValue(for characteristic: CBCharacteristic, timeout: TimeInterval, completion: @escaping UUPeripheralCharacteristicErrorBlock)
    {
    }
    
    public func readValue(for descriptor: CBDescriptor, timeout: TimeInterval, completion: @escaping UUPeripheralDescriptorErrorBlock)
    {
    }
    
    public func writeValue(data: Data, for characteristic: CBCharacteristic, timeout: TimeInterval, completion: @escaping UUPeripheralCharacteristicErrorBlock)
    {
    }
    
    public func writeValueWithoutResponse(data: Data, for characteristic: CBCharacteristic, completion: @escaping UUPeripheralCharacteristicErrorBlock)
    {
    }
    
    public func writeValue(data: Data, for descriptor: CBDescriptor, timeout: TimeInterval, completion: @escaping UUPeripheralDescriptorErrorBlock)
    {
    }
    
    public func readRSSI(timeout: TimeInterval, completion: @escaping UUPeripheralIntegerErrorBlock)
    {
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
}

