//
//  UUSwiftBluetoothLiveTests.swift
//  UUSwiftBluetoothLiveTests
//
//  Created by Ryan DeVore on 5/12/25.
//

import XCTest
import UUSwiftCore
@testable import UUSwiftBluetooth
import UUSwiftTestCore
import UUSwiftTestCoreUX
import CoreBluetooth

final class UUSwiftBluetoothLiveTests: XCTestCase
{
    override func setUpWithError() throws
    {
        let logger = UULogger.console
        logger.logLevel = .debug
        
        UULog.setLogger(logger)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_scanner() throws
    {
        UUTestSetTitle("Scanner Test")
        
        let exp = uuExpectationForMethod()
        
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        var scanner = UUBluetooth.scanner
        
        let config = UUPeripheralScannerConfig()
        //settings.serviceUUIDs = []
        scanner.config = config
        
        var discoveredPeripherals: [UUPeripheral] = []
        scanner.listChanged =
        { _, peripherals in
            print("Scan callback: \(peripherals)")
            
            discoveredPeripherals.removeAll()
            discoveredPeripherals.append(contentsOf: peripherals)
            
            UUTestAddLine("Scan callback, got \(peripherals.count) peripherals")
        }
        
        scanner.start()
        
        UUTimerPool.shared.start(identifier: "test", timeout: 10, userInfo: nil, block:
        { _ in
            
            exp.fulfill()
            
        })
        
        uuWaitForExpectations()
                                 
        print("Found \(discoveredPeripherals.count) peripherals")
    }

}
