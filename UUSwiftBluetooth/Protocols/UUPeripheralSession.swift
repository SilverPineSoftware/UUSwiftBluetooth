//
//  UUPeripheralSession.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 1/10/25.
//

import CoreBluetooth

public struct UUPeripheralSessionConfiguration
{   
    public var servicesToDiscover: [CBUUID]? = nil
    public var characteristicsToDiscover: [CBUUID:[CBUUID]?]? = nil
    
    public var connectTimeout: TimeInterval = UUCoreBluetooth.Defaults.connectTimeout
    public var disconnectTimeout: TimeInterval = UUCoreBluetooth.Defaults.disconnectTimeout
    public var serviceDiscoveryTimeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout
    public var characteristicDiscoveryTimeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout
    public var descriptorDiscoveryTimeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout
    public var readTimeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout
    public var writeTimeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout
    
    public init(
        servicesToDiscover: [CBUUID]? = nil,
        characteristicsToDiscover: [CBUUID : [CBUUID]?]? = nil,
        connectTimeout: TimeInterval = UUCoreBluetooth.Defaults.connectTimeout,
        disconnectTimeout: TimeInterval = UUCoreBluetooth.Defaults.disconnectTimeout,
        serviceDiscoveryTimeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout,
        characteristicDiscoveryTimeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout,
        descriptorDiscoveryTimeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout,
        readTimeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout,
        writeTimeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout)
    {
        self.servicesToDiscover = servicesToDiscover
        self.characteristicsToDiscover = characteristicsToDiscover
        self.connectTimeout = connectTimeout
        self.disconnectTimeout = disconnectTimeout
        self.serviceDiscoveryTimeout = serviceDiscoveryTimeout
        self.characteristicDiscoveryTimeout = characteristicDiscoveryTimeout
        self.descriptorDiscoveryTimeout = descriptorDiscoveryTimeout
        self.readTimeout = readTimeout
        self.writeTimeout = writeTimeout
    }
}

public protocol UUPeripheralSession
{
    init (peripheral: UUPeripheral)
    
    // Properties
    var peripheral: UUPeripheral { get }
    var configuration: UUPeripheralSessionConfiguration { get set }
    var discoveredServices: [CBService] { get }
    var discoveredCharacteristics: [CBUUID:[CBCharacteristic]] { get }
    var discoveredDescriptors: [CBUUID:[CBDescriptor]] { get }
    var sessionEndError: Error? { get }
    
    // Callbacks
    var sessionStarted: ((UUPeripheralSession) -> Void)? { get set }
    var sessionEnded: ((UUPeripheralSession, Error?) -> Void)? { get set }
    
    // Methods
    func start()
    func end(error: Error?)
    
    func read(
        from characteristic: CBUUID,
        completion: @escaping (Data?)->(),
        errorHandler: ((Error)->Bool)?)
    
    func write(
        data: Data,
        toCharacteristic: CBUUID,
        withResponse: Bool,
        completion: @escaping ()->(),
        errorHandler: ((Error)->Bool)?)
    
    func startListeningForDataChanges(
        from characteristic: CBUUID,
        dataChanged: @escaping (Data?)->(),
        completion: @escaping ()->(),
        errorHandler: ((Error)->Bool)?)
    
    func stopListeningForDataChanges(
        from characteristic: CBUUID,
        completion: @escaping ()->(),
        errorHandler: ((Error)->Bool)?)
}



public extension UUPeripheralSession // Read Methods
{
    func read(
        from characteristic: CBUUID,
        completion: @escaping (Data?)->())
    {
        read(from: characteristic, completion: completion, errorHandler: nil)
    }
    
    func readString(from characteristic: CBUUID, encoding: String.Encoding, completion: @escaping (String?)->())
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
    
    func readUtf8(from characteristic: CBUUID, completion: @escaping (String?)->())
    {
        readString(from: characteristic, encoding: .utf8, completion: completion)
    }
    
    func readUInt8(from characteristic: CBUUID,  completion: @escaping (UInt8?)->())
    {
        read(from: characteristic)
        { data in
         
            let result = data?.uuUInt8(at: 0)
            completion(result)
        }
    }
    
    func readUInt16(from characteristic: CBUUID, completion: @escaping (UInt16?)->())
    {
        read(from: characteristic)
        { data in
         
            let result = data?.uuUInt16(at: 0)
            completion(result)
        }
    }
    
    func readUInt32(from characteristic: CBUUID, completion: @escaping (UInt32?)->())
    {
        read(from: characteristic)
        { data in
         
            let result = data?.uuUInt32(at: 0)
            completion(result)
        }
    }
    
    func readUInt64(from characteristic: CBUUID, completion: @escaping (UInt64?)->())
    {
        read(from: characteristic)
        { data in
         
            let result = data?.uuUInt64(at: 0)
            completion(result)
        }
    }
    
    func readInt8(from characteristic: CBUUID, completion: @escaping (Int8?)->())
    {
        read(from: characteristic)
        { data in
         
            let result = data?.uuInt8(at: 0)
            completion(result)
        }
    }
    
    func readInt16(from characteristic: CBUUID, completion: @escaping (Int16?)->())
    {
        read(from: characteristic)
        { data in
         
            let result = data?.uuInt16(at: 0)
            completion(result)
        }
    }
    
    func readInt32(from characteristic: CBUUID, completion: @escaping (Int32?)->())
    {
        read(from: characteristic)
        { data in
         
            let result = data?.uuInt32(at: 0)
            completion(result)
        }
    }
    
    func readInt32(from characteristic: CBUUID, completion: @escaping (Int64?)->())
    {
        read(from: characteristic)
        { data in
         
            let result = data?.uuInt64(at: 0)
            completion(result)
        }
    }
}

public extension UUPeripheralSession // Write Methods
{
    func write(
        data: Data,
        toCharacteristic: CBUUID,
        withResponse: Bool,
        completion: @escaping ()->())
    {
        write(data: data, toCharacteristic: toCharacteristic, withResponse: withResponse, completion: completion, errorHandler: nil)
    }
    
    func write(
        string: String,
        with encoding: String.Encoding,
        to characteristic: CBUUID,
        withResponse: Bool,
        completion: @escaping ()->())
    {
        var data = Data()
        data.uuAppend(string, encoding: encoding)
        
        write(data: data, toCharacteristic: characteristic, withResponse: withResponse, completion: completion)
    }
    
    func writeUtf8(
        string: String,
        to characteristic: CBUUID,
        withResponse: Bool,
        completion: @escaping ()->())
    {
        write(string: string, with: .utf8, to: characteristic, withResponse: withResponse, completion: completion)
    }
    
    func write<T: FixedWidthInteger>(
        integer: T,
        to characteristic: CBUUID,
        withResponse: Bool,
        completion: @escaping ()->())
    {
        var data = Data()
        data.uuAppend(integer)
        write(data: data, toCharacteristic: characteristic, withResponse: withResponse, completion: completion)
    }
}

public extension UUPeripheralSession // Characteristic Data Notify
{
    func startListeningForDataChanges(
        from characteristic: CBUUID,
        dataChanged: @escaping (Data?)->(),
        completion: @escaping ()->())
    {
        startListeningForDataChanges(from: characteristic, dataChanged: dataChanged, completion: completion, errorHandler: nil)
    }
    
    func stopListeningForDataChanges(
        from characteristic: CBUUID,
        completion: @escaping ()->())
    {
        stopListeningForDataChanges(from: characteristic, completion: completion, errorHandler: nil)
        
    }
}
