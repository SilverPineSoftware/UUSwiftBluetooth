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
    // Keep an accepted operation alive until its terminal session callback.
    private var retainedWhileRunning: UUPeripheralOperation<Result>? = nil
    
    private(set) public var operationResult: Result? = nil
    
    public init(_ peripheral: UUPeripheral, centralManager: UUCentralManager, configuration: UUPeripheralSessionConfiguration = UUPeripheralSessionConfiguration())
    {
        self.peripheral = peripheral
        
        self.session = UUPeripheralSession(peripheral: peripheral, centralManager: centralManager)
        self.session.configuration = configuration
        session.started = { [weak self] _ in
            self?.internalExecute()
        }
        
        session.ended = { [weak self] _, error in
            guard let self else { return }
            let callback = self.operationCallback
            self.operationCallback = nil
            self.retainedWhileRunning = nil
            callback?(self.operationResult, error)
        }
    }
    
    /// Starts the operation and retains it until the session's terminal callback.
    /// The completion is released before it is invoked.
    public func start(_ completion: @escaping(Result?, Error?)->())
    {
        self.operationCallback = completion
        retainedWhileRunning = self
        
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
        { [weak self] result, err in
            self?.end(result: result, error: err)
        }
    }
    
}
