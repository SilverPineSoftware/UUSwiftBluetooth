//
//  UUPeripheralProtocol.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 12/16/24.
//

import Foundation
import CoreBluetooth
import UUSwiftCore

public typealias UUPeripheralConnectedBlock = (()->())
public typealias UUPeripheralDisconnectedBlock = ((Error?)->())
public typealias UUPeripheralBlock = ((UUPeripheral)->())
public typealias UUPeripheralErrorBlock = ((UUPeripheral, Error?)->())
public typealias UUPeripheralCharacteristicErrorBlock = ((UUPeripheral, CBCharacteristic, Error?)->())
public typealias UUPeripheralDescriptorErrorBlock = ((UUPeripheral, CBDescriptor, Error?)->())
public typealias UUPeripheralIntegerErrorBlock = ((UUPeripheral, Int, Error?)->())



public protocol UUPeripheral
{
    var advertisement: UUAdvertisement { get }
    var rssi: Int { get }
    var firstDiscoveryTime: Date { get }
    var timeSinceLastUpdate: TimeInterval { get }
    var identifier: UUID { get }
    var name: String { get }
    var friendlyName: String { get }
    var peripheralState: CBPeripheralState { get }
    var services: [CBService]? { get }
    
    func startTimer(name: String, timeout: TimeInterval, block: @escaping ()->())
    func cancelTimer(name: String)
    
    func maximumWriteValueLength(for writeType: CBCharacteristicWriteType) -> Int
    
    func connect(timeout: TimeInterval,
                 connected: @escaping UUPeripheralConnectedBlock,
                 disconnected: @escaping UUPeripheralDisconnectedBlock)
    
    func disconnect(timeout: TimeInterval)
    
    func discoverServices(serviceUUIDs: [CBUUID]?,
                          timeout: TimeInterval,
                          completion: @escaping UUListErrorBlock<CBService>)
    
    func discoverCharacteristics(
        characteristicUUIDs: [CBUUID]?,
        for service: CBService,
        timeout: TimeInterval,
        completion: @escaping UUListErrorBlock<CBCharacteristic>)
    
    func discoverIncludedServices(
        includedServiceUUIDs: [CBUUID]?,
        for service: CBService,
        timeout: TimeInterval,
        completion: @escaping UUListErrorBlock<CBService>)
    
    func discoverDescriptors(
        for characteristic: CBCharacteristic,
        timeout: TimeInterval,
        completion: @escaping UUListErrorBlock<CBDescriptor>)
    
//    func discover(
//        characteristics: [CBUUID]?,
//        for serviceUuid: CBUUID,
//        timeout: TimeInterval,
//        completion: @escaping UUDiscoverCharacteristicsCompletionBlock)
    
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
        return Date.timeIntervalSinceReferenceDate - advertisement.timestamp.timeIntervalSinceReferenceDate
    }
    
    // Convenience wrapper to perform both service and characteristic discovery at
    // one time.  This method is useful when you know both service and characteristic
    // UUID's ahead of time.
    /*func discover(
        characteristics: [CBUUID]?,
        for serviceUuid: CBUUID,
        timeout: TimeInterval,
        completion: @escaping UUDiscoverCharacteristicsCompletionBlock)
    {
        let start = Date().timeIntervalSinceReferenceDate
        
        discoverServices(serviceUUIDs: [serviceUuid], timeout: timeout)
        { discoveredServices, err in
            
            if let error = err
            {
                completion(nil, error)
                return
            }
            
            guard let foundService = discoveredServices?.filter({ $0.uuid.uuidString == serviceUuid.uuidString }).first else
            {
                // QUESTION: Should this emit a 'service not found error'
                completion(nil, err)
                return
            }
            
            let duration = Date().timeIntervalSinceReferenceDate - start
            let remainingTimeout = timeout - duration
            
            self.discoverCharacteristics(characteristicUUIDs: characteristics, for: foundService, timeout: remainingTimeout, completion: completion)
        }
    }*/
}


internal protocol UUPeripheralInternal
{
    func update(advertisement: UUAdvertisement)
}
