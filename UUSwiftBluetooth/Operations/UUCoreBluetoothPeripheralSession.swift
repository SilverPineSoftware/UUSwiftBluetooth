//
//  UUPeripheralOperation.swift
//  
//
//  Created by Ryan DeVore on 10/28/21.
//

import Foundation
import CoreBluetooth
import UUSwiftCore

fileprivate let LOG_TAG = "UUPeripheralOperation"

open class UUCoreBluetoothPeripheralSession: UUPeripheralSession
{
    // MARK: - UUPeripheralSession
    
    public let peripheral: UUPeripheral
    public var configuration: UUPeripheralSessionConfiguration = UUPeripheralSessionConfiguration()
    public private(set) var discoveredServices: [CBService] = []
    public private(set) var discoveredCharacteristics: [CBUUID:[CBCharacteristic]] = [:]
    public private(set) var discoveredDescriptors: [CBUUID:[CBDescriptor]] = [:]
    public private(set) var sessionEndError: Error? = nil
    
    public var sessionStarted: ((any UUPeripheralSession) -> Void)?
    public var sessionEnded: ((any UUPeripheralSession, (any Error)?) -> Void)?
    
    required public init(peripheral: UUPeripheral)
    {
        self.peripheral = peripheral
    }
    
    public func start()
    {
        connect()
    }
    
    public func end(error: Error? = nil)
    {
        UULog.debug(tag: LOG_TAG, message: "Session ending with error: \(String(describing: error))")
        
        sessionEndError = error
        disconnect()
    }
    
    private func defaultErrorHandler(_ error: Error) -> Bool
    {
        UULog.debug(tag: LOG_TAG, message: "Error: \(error)")
        return true
    }
    
    public func read(
        from characteristic: CBUUID,
        completion: @escaping (Data?)->(),
        errorHandler: ((Error)->Bool)?)
    {
        let actualErrorHandler = errorHandler ?? defaultErrorHandler
        
        func internalHandleCompletion(_ data: Data?, _ error: Error?)
        {
            var invokeCompletion = true
            
            if let err = error
            {
                let endSession = actualErrorHandler(err)
                if (endSession)
                {
                    invokeCompletion = false
                    self.end(error: error)
                }
            }
            
            if (invokeCompletion)
            {
                completion(data)
            }
        }
        
        guard let char = findDiscoveredCharacteristic(for: characteristic) else
        {
            let err = NSError.uuRequiredCharacteristicNotFoundError(characteristic)
            internalHandleCompletion(nil, err)
            return
        }
        
        peripheral.readValue(for: char, timeout: self.configuration.readTimeout)
        { p, char, error in
            
            internalHandleCompletion(char.value, error)
        }
    }
    
    public func write(
        data: Data,
        toCharacteristic: CBUUID,
        withResponse: Bool,
        completion: @escaping ()->(),
        errorHandler: ((Error)->Bool)?)
    {
        let actualErrorHandler = errorHandler ?? defaultErrorHandler
        
        func internalHandleCompletion(_ error: Error?)
        {
            var invokeCompletion = true
            
            if let err = error
            {
                let endSession = actualErrorHandler(err)
                if (endSession)
                {
                    invokeCompletion = false
                    self.end(error: error)
                }
            }
            
            if (invokeCompletion)
            {
                completion()
            }
        }
        
        guard let char = findDiscoveredCharacteristic(for: toCharacteristic) else
        {
            let err = NSError.uuRequiredCharacteristicNotFoundError(toCharacteristic)
            internalHandleCompletion(err)
            return
        }
        
        if (withResponse)
        {
            peripheral.writeValue(data: data, for: char, timeout: configuration.writeTimeout)
            { p, char, error in
                
                internalHandleCompletion(error)
            }
        }
        else
        {
            peripheral.writeValueWithoutResponse(data: data, for: char)
            { p, char, error in
                
                internalHandleCompletion(error)
            }
        }
    }
    
    public func startListeningForDataChanges(
        from characteristic: CBUUID,
        dataChanged: @escaping (Data?)->(),
        completion: @escaping ()->(),
        errorHandler: ((Error)->Bool)?)
    {
        let actualErrorHandler = errorHandler ?? defaultErrorHandler
        
        func internalHandleCompletion(_ error: Error?)
        {
            var invokeCompletion = true
            
            if let err = error
            {
                let endSession = actualErrorHandler(err)
                if (endSession)
                {
                    invokeCompletion = false
                    self.end(error: error)
                }
            }
            
            if (invokeCompletion)
            {
                completion()
            }
        }
        
        guard let char = findDiscoveredCharacteristic(for: characteristic) else
        {
            let err = NSError.uuRequiredCharacteristicNotFoundError(characteristic)
            internalHandleCompletion(err)
            return
        }
        
        peripheral.setNotifyValue(
            enabled: true,
            for: char,
            timeout: configuration.readTimeout)
        { p, char, error in
            
            if let err = error
            {
                let endSession = actualErrorHandler(err)
                if (endSession)
                {
                    self.end(error: error)
                    return
                }
            }
            
            dataChanged(char.value)
            
        } completion:
        { p, char, err in
            
            internalHandleCompletion(err)
        }
    }
    
    public func stopListeningForDataChanges(
        from characteristic: CBUUID,
        completion: @escaping ()->(),
        errorHandler: ((Error)->Bool)?)
    {
        let actualErrorHandler = errorHandler ?? defaultErrorHandler
        
        func internalHandleCompletion(_ error: Error?)
        {
            var invokeCompletion = true
            
            if let err = error
            {
                let endSession = actualErrorHandler(err)
                if (endSession)
                {
                    invokeCompletion = false
                    self.end(error: error)
                }
            }
            
            if (invokeCompletion)
            {
                completion()
            }
        }
        
        guard let char = findDiscoveredCharacteristic(for: characteristic) else
        {
            let err = NSError.uuRequiredCharacteristicNotFoundError(characteristic)
            internalHandleCompletion(err)
            return
        }
        
        peripheral.setNotifyValue(enabled: false, for: char, timeout: configuration.readTimeout, notifyHandler: nil)
        { p, char, err in
            
            internalHandleCompletion(err)
        }
    }
    
    // MARK: - Private Variables
    
    private var servicesNeedingCharacteristicDiscovery: [CBService] = []
    private var characteristicsNeedingDescriptorDiscovery: [CBCharacteristic] = []
    
    private let connectTimeMeasurement = UUTimeMeasurement(name: "connectTime")
    private let disconnectTimeMeasurement = UUTimeMeasurement(name: "disconnectTime")
    private let serviceDiscoveryTimeMeasurement = UUTimeMeasurement(name: "serviceDiscoveryTime")
    private let characteristicDiscoveryTimeMeasurement = UUTimeMeasurement(name: "characteristicDiscoveryTime")
    private let descriptorDiscoveryTimeMeasurement = UUTimeMeasurement(name: "descriptorDiscoveryTime")
    
    // MARK: - Private Implementation
    
    private func findDiscoveredCharacteristic(for uuid: CBUUID) -> CBCharacteristic?
    {
        return discoveredCharacteristics.values.flatMap { $0 }.first { $0.uuid == uuid }
    }
}

// MARK: - Connection & Disconnection
fileprivate extension UUCoreBluetoothPeripheralSession
{
    func connect()
    {
        connectTimeMeasurement.start()
        peripheral.connect(timeout: configuration.connectTimeout, connected: handleConnected, disconnected: handleDisconnection)
    }
    
    func handleSessionStarted()
    {
        sessionStarted?(self)
    }
    
    func disconnect()
    {
        disconnectTimeMeasurement.start()
        peripheral.disconnect(timeout: configuration.disconnectTimeout)
    }
    
    func handleConnected()
    {
        connectTimeMeasurement.end()
        startServiceDiscovery()
    }
    
    func handleDisconnection(_ disconnectError: Error?)
    {
        disconnectTimeMeasurement.end()
        
        // Only set error if not already set.  In the case where end(error) forcefully ends the session, preserve that error.
        if (self.sessionEndError != nil)
        {
            self.sessionEndError = disconnectError
        }
        
        sessionEnded?(self, self.sessionEndError)
    }
}


// MARK: - Service Discovery
fileprivate extension UUCoreBluetoothPeripheralSession
{
    func startServiceDiscovery()
    {
        serviceDiscoveryTimeMeasurement.start()
        
        discoveredServices.removeAll()
        
        peripheral.discoverServices(
            serviceUUIDs: configuration.servicesToDiscover,
            timeout: configuration.serviceDiscoveryTimeout)
        { services, error in
            
            self.serviceDiscoveryTimeMeasurement.end()
            
            if let err = error
            {
                self.end(error: err)
                return
            }
            
            guard let services = services else
            {
                let err = NSError.uuCoreBluetoothError(.noServicesDiscovered)
                self.end(error: err)
                return
            }
            
            self.discoveredServices.append(contentsOf: services)
            self.logDiscoveredServices()
            self.startCharacteristicDiscovery()
        }
    }
    
    private func logDiscoveredServices()
    {
        UULog.debug(tag: LOG_TAG, message: "Discovered \(discoveredServices.count) services.")
        discoveredServices.forEach { service in
            let serviceDescription = UUServiceRepresentation(from: service)
            UULog.debug(tag: LOG_TAG, message: "Service: \(serviceDescription.uuToJsonString())")
        }
    }
}

// MARK: - Characteristic Discovery
fileprivate extension UUCoreBluetoothPeripheralSession
{
    func startCharacteristicDiscovery()
    {
        characteristicDiscoveryTimeMeasurement.start()
        discoveredCharacteristics.removeAll()
        servicesNeedingCharacteristicDiscovery.append(contentsOf: discoveredServices)
        discoverNextCharacteristics()
    }
    
    private func discoverNextCharacteristics()
    {
        if (servicesNeedingCharacteristicDiscovery.isEmpty)
        {
            handleCharacteristicDiscoveryFinished()
            return
        }
        
        let service = servicesNeedingCharacteristicDiscovery.remove(at: 0)

        discoverCharacteristics(for: service)
        {
            self.discoverNextCharacteristics()
        }
    }
    
    private func handleCharacteristicDiscoveryFinished()
    {
        characteristicDiscoveryTimeMeasurement.end()
        logDiscoveredCharacteristics()
        startDescriptorDiscovery()
    }
    
    private func characteristicsToDiscover(for serviceUUID: CBUUID) -> [CBUUID]?
    {
        if let chars = configuration.characteristicsToDiscover
        {
            if let toDiscover = chars[serviceUUID]
            {
                return toDiscover
            }
        }
        
        return nil
    }
    
    private func discoverCharacteristics(for service: CBService, _ completion: @escaping ()->())
    {
        discoveredCharacteristics[service.uuid] = []
        
        let charsToDiscover = characteristicsToDiscover(for: service.uuid)
        
        UULog.debug(tag: LOG_TAG, message: "There are \(String(describing: charsToDiscover?.count ?? 0)) characteristics to discover on service \(service.uuid)")
        
        peripheral.discoverCharacteristics(
            characteristicUUIDs: charsToDiscover,
            for: service,
            timeout: configuration.characteristicDiscoveryTimeout)
        { characteristics, error in
            
            if let err = error
            {
                self.end(error: err)
                return
            }
            
            if let characteristics = characteristics
            {
                self.discoveredCharacteristics[service.uuid] = characteristics
            }
            
            completion()
        }
    }
    
    private func logDiscoveredCharacteristics()
    {
        discoveredCharacteristics.forEach { service, characteristics in
            UULog.debug(tag: LOG_TAG, message: "Discovered \(characteristics.count) characteristics on service \(service)")
            
            characteristics.forEach { characteristic in
                let characteristicDescription = UUCharacteristicRepresentation(from: characteristic)
                UULog.debug(tag: LOG_TAG, message: "Characteristic: \(characteristicDescription.uuToJsonString())")
            }
        }
    }
}

// MARK: - Descriptor Discovery
fileprivate extension UUCoreBluetoothPeripheralSession
{
    func startDescriptorDiscovery()
    {
        descriptorDiscoveryTimeMeasurement.start()
        discoveredDescriptors.removeAll()
        characteristicsNeedingDescriptorDiscovery.append(contentsOf: discoveredCharacteristics.values.flatMap { $0 })
        discoverNextDescriptors()
    }
    
    private func discoverNextDescriptors()
    {
        if (characteristicsNeedingDescriptorDiscovery.isEmpty)
        {
            handleDescriptorDiscoveryFinished()
            return
        }
        
        let characteristic = characteristicsNeedingDescriptorDiscovery.remove(at: 0)
        
        discoverDescriptors(for: characteristic)
        {
            self.discoverNextDescriptors()
        }
    }
    
    private func handleDescriptorDiscoveryFinished()
    {
        descriptorDiscoveryTimeMeasurement.end()
        logDiscoveredDescriptors()
        handleSessionStarted()
    }
    
    private func discoverDescriptors(for characteristic: CBCharacteristic, _ completion: @escaping ()->())
    {
        discoveredDescriptors[characteristic.uuid] = []
        
        peripheral.discoverDescriptorsForCharacteristic(
            for: characteristic,
            timeout: configuration.descriptorDiscoveryTimeout)
        { descriptors, error in
            
            if let err = error
            {
                self.end(error: err)
                return
            }
            
            if let descriptors = descriptors
            {
                self.discoveredDescriptors[characteristic.uuid] = descriptors
            }
            
            completion()
        }
    }
    
    private func logDiscoveredDescriptors()
    {
        discoveredDescriptors.forEach { characteristic, descriptors in
            UULog.debug(tag: LOG_TAG, message: "Discovered \(descriptors.count) descriptors on characterstic \(characteristic)")
            
            descriptors.forEach { descriptor in
                let descriptorDescription = UUDescriptorRepresentation(from: descriptor)
                UULog.debug(tag: LOG_TAG, message: "Descriptor: \(descriptorDescription.uuToJsonString())")
            }
        }
    }
}
