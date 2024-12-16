//
//  UUPeripheralProtocol.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 12/16/24.
//

import UIKit
import CoreBluetooth

public typealias UUPeripheralConnectedBlock = (()->())
public typealias UUPeripheralDisconnectedBlock = ((Error?)->())
public typealias UUPeripheralBlock = ((UUPeripheral)->())
public typealias UUPeripheralErrorBlock = ((UUPeripheral, Error?)->())
public typealias UUPeripheralCharacteristicErrorBlock = ((UUPeripheral, CBCharacteristic, Error?)->())
public typealias UUPeripheralDescriptorErrorBlock = ((UUPeripheral, CBDescriptor, Error?)->())
public typealias UUPeripheralIntegerErrorBlock = ((UUPeripheral, Int, Error?)->())
public typealias UUDiscoverServicesCompletionBlock = (([CBService]?, Error?)->())
public typealias UUDiscoverCharacteristicsCompletionBlock = (([CBCharacteristic]?, Error?)->())
public typealias UUDiscoverDescriptorsCompletionBlock = (([CBDescriptor]?, Error?)->())

public protocol UUPeripheral
{
    var advertisement: UUAdvertisementProtocol?  { get }
    var rssi: Int?  { get }
    var firstDiscoveryTime: Date  { get }
    var timeSinceLastUpdate: TimeInterval { get }
    var identifier: UUID { get }
    var name: String { get }
    var friendlyName: String { get }
    var peripheralState: CBPeripheralState { get }
    var services: [CBService]? { get }
    
    func connect(timeout: TimeInterval,
                 connected: @escaping UUPeripheralConnectedBlock,
                 disconnected: @escaping UUPeripheralDisconnectedBlock)
    
    func disconnect(timeout: TimeInterval)
    
    func discoverServices(serviceUUIDs: [CBUUID]?,
                          timeout: TimeInterval,
                          completion: @escaping UUDiscoverServicesCompletionBlock)
    
    func discoverCharacteristics(
        characteristicUUIDs: [CBUUID]?,
        for service: CBService,
        timeout: TimeInterval,
        completion: @escaping UUDiscoverCharacteristicsCompletionBlock)
    
    func discoverIncludedServices(
        includedServiceUUIDs: [CBUUID]?,
        for service: CBService,
        timeout: TimeInterval,
        completion: @escaping UUPeripheralErrorBlock)
    
    func discoverDescriptorsForCharacteristic(
        for characteristic: CBCharacteristic,
        timeout: TimeInterval,
        completion: @escaping UUDiscoverDescriptorsCompletionBlock)
    
    func discover(
        characteristics: [CBUUID]?,
        for serviceUuid: CBUUID,
        timeout: TimeInterval,
        completion: @escaping UUDiscoverCharacteristicsCompletionBlock)
    
    func setNotifyValue(
        enabled: Bool,
        for characteristic: CBCharacteristic,
        timeout: TimeInterval,
        notifyHandler: UUPeripheralCharacteristicErrorBlock?,
        completion: @escaping UUPeripheralCharacteristicErrorBlock)
    
    func readValue(for characteristic: CBCharacteristic,
                   timeout: TimeInterval,
                   completion: @escaping UUPeripheralCharacteristicErrorBlock)
    
    func readValue(
        for descriptor: CBDescriptor,
        timeout: TimeInterval,
        completion: @escaping UUPeripheralDescriptorErrorBlock)
    
    func writeValue(
        data: Data,
        for characteristic: CBCharacteristic,
        timeout: TimeInterval,
        completion: @escaping UUPeripheralCharacteristicErrorBlock)
    
    func writeValueWithoutResponse(
        data: Data,
        for characteristic: CBCharacteristic,
        completion: @escaping UUPeripheralCharacteristicErrorBlock)
    
    func writeValue(
        data: Data,
        for descriptor: CBDescriptor,
        timeout: TimeInterval,
        completion: @escaping UUPeripheralDescriptorErrorBlock)
    
    func readRSSI(
        timeout: TimeInterval,
        completion: @escaping UUPeripheralIntegerErrorBlock)
    
    // These need to be internal
    func openL2CAPChannel(psm: CBL2CAPPSM)
    
    func setDidOpenL2ChannelCallback(callback:((CBPeripheral, CBL2CAPChannel?, Error?) -> Void)?)
}


public extension UUPeripheral
{
    var timeSinceLastUpdate: TimeInterval
    {
        guard let lastBeaconTime = advertisement?.timestamp else
        {
            return 0
        }
    
        return Date.timeIntervalSinceReferenceDate - lastBeaconTime.timeIntervalSinceReferenceDate
    }
}


internal protocol UUPeripheralInternal
{
    //var underlyingPeripheral: CBPeripheral { get }
    
    func update(advertisement: UUBluetoothAdvertisement)
}
