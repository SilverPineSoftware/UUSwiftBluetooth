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
            
            self.peripheral.writeValue(data, for: char)
            { p, char, error in
                
                if let err = error
                {
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
                    self.end(with: err)
                    return
                }
                
                completion()
            }
        }
    }
    
    public func read(data: Data, fromCharacteristic: CBUUID, completion: @escaping (Data?)->())
    {
        requireDiscoveredCharacteristic(for: fromCharacteristic)
        { char in
            
            self.peripheral.readValue(for: char, completion:
            { p, char, error in
                
                if let err = error
                {
                    self.end(with: err)
                    return
                }
                
                completion(char.value)
            })
        }
    }
    
    open var connectTimeout: TimeInterval
    {
        return UUPeripheral.Defaults.connectTimeout
    }
    
    open var disconnectTimeout: TimeInterval
    {
        return UUPeripheral.Defaults.disconnectTimeout
    }
    
    open var serviceDiscoveryTimeout: TimeInterval
    {
        return UUPeripheral.Defaults.operationTimeout
    }
    
    open var characteristicDiscoveryTimeout: TimeInterval
    {
        return UUPeripheral.Defaults.operationTimeout
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
            let err = NSError(domain: "", code: -1, userInfo: nil)
            self.end(with: err)
            return
        }
        
        completion(discovered)
    }
    
    public func requireDiscoveredCharacteristic(for uuid: CBUUID, _ completion: @escaping (CBCharacteristic)->())
    {
        guard let discovered = findDiscoveredCharacteristic(for: uuid) else
        {
            let err = NSError(domain: "", code: -1, userInfo: nil)
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
                self.end(with: err)
                return
            }
            
            self.discoveredServices.removeAll()
            self.discoveredCharacteristics.removeAll()
            self.servicesNeedingCharacteristicDiscovery.removeAll()
            
            guard let services = services else
            {
                let err = NSError(domain: "Err", code: -1, userInfo: [NSLocalizedDescriptionKey: "No services were discovered"])
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
