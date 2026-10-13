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
    func test_pendingConnectionDoesNotRetainAbandonedSession()
    {
        let (central, peripheral, delegate) = connectionFixture()

        func startAndReleaseSession() -> WeakSessionBox
        {
            let session = UUPeripheralSession(peripheral: peripheral, centralManager: central)
            session.configuration.connectTimeout = -1
            session.start()
            central.dispatchQueue.sync {}
            return WeakSessionBox(session)
        }

        let box = startAndReleaseSession()
        XCTAssertNotNil(delegate.disconnectBlocks[peripheral.identifier], "The connection callback must remain registered")
        XCTAssertNil(box.value, "The central's connection callback must not retain the session")
        central.dispatchQueue.sync { central.notifyDisconnect(peripheral.identifier, nil) }
    }

    func test_retainedSessionReceivesDisconnectCallback()
    {
        let (central, peripheral, _) = connectionFixture()
        let session = UUPeripheralSession(peripheral: peripheral, centralManager: central)
        session.configuration.connectTimeout = -1
        var endCount = 0
        session.ended = { _, _ in endCount += 1 }
        session.start()
        central.dispatchQueue.sync {}
        central.dispatchQueue.sync { central.notifyDisconnect(peripheral.identifier, nil) }
        XCTAssertEqual(endCount, 1)
        withExtendedLifetime(session) {}
    }

    func test_pendingServiceDiscoveryDoesNotRetainAbandonedSession()
    {
        let backend = PendingDiscoveryPeripheral()
        let native = backend.backingPeripheral
        let delegate = UUCentralManagerDelegate()
        let central = UUCentralManager(options: UUCentralManagerOptions(), injection: { queue, options in
            let mock = UUMockCBCentralManager(delegate: delegate, queue: queue, options: options.coreBluetoothOptions)
            mock.mockPeripherals = [native]
            mock.mockDispatchQueue = queue
            mock.mockCallbackTime = 0
            return (delegate, mock)
        })
        let peripheral = UUPeripheral(dispatchQueue: central.dispatchQueue,
                                      centralState: central.centralState,
                                      peripheral: backend,
                                      advertisement: UUAdvertisement(identifier: native.identifier))
        let discoveryStarted = expectation(description: "Session submitted service discovery")
        backend.discoveryStarted = { discoveryStarted.fulfill() }

        func startAndReleaseSession() -> WeakSessionBox
        {
            let session = UUPeripheralSession(peripheral: peripheral, centralManager: central)
            session.configuration.serviceDiscoveryTimeout = -1
            session.start()
            wait(for: [discoveryStarted], timeout: 2)
            return WeakSessionBox(session)
        }

        let box = startAndReleaseSession()
        XCTAssertNil(box.value, "Pending GATT callbacks must not retain the session")
        central.dispatchQueue.sync { central.notifyDisconnect(peripheral.identifier, nil) }
    }

    private func connectionFixture() -> (UUCentralManager, UUPeripheral, UUCentralManagerDelegate)
    {
        let backend = UUMockCBPeripheral()
        let native = backend.backingPeripheral
        let delegate = UUCentralManagerDelegate()
        let central = UUCentralManager(options: UUCentralManagerOptions(), injection: { queue, options in
            let mock = NeverRespondingCentral(delegate: delegate, queue: queue, options: options.coreBluetoothOptions)
            mock.mockPeripherals = [native]
            return (delegate, mock)
        })
        let peripheral = UUPeripheral(dispatchQueue: central.dispatchQueue,
                                      centralState: central.centralState,
                                      peripheral: backend,
                                      advertisement: UUAdvertisement(identifier: native.identifier))
        return (central, peripheral, delegate)
    }

    private final class WeakSessionBox
    {
        weak var value: UUPeripheralSession?

        init(_ session: UUPeripheralSession) { value = session }
    }

    private final class NeverRespondingCentral: UUMockCBCentralManager
    {
        override func connect(_ peripheral: CBPeripheral, options: [String: Any]?) {}
    }

    private final class PendingDiscoveryPeripheral: UUMockCBPeripheral
    {
        var discoveryStarted: (() -> Void)?

        override func discoverServices(_ serviceUUIDs: [CBUUID]?)
        {
            discoveryStarted?()
        }
    }

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
    
    /*
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
    }*/
}
