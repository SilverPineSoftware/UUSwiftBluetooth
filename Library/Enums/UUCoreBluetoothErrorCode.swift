//
//  UUCoreBluetoothErrorCode.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 8/13/21.
//

import Foundation

public enum UUCoreBluetoothErrorCode: Int, CaseIterable
{
    // A operation attempt was manually timed out by UUCoreBluetooth
    case timeout = 1
    
    // A method call was not attempted because the CBPeripheral was not connected.
    case notConnected = 2
    
    // A CoreBluetooth operation failed for some reason. Check inner error for
    // more information.  This can be returned from any Core Bluetooth delegate
    // method that returns an NSError
    case operationFailed = 3
    
    // didFailToConnectPeripheral was called
    case connectionFailed = 4
    
    // didDisconnectPeripheral was called
    case disconnected = 5
    
    // An operation was passed an invalid argument.  Inspect user info for
    // specific details
    case invalidParam = 6
    
    // An operation was attempted while CBCentralManager was in a state other
    // that 'On'
    case centralNotReady = 7
    
    // A service discovery operation did not discover any services
    case noServicesDiscovered = 8
    
    // An attempt was made to perform an operation on a service that has not been discovered
    case serviceNotDiscovered = 9
    
    // An attempt was made to read from a characterstic that has not been discovered
    case characteristicNotDiscovered = 10
    
    // An attempt was made to read from a descriptor that has not been discovered
    case descriptorNotDiscovered = 11
    
    // Bluetooth is turned off
    case bluetoothDisabled = 12
}

internal extension UUCoreBluetoothErrorCode
{
    var errorDescription: String
    {
        switch (self)
        {
            case .timeout:
                return "Timeout"
                
            case .notConnected:
                return "NotConnected"
                
            case .operationFailed:
                return "OperationFailed"
                
            case .connectionFailed:
                return "ConnectionFailed"
                
            case .disconnected:
                return "Disconnected"
                
            case .invalidParam:
                return "InvalidParam"
                
            case .centralNotReady:
                return "CentralNotReady"
            
            case .noServicesDiscovered:
                return "NoServicesDiscovered"
            
            case .serviceNotDiscovered:
                return "ServiceNotDiscovered"
            
            case .characteristicNotDiscovered:
                return "CharacteristicNotDiscovered"
            
            case .descriptorNotDiscovered:
                return "DescriptorNotDiscovered"
            
            case .bluetoothDisabled:
                return "BluetoothDisabled"
        }
    }
    
    var recoverySuggestion: String
    {
        switch (self)
        {
            case .timeout:
                return "Make sure the peripheral is connected and in range, and try again."
                
            case .notConnected:
                return "Connect to the peripheral and try the operation again."
                
            case .operationFailed:
                return "Inspect inner error for more details."
                
            case .connectionFailed:
                return "Connection attempt failed."
                
            case .disconnected:
                return "Peripheral disconnected."
                
            case .invalidParam:
                return "An invalid parameter was passed in."
                
            case .centralNotReady:
                return "Core Bluetooth is not ready to accept commands."
            
            case .noServicesDiscovered:
                return "No services were discovered on the peripheral."
            
            case .serviceNotDiscovered:
                return "A service was not discovered on the peripheral."
            
            case .characteristicNotDiscovered:
                return "A characteristic was not discovered on the peripheral."
            
            case .descriptorNotDiscovered:
                return "A descriptor was not discovered on the peripheral."
            
            case .bluetoothDisabled:
                return "Turn bluetooth on and try again."
        }
    }
}



public extension NSError
{
    var uuBluetoothErrorCode: UUCoreBluetoothErrorCode?
    {
        if (domain == kUUCoreBluetoothErrorDomain)
        {
            return UUCoreBluetoothErrorCode(rawValue: code)
        }
        
        return nil
    }
}

public extension Error
{
    var uuBluetoothErrorCode: UUCoreBluetoothErrorCode?
    {
        return (self as NSError).uuBluetoothErrorCode
    }
}
