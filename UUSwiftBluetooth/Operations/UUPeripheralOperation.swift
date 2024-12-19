//
//  UUPeripheralOperation.swift
//  
//
//  Created by Ryan DeVore on 10/28/21.
//

import Foundation
import CoreBluetooth
import UUSwiftCore

open class UUPeripheralOperation<Result>
{
    public let peripheral: UUPeripheral
    private var operationError: Error? = nil
    private var operationCallback: ((Result?, Error?)->())? = nil
    public var discoveredServices: [CBService] = []
    public var discoveredCharacteristics: [CBCharacteristic] = []
    public var discoveredDescriptors: [CBDescriptor] = []
    
    private var servicesNeedingCharacteristicDiscovery: [CBService] = []
    private var characteristicsNeedingDescriptorDiscovery: [CBCharacteristic] = []
    
    public var connectTimeout: TimeInterval = UUCoreBluetooth.Defaults.connectTimeout
    public var disconnectTimeout: TimeInterval = UUCoreBluetooth.Defaults.disconnectTimeout
    public var serviceDiscoveryTimeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout
    public var characteristicDiscoveryTimeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout
    public var descriptorDiscoveryTimeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout
    public var readTimeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout
    public var writeTimeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout
    
    private(set) public var operationResult: Result? = nil
    
    private let connectTimeMeasurement = UUTimeMeasurement(name: "connectTime")
    private let serviceDiscoveryTimeMeasurement = UUTimeMeasurement(name: "serviceDiscoveryTime")
    private let characteristicDiscoveryTimeMeasurement = UUTimeMeasurement(name: "characteristicDiscoveryTime")
    private let descriptorDiscoveryTimeMeasurement = UUTimeMeasurement(name: "descriptorDiscoveryTime")
    
    public init(_ peripheral: UUPeripheral)
    {
        self.peripheral = peripheral
    }
    
    public func start(_ completion: @escaping(Result?, Error?)->())
    {
        self.operationError = nil
        self.operationCallback = completion
        
        self.connectTimeMeasurement.start()
        peripheral.connect(timeout: connectTimeout, connected: handleConnected, disconnected: handleDisconnection)
    }
    
    public func end(result: Result?, error: Error?)
    {
        UUDebugLog("**** Ending Operation with result: \(String(describing: result)),  error: \(error?.localizedDescription ?? "nil")")
        self.operationResult = result
        self.operationError = error
        peripheral.disconnect(timeout: disconnectTimeout)
    }
    
    open func execute(_ completion: @escaping (Result?, Error?)->())
    {
        completion(nil, nil)
    }
    
    public func write(data: Data, toCharacteristic: CBUUID, completion: @escaping ()->())
    {
        requireDiscoveredCharacteristic(for: toCharacteristic)
        { char in
            
            self.peripheral.writeValue(data: data, for: char, timeout: self.writeTimeout)
            { p, char, error in
                
                if let err = error
                {
                    UUDebugLog("write failed, ending operation with error: \(err)")
                    self.end(result: nil, error: err)
                    return
                }
                
                completion()
            }
        }
    }
    
    public func wwor(data: Data, toCharacteristic: CBUUID, completion: @escaping ()->())
    {
        requireDiscoveredCharacteristic(for: toCharacteristic)
        { char in
            
            self.peripheral.writeValueWithoutResponse(data: data, for: char)
            { p, char, error in
                
                if let err = error
                 {
                    UUDebugLog("WWOR failed, ending operation with error: \(err)")
                    self.end(result: nil, error: err)
                    return
                }
                
                completion()
            }
        }
    }
    
    public func read(from characteristic: CBUUID, completion: @escaping (Data?)->())
    {
        requireDiscoveredCharacteristic(for: characteristic)
        { char in
            
            self.peripheral.readValue(for: char, timeout: self.readTimeout, completion:
            { p, char, error in
                
                if let err = error
                {
                    UUDebugLog("read failed, ending operation with error: \(err)")
                    self.end(result: nil, error: err)
                    return
                }
                
                completion(char.value)
            })
        }
    }
    
    public func readString(from characteristic: CBUUID, encoding: String.Encoding, completion: @escaping (String?)->())
    {
        read(from: characteristic)
        { data in
         
            var result: String? = nil
            
            if let data = data
            {
                result = String(data: data, encoding: encoding)
            }
            
            completion(result)
        }
    }
    
    public func readUtf8(from characteristic: CBUUID, completion: @escaping (String?)->())
    {
        readString(from: characteristic, encoding: .utf8, completion: completion)
    }
    
    public func readUInt8(from characteristic: CBUUID,  completion: @escaping (UInt8?)->())
    {
        read(from: characteristic)
        { data in
         
            let result = data?.uuUInt8(at: 0)
            completion(result)
        }
    }
    
    public func readUInt16(from characteristic: CBUUID, completion: @escaping (UInt16?)->())
    {
        read(from: characteristic)
        { data in
         
            let result = data?.uuUInt16(at: 0)
            completion(result)
        }
    }
    
    public func readUInt32(from characteristic: CBUUID, completion: @escaping (UInt32?)->())
    {
        read(from: characteristic)
        { data in
         
            let result = data?.uuUInt32(at: 0)
            completion(result)
        }
    }
    
    public func readUInt64(from characteristic: CBUUID, completion: @escaping (UInt64?)->())
    {
        read(from: characteristic)
        { data in
         
            let result = data?.uuUInt64(at: 0)
            completion(result)
        }
    }
    
    public func readInt8(from characteristic: CBUUID, completion: @escaping (Int8?)->())
    {
        read(from: characteristic)
        { data in
         
            let result = data?.uuInt8(at: 0)
            completion(result)
        }
    }
    
    public func readInt16(from characteristic: CBUUID, completion: @escaping (Int16?)->())
    {
        read(from: characteristic)
        { data in
         
            let result = data?.uuInt16(at: 0)
            completion(result)
        }
    }
    
    public func readInt32(from characteristic: CBUUID, completion: @escaping (Int32?)->())
    {
        read(from: characteristic)
        { data in
         
            let result = data?.uuInt32(at: 0)
            completion(result)
        }
    }
    
    public func readInt32(from characteristic: CBUUID, completion: @escaping (Int64?)->())
    {
        read(from: characteristic)
        { data in
         
            let result = data?.uuInt64(at: 0)
            completion(result)
        }
    }
    
    public func write(string: String, with encoding: String.Encoding, to characteristic: CBUUID, completion: @escaping ()->())
    {
        var data = Data()
        data.uuAppend(string, encoding: encoding)
        
        write(data: data, toCharacteristic: characteristic, completion: completion)
    }
    
    public func writeUtf8(string: String, to characteristic: CBUUID, completion: @escaping ()->())
    {
        write(string: string, with: .utf8, to: characteristic, completion: completion)
    }
    
    public func write<T: FixedWidthInteger>(integer: T, to characteristic: CBUUID, completion: @escaping ()->())
    {
        var data = Data()
        data.uuAppend(integer)
        write(data: data, toCharacteristic: characteristic, completion: completion)
    }
    
    public func startListeningForDataChanges(from characteristic: CBUUID, dataChanged: @escaping (Data?)->(), completion: @escaping ()->())
    {
        requireDiscoveredCharacteristic(for: characteristic)
        { char in
            self.peripheral.setNotifyValue(enabled: true, for: char, timeout: self.readTimeout)
            { p, char, err in
                
                if let e = err
                {
                    self.end(result: nil, error: err)
                    return
                }
                
                dataChanged(char.value)
                
            } completion:
            { p, char, err in
                
                if let e = err
                {
                    self.end(result: nil, error: err)
                    return
                }
                
                completion()
            }
        }
    }
    
    public func stopListeningForDataChanges(from characteristic: CBUUID, completion: @escaping ()->())
    {
        requireDiscoveredCharacteristic(for: characteristic)
        { char in
            
            self.peripheral.setNotifyValue(enabled: false, for: char, timeout: self.readTimeout, notifyHandler: nil)
            { p, char, err in
                
                if let e = err
                {
                    self.end(result: nil, error: err)
                    return
                }
                
                completion()
            }
        }
    }
    
    open var servicesToDiscover: [CBUUID]?
    {
        return nil
    }
    
    open func characteristicsToDiscover(for service: CBUUID) -> [CBUUID]?
    {
        return nil
    }
    
    public func findDiscoveredService(for uuid: CBUUID) -> CBService?
    {
        return discoveredServices.filter({ $0.uuid == uuid }).first
    }
    
    public func findDiscoveredCharacteristic(for uuid: CBUUID) -> CBCharacteristic?
    {
        return discoveredCharacteristics.filter({ $0.uuid == uuid }).first
    }
    
    public func requireDiscoveredService(for uuid: CBUUID, _ completion: @escaping (CBService)->())
    {
        guard let discovered = findDiscoveredService(for: uuid) else
        {
            let err = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Required service \(uuid.uuidString) not found"])
            UUDebugLog("Required Service not found, ending operation with error: \(err)")
            self.end(result: nil, error: err)
            return
        }
        
        completion(discovered)
    }
    
    public func requireDiscoveredCharacteristic(for uuid: CBUUID, _ completion: @escaping (CBCharacteristic)->())
    {
        guard let discovered = findDiscoveredCharacteristic(for: uuid) else
        {
            let err = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Required characteristic \(uuid.uuidString) not found"])
            UUDebugLog("Required Characteristic not found, ending operation with error: \(err)")
            self.end(result: nil, error: err)
            return
        }
        
        completion(discovered)
    }
    
    private func handleConnected()
    {
        self.connectTimeMeasurement.end()
        startServiceDiscovery()
    }
    
    private func startServiceDiscovery()
    {
        self.serviceDiscoveryTimeMeasurement.start()
        
        peripheral.discoverServices(serviceUUIDs: servicesToDiscover, timeout: serviceDiscoveryTimeout)
        { services, error in
            
            self.serviceDiscoveryTimeMeasurement.end()
            
            if let err = error
            {
                UUDebugLog("Service Discovery Failed, ending operation with error: \(err)")
                self.end(result: nil, error: err)
                return
            }
            
            self.discoveredServices.removeAll()
            self.discoveredCharacteristics.removeAll()
            self.servicesNeedingCharacteristicDiscovery.removeAll()
            
            guard let services = services else
            {
                let err = NSError(domain: "Err", code: -1, userInfo: [NSLocalizedDescriptionKey: "No services were discovered"])
                UUDebugLog("Service Discovery Failed to discover any services, ending operation with error: \(err)")
                self.end(result: nil, error: err)
                return
            }
            
            self.discoveredServices.append(contentsOf: services)
            self.servicesNeedingCharacteristicDiscovery.append(contentsOf: services)
            self.startCharacteristicDiscovery()
        }
    }
    
    private func startCharacteristicDiscovery()
    {
        self.characteristicDiscoveryTimeMeasurement.start()
        self.discoverNextCharacteristics()
    }
    
    private func startDescriptorDiscovery()
    {
        self.descriptorDiscoveryTimeMeasurement.start()
        self.discoverNextDescriptors()
    }
    
    private func discoverNextCharacteristics()
    {
        guard let service = servicesNeedingCharacteristicDiscovery.popLast() else
        {
            self.handleCharacteristicDiscoveryFinished()
            return
        }
        
        discoverCharacteristics(for: service)
        {
            self.discoverNextCharacteristics()
        }
    }
    
    private func discoverCharacteristics(for service: CBService, _ completion: @escaping ()->())
    {
        peripheral.discoverCharacteristics(characteristicUUIDs: characteristicsToDiscover(for: service.uuid), for: service, timeout: characteristicDiscoveryTimeout)
        { characteristics, error in
            
            if let err = error
            {
                UUDebugLog("Characteristic Discovery Failed, ending operation with error: \(err)")
                self.end(result: nil, error: err)
                return
            }
            
            UUDebugLog("Finished characteristic discovery for \(service.uuid.uuidString), found \(characteristics?.count ?? 0) characteristics. Characteristics: \(characteristics?.map(\.uuid.uuidString) ?? []).")
            if let characteristics = characteristics
            {
                self.discoveredCharacteristics.append(contentsOf: characteristics)
            }
            
            completion()
        }
    }
    
    private func discoverNextDescriptors()
    {
        guard let characteristic = characteristicsNeedingDescriptorDiscovery.popLast() else
        {
            self.handleDescriptorDiscoveryFinished()
            return
        }
        
        discoverDescriptors(for: characteristic)
        {
            self.discoverNextDescriptors()
        }
    }
    
    private func discoverDescriptors(for characteristic: CBCharacteristic, _ completion: @escaping ()->())
    {
        peripheral.discoverDescriptorsForCharacteristic(for: characteristic, timeout: descriptorDiscoveryTimeout)
        { descriptors, error in
            
            if let err = error
            {
                UUDebugLog("Descriptor Discovery Failed, ending operation with error: \(err)")
                self.end(result: nil, error: err)
                return
            }
            
            UUDebugLog("Finished descriptor discovery for \(characteristic.uuid.uuidString), found \(characteristic.descriptors?.count ?? 0) descriptors. Descriptors: \(descriptors?.map(\.uuid.uuidString) ?? []).")
            if let descriptors = descriptors
            {
                self.discoveredDescriptors.append(contentsOf: descriptors)
            }
            
            completion()
        }
    }
    
    private func handleDisconnection(_ disconnectError: Error?)
    {
        if (self.operationError == nil)
        {
            self.operationError = disconnectError
        }
        
        let callback = self.operationCallback
        let err = self.operationError
        let result = self.operationResult
        self.operationCallback = nil
        callback?(result, err)
    }
    
    private func handleCharacteristicDiscoveryFinished()
    {
        self.characteristicDiscoveryTimeMeasurement.end()
        self.characteristicsNeedingDescriptorDiscovery.append(contentsOf: discoveredCharacteristics)
        self.startDescriptorDiscovery()
    }
    
    private func handleDescriptorDiscoveryFinished()
    {
        self.descriptorDiscoveryTimeMeasurement.end()
        internalExecute()
    }
    
    private func internalExecute()
    {
        UUDebugLog("\(connectTimeMeasurement)")
        UUDebugLog("\(serviceDiscoveryTimeMeasurement)")
        UUDebugLog("\(characteristicDiscoveryTimeMeasurement)")
        UUDebugLog("\(descriptorDiscoveryTimeMeasurement)")
        
        execute
        { result, err in
            self.end(result: result, error: err)
        }
    }
    
}
