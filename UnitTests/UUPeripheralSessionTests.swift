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
            let mock = TestCentralManager(delegate: delegate, queue: queue, options: options.coreBluetoothOptions)
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
        let backend = TestPeripheral()
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

    private final class NeverRespondingCentral: TestCentralManager
    {
        override func connect(_ peripheral: CBPeripheral, options: [String: Any]?) {}
    }

    private final class PendingDiscoveryPeripheral: TestPeripheral
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
    
}
