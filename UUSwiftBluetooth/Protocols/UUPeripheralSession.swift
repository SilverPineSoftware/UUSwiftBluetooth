//
//  UUPeripheralSession.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 1/10/25.
//

import CoreBluetooth

public typealias UUPeripheralSessionStartedCallback = ((any UUPeripheralSession) -> Void)
public typealias UUPeripheralSessionEndedCallback = ((any UUPeripheralSession, Error?) -> Void)
public typealias UUPeripheralSessionObjectErrorCallback<T> = ((any UUPeripheralSession, T?, Error?) -> Void)
public typealias UUPeripheralSessionErrorCallback = ((any UUPeripheralSession, Error?) -> Void)

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
    var started: UUPeripheralSessionStartedCallback { get set }
    var ended: UUPeripheralSessionEndedCallback { get set }
    
    // Methods
    func start()
    func end(error: Error?)
    
    func startTimer(name: String, timeout: TimeInterval, block: @escaping ()->())
    func cancelTimer(name: String)
    
    func read(
        from characteristic: CBUUID,
        completion: @escaping UUPeripheralSessionObjectErrorCallback<Data>)
    
    func write(
        data: Data,
        to characteristic: CBUUID,
        withResponse: Bool,
        completion: @escaping UUPeripheralSessionErrorCallback)
    
    func startListeningForDataChanges(
        from characteristic: CBUUID,
        dataChanged: @escaping UUPeripheralSessionObjectErrorCallback<Data>,
        completion: @escaping UUPeripheralSessionErrorCallback)
    
    func stopListeningForDataChanges(
        from characteristic: CBUUID,
        completion: @escaping UUPeripheralSessionErrorCallback)
}



public extension UUPeripheralSession // Read Methods
{
//    func read(
//        from characteristic: CBUUID,
//        completion: @escaping (Data?)->())
//    {
//        read(from: characteristic, completion: completion, errorHandler: nil)
//    }
    
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
