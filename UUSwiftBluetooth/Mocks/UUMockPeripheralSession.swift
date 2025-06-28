//
//  UUMockPeripheralSession.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 6/27/25.
//
//
//import Foundation
//import CoreBluetooth
//
//
//open class UUMockPeripheralSession: UUPeripheralSession
//{
//    public var peripheral: any UUPeripheral
//    
//    public var configuration: UUPeripheralSessionConfiguration = UUPeripheralSessionConfiguration()
//    
//    public var discoveredServices: [CBService]
//    
//    public var discoveredCharacteristics: [CBUUID : [CBCharacteristic]]
//    
//    public var discoveredDescriptors: [CBUUID : [CBDescriptor]]
//    
//    public var sessionEndError: (any Error)?
//    
//    public var started: UUPeripheralSessionStartedCallback
//    
//    public var ended: UUPeripheralSessionEndedCallback
//    
//    public func start()
//    {
//        
//    }
//    
//    public func end(error: (any Error)?)
//    {
//        
//    }
//    
//    required public init(peripheral: any UUPeripheral)
//    {
//        //super.init(peripheral: peripheral)
//        self.peripheral = peripheral
//    }
//}
