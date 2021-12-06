//
//  UUPeripheralOperation.swift
//  
//
//  Created by Ryan DeVore on 10/28/21.
//

import Foundation
import CoreBluetooth

open class UUPeripheralOperation<T: UUPeripheral>
{
    public let peripheral: T
    private var operationError: Error? = nil
    private var operationCallback: ((Error?)->())? = nil
    private var discoveredServices: [CBService] = []
    private var discoveredCharacteristics: [CBCharacteristic] = []
    
    private var servicesNeedingCharacteristicDiscovery: [CBService] = []
    
    public var connectTimeout: TimeInterval = UUPeripheral.Defaults.connectTimeout
    public var disconnectTimeout: TimeInterval = UUPeripheral.Defaults.disconnectTimeout
    public var serviceDiscoveryTimeout: TimeInterval = UUPeripheral.Defaults.operationTimeout
    public var characteristicDiscoveryTimeout: TimeInterval = UUPeripheral.Defaults.operationTimeout
    public var readTimeout: TimeInterval = UUPeripheral.Defaults.operationTimeout
    public var writeTimeout: TimeInterval = UUPeripheral.Defaults.operationTimeout
    
    
    public init(_ peripheral: T)
    {
        self.peripheral = peripheral
    }
    
    public func start(_ completion: @escaping(Error?)->())
    {
        self.operationError = nil
        self.operationCallback = completion
        
        peripheral.connect(timeout: connectTimeout, connected: handleConnected, disconnected: handleDisconnection)
    }
    
    public func end(with error: Error?)
    {
        NSLog("**** Ending Operation with error: \(error?.localizedDescription ?? "nil")")
        self.operationError = error
        peripheral.disconnect(timeout: disconnectTimeout)
    }
    
    open func execute(_ completion: @escaping (Error?)->())
    {
        completion(nil)
    }
    
    public func write(data: Data, toCharacteristic: CBUUID, completion: @escaping ()->())
    {
        requireDiscoveredCharacteristic(for: toCharacteristic)
        { char in
            
            self.peripheral.writeValue(data, for: char, timeout: self.writeTimeout)
            { p, char, error in
                
                if let err = error
                {
                    NSLog("write failed, ending operation with error: \(err)")
                    self.end(with: err)
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
            
            self.peripheral.writeValueWithoutResponse(data, for: char)
            { p, char, error in
                
                if let err = error
                 {
                    NSLog("WWOR failed, ending operation with error: \(err)")
                    self.end(with: err)
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
                    NSLog("read failed, ending operation with error: \(err)")
                    self.end(with: err)
                    return
                }
                
                completion(char.value)
            })
        }
    }
    
    public func readUtf8(_ characteristic: CBUUID, _ completion: @escaping (String?)->())
    {
        read(from: characteristic)
        { data in
         
            var result: String? = nil
            
            if let data = data
            {
                result = String(data: data, encoding: .utf8)
            }
            
            completion(result)
        }
    }
    
    public func readUInt8(_ characteristic: CBUUID, _ completion: @escaping (UInt8?)->())
    {
        read(from: characteristic)
        { data in
         
            let result = data?.uuUInt8(at: 0)
            completion(result)
        }
    }
    
    public func readUInt16(_ characteristic: CBUUID, _ completion: @escaping (UInt16?)->())
    {
        read(from: characteristic)
        { data in
         
            let result = data?.uuUInt16(at: 0)
            completion(result)
        }
    }
    
    public func readUInt32(_ characteristic: CBUUID, _ completion: @escaping (UInt32?)->())
    {
        read(from: characteristic)
        { data in
         
            let result = data?.uuUInt32(at: 0)
            completion(result)
        }
    }
    
    public func readUInt64(_ characteristic: CBUUID, _ completion: @escaping (UInt64?)->())
    {
        read(from: characteristic)
        { data in
         
            let result = data?.uuUInt64(at: 0)
            completion(result)
        }
    }
    
    public func readInt8(_ characteristic: CBUUID, _ completion: @escaping (Int8?)->())
    {
        read(from: characteristic)
        { data in
         
            let result = data?.uuInt8(at: 0)
            completion(result)
        }
    }
    
    public func readInt16(_ characteristic: CBUUID, _ completion: @escaping (Int16?)->())
    {
        read(from: characteristic)
        { data in
         
            let result = data?.uuInt16(at: 0)
            completion(result)
        }
    }
    
    public func readInt32(_ characteristic: CBUUID, _ completion: @escaping (Int32?)->())
    {
        read(from: characteristic)
        { data in
         
            let result = data?.uuInt32(at: 0)
            completion(result)
        }
    }
    
    public func readInt32(_ characteristic: CBUUID, _ completion: @escaping (Int64?)->())
    {
        read(from: characteristic)
        { data in
         
            let result = data?.uuInt64(at: 0)
            completion(result)
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
            NSLog("Required Service not found, ending operation with error: \(err)")
            self.end(with: err)
            return
        }
        
        completion(discovered)
    }
    
    public func requireDiscoveredCharacteristic(for uuid: CBUUID, _ completion: @escaping (CBCharacteristic)->())
    {
        guard let discovered = findDiscoveredCharacteristic(for: uuid) else
        {
            let err = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Required characteristic \(uuid.uuidString) not found"])
            NSLog("Required Characteristic not found, ending operation with error: \(err)")
            self.end(with: err)
            return
        }
        
        completion(discovered)
    }
    
    
    
    private func handleConnected()
    {
        peripheral.discoverServices(servicesToDiscover, timeout: serviceDiscoveryTimeout)
        { services, error in
            
            if let err = error
            {
                NSLog("Service Discovery Failed, ending operation with error: \(err)")
                self.end(with: err)
                return
            }
            
            self.discoveredServices.removeAll()
            self.discoveredCharacteristics.removeAll()
            self.servicesNeedingCharacteristicDiscovery.removeAll()
            
            guard let services = services else
            {
                let err = NSError(domain: "Err", code: -1, userInfo: [NSLocalizedDescriptionKey: "No services were discovered"])
                NSLog("Service Discovery Failed to discover any services, ending operation with error: \(err)")
                self.end(with: err)
                return
            }
            
            self.discoveredServices.append(contentsOf: services)
            self.servicesNeedingCharacteristicDiscovery.append(contentsOf: services)
            self.discoverNextCharacteristics()
        }
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
        peripheral.discoverCharacteristics(characteristicsToDiscover(for: service.uuid), for: service, timeout: characteristicDiscoveryTimeout)
        { characteristics, error in
            
            if let err = error
            {
                NSLog("Characteristic Discovery Failed, ending operation with error: \(err)")
                self.end(with: err)
                return
            }
            
            if let characteristics = characteristics
            {
                self.discoveredCharacteristics.append(contentsOf: characteristics)
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
        self.operationCallback = nil
        self.operationError = nil
        callback?(err)
    }
    
    private func handleCharacteristicDiscoveryFinished()
    {
        execute
        { error in
            self.end(with: error)
        }
    }
}
