//
//  MockPeripheral.swift
//  UUSwiftBluetoothTests
//
//  Created by Ryan DeVore on 5/8/25.
//

#if DEBUG

import Foundation
import UUSwiftBluetooth
import CoreBluetooth

open class MockPeripheral: UUPeripheral
{
    convenience init(
        advertisement: UUAdvertisement = MockAdvertisement(),
        identifier: UUID = UUID(),
        rssi: Int = 0,
        name: String = "",
        friendlyName: String = "",
        firstDiscoveryTime: Date = Date(),
        peripheralState: CBPeripheralState = .disconnected,
        services: [CBService]? = nil)
    {
        self.init()
        
        self.advertisement = advertisement
        self.rssi = rssi
        self.firstDiscoveryTime = firstDiscoveryTime
        self.identifier = identifier
        self.name = name
        self.friendlyName = friendlyName
        self.peripheralState = peripheralState
        self.services = services
    }
    
    // UUPeripheral
    public var advertisement: UUAdvertisement = MockAdvertisement()
    public var rssi: Int = 0
    public var firstDiscoveryTime: Date = Date()
    public var identifier: UUID = UUID()
    public var name: String = ""
    public var friendlyName: String = ""
    public var peripheralState: CBPeripheralState = .disconnected
    public var services: [CBService]? = nil
    
    public func connect(timeout: TimeInterval, connected: @escaping UUSwiftBluetooth.UUPeripheralConnectedBlock, disconnected: @escaping UUSwiftBluetooth.UUPeripheralDisconnectedBlock)
    {
    }
    
    public func disconnect(timeout: TimeInterval)
    {
    }
    
    public func startTimer(name: String, timeout: TimeInterval, block: @escaping () -> ())
    {
    }
    
    public func cancelTimer(name: String)
    {
        
    }
    
    public func discoverServices(serviceUUIDs: [CBUUID]?, timeout: TimeInterval, completion: @escaping UUSwiftBluetooth.UUDiscoverServicesCompletionBlock)
    {
    }
    
    public func discoverCharacteristics(characteristicUUIDs: [CBUUID]?, for service: CBService, timeout: TimeInterval, completion: @escaping UUSwiftBluetooth.UUDiscoverCharacteristicsCompletionBlock)
    {
    }
    
    public func discoverIncludedServices(includedServiceUUIDs: [CBUUID]?, for service: CBService, timeout: TimeInterval, completion: @escaping UUSwiftBluetooth.UUPeripheralErrorBlock)
    {
    }
    
    public func discoverDescriptorsForCharacteristic(for characteristic: CBCharacteristic, timeout: TimeInterval, completion: @escaping UUSwiftBluetooth.UUDiscoverDescriptorsCompletionBlock)
    {
    }
    
    public func discover(characteristics: [CBUUID]?, for serviceUuid: CBUUID, timeout: TimeInterval, completion: @escaping UUSwiftBluetooth.UUDiscoverCharacteristicsCompletionBlock)
    {
    }
    
    public func setNotifyValue(enabled: Bool, for characteristic: CBCharacteristic, timeout: TimeInterval, notifyHandler: UUSwiftBluetooth.UUPeripheralCharacteristicErrorBlock?, completion: @escaping UUSwiftBluetooth.UUPeripheralCharacteristicErrorBlock)
    {
    }
    
    public func readValue(for characteristic: CBCharacteristic, timeout: TimeInterval, completion: @escaping UUSwiftBluetooth.UUPeripheralCharacteristicErrorBlock)
    {
    }
    
    public func readValue(for descriptor: CBDescriptor, timeout: TimeInterval, completion: @escaping UUSwiftBluetooth.UUPeripheralDescriptorErrorBlock)
    {
    }
    
    public func writeValue(data: Data, for characteristic: CBCharacteristic, timeout: TimeInterval, completion: @escaping UUSwiftBluetooth.UUPeripheralCharacteristicErrorBlock)
    {
    }
    
    public func writeValueWithoutResponse(data: Data, for characteristic: CBCharacteristic, completion: @escaping UUSwiftBluetooth.UUPeripheralCharacteristicErrorBlock)
    {
    }
    
    public func writeValue(data: Data, for descriptor: CBDescriptor, timeout: TimeInterval, completion: @escaping UUSwiftBluetooth.UUPeripheralDescriptorErrorBlock)
    {
    }
    
    public func readRSSI(timeout: TimeInterval, completion: @escaping UUSwiftBluetooth.UUPeripheralIntegerErrorBlock)
    {
    }
    
    public func openL2CAPChannel(psm: CBL2CAPPSM)
    {
    }
    
    public func setDidOpenL2ChannelCallback(callback: ((CBPeripheral, CBL2CAPChannel?, (any Error)?) -> Void)?)
    {
    }
}

#endif
