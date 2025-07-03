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
    
    private func loadMockPeripheral() -> UUMockPeripheral?
    {
        let bundle = Bundle(for: Self.self)
        
        //guard let path = bundle.path(forResource: "atmotube_pro", ofType: "json") else
        guard let path = bundle.path(forResource: "ti_sensor_tag", ofType: "json") else
        {
            NSLog("Unable to load file from bundle")
            return nil
        }
        
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else
        {
            NSLog("Unable to create data from file")
            return nil
        }
        
        guard let peripheralData = try? JSONDecoder().decode(UUPeripheralRepresentation.self, from: data) else
        {
            NSLog("Unable to load JSON representation")
            return nil
        }
        
        let check = peripheralData.uuToJsonString()
        UULog.debug(tag: "Import", message: check)
        
        return peripheralData.mockPeripheral
    }
    
    private func setupMockPeripheral() throws -> UUMockPeripheral
    {
        let peripheral = try XCTUnwrap(loadMockPeripheral())
        
        return peripheral
    }
    
    func test_0001_setupSession() throws
    {
        let peripheral = try setupMockPeripheral()
        
        let startExp = uuExpectationForMethod(tag: "start")
        let endExp = uuExpectationForMethod(tag: "end")
        
        let session = TiSensorTagCoreBluetoothSession(peripheral: peripheral)
        //let session = UUPeripheralSession(peripheral: peripheral)
        session.started =
        { startedSession in
            NSLog("Session was started")
            startExp.fulfill()
        }

        session.ended =
        { endedSession, error in
            NSLog("Session was ended, error: $error")
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
            NSLog("Session was ended, error: $error")
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
