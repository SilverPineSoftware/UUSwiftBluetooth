//
//  UUPeripheralSessionTests.swift
//  UUSwiftBluetoothTests
//
//  Created by Ryan DeVore on 7/1/25.
//

import XCTest
import UUSwiftTestCore
import UUSwiftCore
import CoreBluetooth

@testable import UUSwiftBluetooth

final class UUPeripheralSessionTests: XCTestCase
{
    public override func setUpWithError() throws
    {
        let logger = UULogger.console
        logger.logLevel = .debug
        
        UULog.setLogger(logger)
    }
    
    private func setupMockPeripheral() throws -> UUMockPeripheral
    {
        let peripheralOpt = UUMockPeripheral.loadFromJson(bundle: Bundle(for: Self.self), fileName: "ti_sensor_tag")
        let peripheral = try XCTUnwrap(peripheralOpt)
        
        return peripheral
    }
    
    func test_0001_setupSession() throws
    {
        let peripheral = try setupMockPeripheral()
        
        let startExp = uuExpectationForMethod(tag: "start")
        let endExp = uuExpectationForMethod(tag: "end")
        
        // Inject a full 'discovered' GATT db tree
        //peripheral.mockPeripheral.backingPeripheral.setValue(peripheral.mockPeripheral.mockServices, forKey: "services")
        
        let session = TiSensorTagCoreBluetoothSession(peripheral: peripheral)
        //let session = UUPeripheralSession(peripheral: peripheral)
        session.started =
        { startedSession in
            NSLog("Session was started")
            startExp.fulfill()
        }

        session.ended =
        { endedSession, error in
            NSLog("Session was ended, error: \(String(describing: error))")
            endExp.fulfill()
        }

        NSLog("Starting peripheral session")
        session.start()

        wait(for: [startExp], timeout: 30)
        
        NSLog("Sleeping a while")
        //testWait(5.0)
        
        session.end(error: nil)

        NSLog("Waiting for session to end")
        wait(for: [endExp], timeout: 30)

        NSLog("Done")
    }
    
    func test_0002_wworWrite() throws
    {
        let peripheral = try setupMockPeripheral()
        
        let startExp = uuExpectationForMethod(tag: "start")
        let endExp = uuExpectationForMethod(tag: "end")
        
        let session = TiSensorTagCoreBluetoothSession(peripheral: peripheral)
        session.started =
        { startedSession in
            NSLog("Session was started")
            startExp.fulfill()
        }

        session.ended =
        { endedSession, error in
            NSLog("Session was ended, error: \(String(describing: error))")
            endExp.fulfill()
        }

        NSLog("Starting peripheral session")
        session.start()

        wait(for: [startExp], timeout: 30)
        
        let writeExp = uuExpectationForMethod(tag: "write")
        var writeError: Error? = nil
        let data = try XCTUnwrap("ABCD".uuToHexData())
        let char: CBUUID = TiSensorTag.Temperature.config
        session.write(data: data, to: char, withResponse: false)
        { session, error in
        
            writeError = error
            writeExp.fulfill()
        }
        
        wait(for: [writeExp], timeout: 30)
        XCTAssertNil(writeError)
        
        NSLog("Sleeping a while before ending session")
        session.end(error: nil)

        NSLog("Waiting for session to end")
        wait(for: [endExp], timeout: 30)

        NSLog("Done")
    }
}
