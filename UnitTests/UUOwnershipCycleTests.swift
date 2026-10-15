import XCTest
import CoreBluetooth
@testable import UUSwiftBluetooth

final class UUOwnershipCycleTests: XCTestCase
{
    func test_operationStaysAliveUntilCompletionThenReleasesCallbacks()
    {
        let fixture = OperationFixture()
        let completed = expectation(description: "Operation completed")
        var operation: UUPeripheralOperation<Int>? = UUPeripheralOperation(fixture.peripheral,
            centralManager: fixture.central)
        operation?.session.configuration.connectTimeout = -1
        operation?.session.configuration.serviceDiscoveryTimeout = -1
        weak var weakOperation: UUPeripheralOperation<Int>?
        weakOperation = operation
        operation?.start { _, error in
            XCTAssertNil(error)
            completed.fulfill()
        }
        operation = nil
        fixture.flush()

        XCTAssertNotNil(weakOperation, "An accepted operation must live through its terminal callback")
        fixture.connect()
        wait(for: [fixture.disconnectRequested], timeout: 2)
        fixture.disconnect()
        wait(for: [completed], timeout: 2)
        fixture.flush()
        XCTAssertNil(weakOperation, "A completed operation must release its session callbacks")
    }

    func test_releasedSnifferDoesNotRetainItselfThroughDelegate()
    {
        weak var weakSniffer: UUBluetoothSniffer?
        autoreleasepool
        {
            let sniffer = UUBluetoothSniffer()
            weakSniffer = sniffer
        }
        XCTAssertNil(weakSniffer)
    }

    func test_completedOperationReleasesCompletionWhileCallerRetainsOperation()
    {
        let fixture = OperationFixture()
        let completed = expectation(description: "Operation completed")
        let operation = UUPeripheralOperation<Int>(fixture.peripheral, centralManager: fixture.central)
        operation.session.configuration.connectTimeout = -1
        var token: Token? = Token()
        weak var weakToken: Token?
        weakToken = token
        operation.start { [token] _, error in
            withExtendedLifetime(token) {}
            XCTAssertNil(error)
            completed.fulfill()
        }
        token = nil

        fixture.flush()
        fixture.connect()
        wait(for: [fixture.disconnectRequested], timeout: 2)
        fixture.disconnect()
        wait(for: [completed], timeout: 2)
        XCTAssertNil(weakToken, "A retained completed operation must release its completion closure")
        withExtendedLifetime(operation) {}
    }

    private final class Token {}

    private final class OperationFixture
    {
        let backend = UUMockCBPeripheral()
        let delegate = UUCentralManagerDelegate()
        let central: UUCentralManager
        let peripheral: UUPeripheral
        let disconnectRequested = XCTestExpectation(description: "Disconnect requested")

        init()
        {
            let native = backend.backingPeripheral
            let centralDelegate = delegate
            let request = disconnectRequested
            central = UUCentralManager(options: UUCentralManagerOptions(), injection: { queue, options in
                let mock = HeldConnectionCentral(delegate: centralDelegate, queue: queue,
                    options: options.coreBluetoothOptions)
                mock.mockPeripherals = [native]
                mock.disconnectRequested = { request.fulfill() }
                return (centralDelegate, mock)
            })
            backend.mockDispatchQueue = central.dispatchQueue
            backend.mockCallbackTime = 0
            peripheral = UUPeripheral(dispatchQueue: central.dispatchQueue,
                centralState: central.centralState, peripheral: backend,
                advertisement: UUAdvertisement(identifier: native.identifier))
        }

        func flush() { central.dispatchQueue.sync {} }

        func connect()
        {
            central.dispatchQueue.sync
            {
                backend.mockSetState(.connected)
                delegate.connectBlocks[peripheral.identifier]?(backend.backingPeripheral)
            }
        }

        func disconnect()
        {
            central.dispatchQueue.sync
            {
                backend.mockSetState(.disconnected)
                central.notifyDisconnect(peripheral.identifier, nil)
            }
        }
    }

    private final class HeldConnectionCentral: UUMockCBCentralManager
    {
        var disconnectRequested: (() -> Void)?
        override func connect(_ peripheral: CBPeripheral, options: [String: Any]?) {}
        override func cancelPeripheralConnection(_ peripheral: CBPeripheral)
        {
            disconnectRequested?()
        }
    }
}
