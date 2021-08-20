//
//  UUCoreBluetoothErrorCode.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 8/13/21.
//

import UIKit

public enum UUCoreBluetoothErrorCode: Int
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
}

extension UUCoreBluetoothErrorCode
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
                
            //default:
            //    return "UUCoreBluetoothErrorCode-\(rawValue)"
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
            
            //default:
            //    return ""
        }
    }
}
