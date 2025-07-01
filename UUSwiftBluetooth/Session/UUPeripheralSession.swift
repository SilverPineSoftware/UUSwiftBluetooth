//
//  UUPeripheralSession.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 1/10/25.
//

import CoreBluetooth
import UUSwiftCore

public typealias UUPeripheralSessionStartedCallback = ((UUPeripheralSession) -> Void)
public typealias UUPeripheralSessionEndedCallback = ((UUPeripheralSession, Error?) -> Void)
public typealias UUPeripheralSessionObjectErrorCallback<T> = ((UUPeripheralSession, T?, Error?) -> Void)
public typealias UUPeripheralSessionErrorCallback = ((UUPeripheralSession, Error?) -> Void)

fileprivate let LOG_TAG = "UUPeripheralSession"

open class UUPeripheralSession
{
    // Properties
    public var peripheral: (any UUPeripheral)
    public var configuration = UUPeripheralSessionConfiguration()
    public private(set) var discoveredServices: [CBService] = []
    public private(set) var discoveredCharacteristics: [CBUUID:[CBCharacteristic]] = [:]
    public private(set) var discoveredDescriptors: [CBUUID:[CBDescriptor]] = [:]
    public private(set) var sessionEndError: Error? = nil
    
    private var servicesNeedingCharacteristicDiscovery: [CBService] = []
    private var characteristicsNeedingDescriptorDiscovery: [CBCharacteristic] = []
    
    public required init (peripheral: any UUPeripheral)
    {
        self.peripheral = peripheral
    }
    
    // Callbacks
    public var started: UUPeripheralSessionStartedCallback =
    { session in
        UULog.fatal(tag: LOG_TAG, message: "Session started callback not implemented, session: \(session)")
    }
    
    public var ended: UUPeripheralSessionEndedCallback =
    { session, error in
        UULog.fatal(tag: LOG_TAG, message: "Session ended callback not implemented, session: \(session), error: \(String(describing: error))")
    }
    
    // Methods
    open func start()
    {
        connect()
    }
    
    open func end(error: Error?)
    {
        sessionEndError = error
        disconnect()
    }
    
    open func finishSessionStart(_ completion: @escaping ()->())
    {
        completion()
    }
    
    public func startTimer(name: String, timeout: TimeInterval, block: @escaping ()->())
    {
        peripheral.startTimer(name: name, timeout: timeout, block: block)
    }
    
    public func cancelTimer(name: String)
    {
        peripheral.cancelTimer(name: name)
    }
    
    public func read(
        from characteristic: CBUUID,
        completion: @escaping UUPeripheralSessionObjectErrorCallback<Data>)
    {
        guard let char = findDiscoveredCharacteristic(for: characteristic) else
        {
            let err = NSError.uuRequiredCharacteristicNotFoundError(characteristic)
            completion(self, nil, err)
            return
        }
        
        peripheral.readValue(for: char, timeout: self.configuration.readTimeout)
        { p, char, error in
            
            completion(self, char.value, error)
        }
    }
    
    public func write(
        data: Data,
        to characteristic: CBUUID,
        withResponse: Bool,
        completion: @escaping UUPeripheralSessionErrorCallback)
    {
        guard let char = findDiscoveredCharacteristic(for: characteristic) else
        {
            let err = NSError.uuRequiredCharacteristicNotFoundError(characteristic)
            completion(self, err)
            return
        }
        
        if (withResponse)
        {
            peripheral.writeValue(data: data, for: char, timeout: configuration.writeTimeout)
            { p, char, error in
                
                completion(self, error)
            }
        }
        else
        {
            peripheral.writeValueWithoutResponse(data: data, for: char)
            { p, char, error in
                
                completion(self, error)
            }
        }
    }
    
    public func startListeningForDataChanges(
        from characteristic: CBUUID,
        dataChanged: @escaping UUPeripheralSessionObjectErrorCallback<Data>,
        completion: @escaping UUPeripheralSessionErrorCallback)
    {
        guard let char = findDiscoveredCharacteristic(for: characteristic) else
        {
            let err = NSError.uuRequiredCharacteristicNotFoundError(characteristic)
            completion(self, err)
            return
        }
        
        peripheral.setNotifyValue(
            enabled: true,
            for: char,
            timeout: configuration.readTimeout)
        { p, char, error in
            
            dataChanged(self, char.value, error)
            
        } completion:
        { p, char, err in
            
            completion(self, err)
        }
    }
    
    public func stopListeningForDataChanges(
        from characteristic: CBUUID,
        completion: @escaping UUPeripheralSessionErrorCallback)
    {
        guard let char = findDiscoveredCharacteristic(for: characteristic) else
        {
            let err = NSError.uuRequiredCharacteristicNotFoundError(characteristic)
            completion(self, err)
            return
        }
        
        peripheral.setNotifyValue(enabled: false, for: char, timeout: configuration.readTimeout, notifyHandler: nil)
        { p, char, err in
            
            completion(self, err)
        }
    }
}


// MARK: - Connection & Disconnection
fileprivate extension UUPeripheralSession
{
    func connect()
    {
        peripheral.connect(timeout: configuration.connectTimeout, connected: handleConnected, disconnected: handleDisconnection)
    }
    
    func handleSessionStarted()
    {
        UULog.debug(tag: LOG_TAG, message: "handleSessionStarted")
        
        finishSessionStart
        {
            UULog.debug(tag: LOG_TAG, message: "handleSessionStarted, notifying session started delegate")
            self.started(self)
        }
    }
    
    func disconnect()
    {
        peripheral.disconnect(timeout: configuration.disconnectTimeout)
    }
    
    func handleConnected()
    {
        startServiceDiscovery()
    }
    
    func handleDisconnection(_ disconnectError: Error?)
    {
        // Only set error if not already set.  In the case where end(error) forcefully ends the session, preserve that error.
        if (self.sessionEndError != nil)
        {
            self.sessionEndError = disconnectError
        }
        
        ended(self, self.sessionEndError)
    }
}


// MARK: - Service Discovery
fileprivate extension UUPeripheralSession
{
    func startServiceDiscovery()
    {
        discoveredServices.removeAll()
        
        peripheral.discoverServices(
            serviceUUIDs: configuration.servicesToDiscover,
            timeout: configuration.serviceDiscoveryTimeout)
        { services, error in
            
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
fileprivate extension UUPeripheralSession
{
    func startCharacteristicDiscovery()
    {
        discoveredCharacteristics.removeAll()
        servicesNeedingCharacteristicDiscovery.append(contentsOf: discoveredServices)
        discoverNextCharacteristics()
    }
    
    private func discoverNextCharacteristics()
    {
        UULog.debug(tag: LOG_TAG, message: "discoverNextCharacteristics, servicesNeedingCharacteristicDiscovery.count: \(servicesNeedingCharacteristicDiscovery.count)")
        
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
        UULog.debug(tag: LOG_TAG, message: "handleCharacteristicDiscoveryFinished")
        
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
        
        if let chars = charsToDiscover
        {
            UULog.debug(tag: LOG_TAG, message: "Discovering \(chars.count) characteristics to discover on service \(service.uuid), chars: \(chars.compactMap(\.uuidString))")
        }
        else
        {
            UULog.debug(tag: LOG_TAG, message: "Discovering all characteristics on service \(service.uuid)")
        }
        
        peripheral.discoverCharacteristics(
            characteristicUUIDs: charsToDiscover,
            for: service,
            timeout: configuration.characteristicDiscoveryTimeout)
        { characteristics, error in
            
            UULog.debug(tag: LOG_TAG, message: "peripheral.discoverCharacteristics returned for service \(service.uuid)")
            
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
fileprivate extension UUPeripheralSession
{
    func startDescriptorDiscovery()
    {
        UULog.debug(tag: LOG_TAG, message: "startDescriptorDiscovery")
        
        discoveredDescriptors.removeAll()
        characteristicsNeedingDescriptorDiscovery.append(contentsOf: discoveredCharacteristics.values.flatMap { $0 })
        discoverNextDescriptors()
    }
    
    private func discoverNextDescriptors()
    {
        UULog.debug(tag: LOG_TAG, message: "discoverNextDescriptors, characteristicsNeedingDescriptorDiscovery.count: \(characteristicsNeedingDescriptorDiscovery.count)")
        
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
        logDiscoveredDescriptors()
        handleSessionStarted()
    }
    
    private func discoverDescriptors(for characteristic: CBCharacteristic, _ completion: @escaping ()->())
    {
        discoveredDescriptors[characteristic.uuid] = []
        
        UULog.debug(tag: LOG_TAG, message: "Discovering all descriptors for characteristic \(characteristic.uuid)")
        
        peripheral.discoverDescriptorsForCharacteristic(
            for: characteristic,
            timeout: configuration.descriptorDiscoveryTimeout)
        { descriptors, error in
            
            UULog.debug(tag: LOG_TAG, message: "peripheral.discoverDescriptorsForCharacteristic returned for characteristic \(characteristic.uuid)")
            
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
            UULog.debug(tag: LOG_TAG, message: "Discovered \(descriptors.count) descriptors on characteristic \(characteristic)")
            
            descriptors.forEach { descriptor in
                let descriptorDescription = UUDescriptorRepresentation(from: descriptor)
                UULog.debug(tag: LOG_TAG, message: "Descriptor: \(descriptorDescription.uuToJsonString())")
            }
        }
    }
}

fileprivate extension UUPeripheralSession
{
    private func findDiscoveredCharacteristic(for uuid: CBUUID) -> CBCharacteristic?
    {
        return discoveredCharacteristics.values.flatMap { $0 }.first { $0.uuid == uuid }
    }
}

public extension UUPeripheralSession // Read Methods
{
    func readString(
        from characteristic: CBUUID,
        encoding: String.Encoding,
        completion: @escaping UUPeripheralSessionObjectErrorCallback<String>)
    {
        read(from: characteristic)
        { session, data, error in
         
            var result: String? = nil
            
            if let data = data
            {
                result = String(data: data, encoding: encoding)
            }
            
            completion(session, result, error)
        }
    }
    
    func readUtf8(
        from characteristic: CBUUID,
        completion: @escaping UUPeripheralSessionObjectErrorCallback<String>)
    {
        readString(from: characteristic, encoding: .utf8, completion: completion)
    }
    
    func readUInt8(
        from characteristic: CBUUID,
        completion: @escaping UUPeripheralSessionObjectErrorCallback<UInt8>)
    {
        read(from: characteristic)
        { session, data, error in
         
            let result = data?.uuUInt8(at: 0)
            completion(session, result, error)
        }
    }
    
    func readUInt16(
        from characteristic: CBUUID,
        completion: @escaping UUPeripheralSessionObjectErrorCallback<UInt16>)
    {
        read(from: characteristic)
        { session, data, error in
         
            let result = data?.uuUInt16(at: 0)
            completion(session, result, error)
        }
    }
    
    func readUInt32(
        from characteristic: CBUUID,
        completion: @escaping UUPeripheralSessionObjectErrorCallback<UInt32>)
    {
        read(from: characteristic)
        { session, data, error in
         
            let result = data?.uuUInt32(at: 0)
            completion(session, result, error)
        }
    }
    
    func readUInt64(from characteristic: CBUUID, completion: @escaping UUPeripheralSessionObjectErrorCallback<UInt64>)
    {
        read(from: characteristic)
        { session, data, error in
         
            let result = data?.uuUInt64(at: 0)
            completion(session, result, error)
        }
    }
    
    func readInt8(from characteristic: CBUUID, completion: @escaping UUPeripheralSessionObjectErrorCallback<Int8>)
    {
        read(from: characteristic)
        { session, data, error in
         
            let result = data?.uuInt8(at: 0)
            completion(session, result, error)
        }
    }
    
    func readInt16(from characteristic: CBUUID, completion: @escaping UUPeripheralSessionObjectErrorCallback<Int16>)
    {
        read(from: characteristic)
        { session, data, error in
         
            let result = data?.uuInt16(at: 0)
            completion(session, result, error)
        }
    }
    
    func readInt32(from characteristic: CBUUID, completion: @escaping UUPeripheralSessionObjectErrorCallback<Int32>)
    {
        read(from: characteristic)
        { session, data, error in
         
            let result = data?.uuInt32(at: 0)
            completion(session, result, error)
        }
    }
    
    func readInt32(from characteristic: CBUUID, completion: @escaping UUPeripheralSessionObjectErrorCallback<Int64>)
    {
        read(from: characteristic)
        { session, data, error in
         
            let result = data?.uuInt64(at: 0)
            completion(session, result, error)
        }
    }
}

public extension UUPeripheralSession // Write Methods
{
    func write(
        string: String,
        with encoding: String.Encoding,
        to characteristic: CBUUID,
        withResponse: Bool,
        completion: @escaping UUPeripheralSessionErrorCallback)
    {
        var data = Data()
        data.uuAppend(string, encoding: encoding)
        
        write(data: data, to: characteristic, withResponse: withResponse, completion: completion)
    }
    
    func writeUtf8(
        string: String,
        to characteristic: CBUUID,
        withResponse: Bool,
        completion: @escaping UUPeripheralSessionErrorCallback)
    {
        write(string: string, with: .utf8, to: characteristic, withResponse: withResponse, completion: completion)
    }
    
    func write<T: FixedWidthInteger>(
        integer: T,
        to characteristic: CBUUID,
        withResponse: Bool,
        completion: @escaping UUPeripheralSessionErrorCallback)
    {
        var data = Data()
        data.uuAppend(integer)
        write(data: data, to: characteristic, withResponse: withResponse, completion: completion)
    }
}
