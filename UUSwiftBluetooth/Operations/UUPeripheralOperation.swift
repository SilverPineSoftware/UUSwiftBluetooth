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

open class UUPeripheralOperation<Result>
{
    public let peripheral: UUPeripheral
    
    public private(set) var session: UUPeripheralSession
    
    private var operationCallback: ((Result?, Error?)->())? = nil
    
    private(set) public var operationResult: Result? = nil
    
    public init(_ peripheral: UUPeripheral, configuration: UUPeripheralSessionConfiguration = UUPeripheralSessionConfiguration())
    {
        self.peripheral = peripheral
        
        self.session = UUCoreBluetoothPeripheralSession(peripheral: peripheral)
        self.session.configuration = configuration
        session.sessionStarted = { session in
            self.internalExecute()
        }
        
        session.sessionEnded = { session, error in
            self.operationCallback?(self.operationResult, error)
        }
    }
    
    public func start(_ completion: @escaping(Result?, Error?)->())
    {
        self.operationCallback = completion
        
        session.start()
    }
    
    public func end(result: Result?, error: Error?)
    {
        UULog.debug(tag: LOG_TAG, message: "**** Ending Operation with result: \(String(describing: result)),  error: \(error?.localizedDescription ?? "nil")")
        self.operationResult = result
        
        session.end(error: error)
    }
    
    open func execute(_ completion: @escaping (Result?, Error?)->())
    {
        completion(nil, nil)
    }
    
    private func internalExecute()
    {
        execute
        { result, err in
            self.end(result: result, error: err)
        }
    }
    
}
