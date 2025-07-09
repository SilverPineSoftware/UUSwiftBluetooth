//
//  UUPeripheralProtocol.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 12/16/24.
//

import Foundation
import CoreBluetooth
import UUSwiftCore

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
                 connected: @escaping UUVoidBlock,
                 disconnected: @escaping UUErrorBlock)
    
    func disconnect(timeout: TimeInterval)
    
    func discoverServices(serviceUUIDs: [CBUUID]?,
                          timeout: TimeInterval,
                          completion: @escaping UUListErrorBlock<UUCBService>)
    
    func discoverCharacteristics(
        characteristicUUIDs: [CBUUID]?,
        for service: UUCBService,
        timeout: TimeInterval,
        completion: @escaping UUListErrorBlock<UUCBCharacteristic>)
    
    func discoverIncludedServices(
        includedServiceUUIDs: [CBUUID]?,
        for service: UUCBService,
        timeout: TimeInterval,
        completion: @escaping UUListErrorBlock<UUCBService>)
    
    func discoverDescriptors(
        for characteristic: UUCBCharacteristic,
        timeout: TimeInterval,
        completion: @escaping UUListErrorBlock<UUCBDescriptor>)
    
//    func discover(
//        characteristics: [CBUUID]?,
//        for serviceUuid: CBUUID,
//        timeout: TimeInterval,
//        completion: @escaping UUDiscoverCharacteristicsCompletionBlock)
    
    func setNotifyValue(
        enabled: Bool,
        for characteristic: UUCBCharacteristic,
        timeout: TimeInterval,
        notifyHandler: UUObjectErrorBlock<Data>?,
        completion: @escaping UUErrorBlock)
    
    func readValue(
        for characteristic: UUCBCharacteristic,
        timeout: TimeInterval,
        completion: @escaping UUObjectErrorBlock<Data>)
    
    func readValue(
        for descriptor: UUCBDescriptor,
        timeout: TimeInterval,
        completion: @escaping UUObjectErrorBlock<Any>)
    
    func writeValue(
        data: Data,
        for characteristic: UUCBCharacteristic,
        timeout: TimeInterval,
        completion: @escaping UUErrorBlock)
    
    func writeValueWithoutResponse(
        data: Data,
        for characteristic: UUCBCharacteristic,
        completion: @escaping UUErrorBlock)
    
    func writeValue(
        data: Data,
        for descriptor: UUCBDescriptor,
        timeout: TimeInterval,
        completion: @escaping UUErrorBlock)
    
    func readRSSI(
        timeout: TimeInterval,
        completion: @escaping UUObjectErrorBlock<Int>)
    
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
