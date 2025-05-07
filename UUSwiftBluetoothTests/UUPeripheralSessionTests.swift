//
//  UUPeripheralSessionTests.swift
//  UUSwiftBluetoothTests
//
//  Created by Ryan DeVore on 5/4/25.
//

import XCTest
import UUSwiftCore
@testable import UUSwiftBluetooth
import UUSwiftTestCore
import UUSwiftTestCoreUX
import CoreBluetooth

final class UUPeripheralSessionTests: XCTestCase
{
    override func setUpWithError() throws
    {
        let logger = UULogger.console
        logger.logLevel = .debug
        
        UULog.setLogger(logger)
        
        TiSensorTag.addSpecNames()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws
    {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws
    {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws
    {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testSessionConnect() async throws
    {
        UUTestSetTitle("Peripheral Session Test")
        
        let startExp = uuExpectationForMethod(tag: "session_start")
        let endExp = uuExpectationForMethod(tag: "session_end")
        
        UUTestAddLine("Scanning for peripheral")
        let scanner = UUCoreBluetooth.defaultScanner
        let peripheralOpt = await scanner.scanForPeripheral(timeout: 10, filter: UUPeripheralNameFilter("CC2650 SensorTag"))
        let peripheral = try XCTUnwrap(peripheralOpt)
        
        UUTestAddLine("Found peripheral")
        //let session = UUCoreBluetoothPeripheralSession(peripheral: peripheral)
        let session = TiSensorTagCoreBluetoothSession(peripheral: peripheral)
        
        session.sessionStarted =
        { s in
            UUTestAddLine("Session Started")
            startExp.fulfill()
        }
        
        session.sessionEnded =
        { s, err in
            UUTestAddLine("session ended, err: \(String(describing: err))")
            endExp.fulfill()
        }
        
        UUTestAddLine("Starting session")
        session.start()
        
        await fulfillment(of: [startExp], timeout: 30)
        
        UUTestAddLine("Waiting a while...")
        session.startTimer(name: "test", timeout: 10.0)
        {
            UUTestAddLine("Ending session")
            session.end(error: nil)
        }
        
        await fulfillment(of: [endExp], timeout: 30)
        
        UUTestAddLine("Test done")
    }

}
