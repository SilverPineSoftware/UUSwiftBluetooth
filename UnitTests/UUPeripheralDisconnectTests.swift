import XCTest
import CoreBluetooth
@testable import UUSwiftBluetooth

/// Regression coverage for review #3: disconnect completes pending operations
/// instead of dropping their handlers and timers.
final class UUPeripheralDisconnectTests: XCTestCase
{
    private enum Operation: CaseIterable
    {
        case services, includedServices, characteristics, descriptors
        case characteristicRead, descriptorRead, characteristicWrite, descriptorWrite
        case notifyState, rssi, channelOpen
    }

    func test_disconnectCompletesPendingServiceDiscovery() throws
    {
        try assertDisconnectCompletes(.services)
    }

    func test_disconnectCompletesPendingIncludedServiceDiscovery() throws
    {
        try assertDisconnectCompletes(.includedServices)
    }

    func test_disconnectCompletesPendingCharacteristicDiscovery() throws
    {
        try assertDisconnectCompletes(.characteristics)
    }

    func test_disconnectCompletesPendingDescriptorDiscovery() throws
    {
        try assertDisconnectCompletes(.descriptors)
    }

    func test_disconnectCompletesPendingCharacteristicRead() throws
    {
        try assertDisconnectCompletes(.characteristicRead)
    }

    func test_disconnectCompletesPendingDescriptorRead() throws
    {
        try assertDisconnectCompletes(.descriptorRead)
    }

    func test_disconnectCompletesPendingCharacteristicWrite() throws
    {
        try assertDisconnectCompletes(.characteristicWrite)
    }

    func test_disconnectCompletesPendingDescriptorWrite() throws
    {
        try assertDisconnectCompletes(.descriptorWrite)
    }

    func test_disconnectCompletesPendingNotifyStateChange() throws
    {
        try assertDisconnectCompletes(.notifyState)
    }

    func test_disconnectCompletesPendingRSSIRead() throws
    {
        try assertDisconnectCompletes(.rssi)
    }

    func test_disconnectCompletesPendingChannelOpen() throws
    {
        try assertDisconnectCompletes(.channelOpen)
    }


    func test_disconnectCompletesReadWithTimeoutDisabled() throws
    {
        try assertDisconnectCompletes(.characteristicRead, timeout: -1)
    }

    func test_errorDisconnectCompletesPendingRead() throws
    {
        try assertDisconnectCompletes(.characteristicRead,
            disconnectError: NSError(domain: "DisconnectTests", code: 42))
    }

    func test_responseBeforeDisconnectCompletesReadOnlyOnce() throws
    {
        let fixture = Fixture()
        let connected = expectation(description: "connected")
        let disconnected = expectation(description: "disconnected")
        fixture.connect(connected: { connected.fulfill() }, disconnected: { _ in disconnected.fulfill() })
        wait(for: [connected], timeout: 2)

        var results: [Error?] = []
        fixture.central.dispatchQueue.sync
        {
            self.start(.characteristicRead, fixture: fixture, timeout: 60)
            { error in results.append(error) }
            XCTAssertEqual(fixture.backend.responses.count, 1)
            fixture.backend.deliverResponses()
            XCTAssertEqual(results.count, 1)
            XCTAssertNil(results.first!)
            fixture.peripheral.disconnect()
        }
        wait(for: [disconnected], timeout: 2)
        fixture.central.dispatchQueue.sync
        {
            XCTAssertEqual(results.count, 1, "Disconnect must not complete an already-finished read again")
        }
    }

    func test_disconnectCompletesDifferentPendingOperationsBeforeConnectionCallback() throws
    {
        let fixture = Fixture()
        let connected = expectation(description: "connected")
        let disconnected = expectation(description: "disconnected")
        var completed: [Operation] = []
        fixture.connect(connected: { connected.fulfill() }, disconnected:
        { _ in
            XCTAssertEqual(completed.count, Operation.allCases.count)
            disconnected.fulfill()
        })
        wait(for: [connected], timeout: 2)

        fixture.central.dispatchQueue.sync
        {
            for operation in Operation.allCases
            {
                self.start(operation, fixture: fixture, timeout: 60)
                { error in
                    XCTAssertEqual(error?.uuBluetoothErrorCode, .disconnected)
                    completed.append(operation)
                }
            }
            XCTAssertEqual(fixture.backend.responses.count, Operation.allCases.count)
            fixture.peripheral.disconnect()
        }
        wait(for: [disconnected], timeout: 2)
        fixture.central.dispatchQueue.sync
        {
            fixture.backend.deliverResponses()
            XCTAssertEqual(completed.count, Operation.allCases.count)
            for operation in Operation.allCases
            {
                XCTAssertEqual(completed.filter { $0 == operation }.count, 1)
            }
        }
    }

    func test_disconnectCompletionCanStartAnotherReadWithoutLosingItsHandler() throws
    {
        let fixture = Fixture()
        let connected = expectation(description: "connected")
        let disconnected = expectation(description: "disconnected")
        let retried = expectation(description: "reentrant read rejected as disconnected")
        retried.assertForOverFulfill = true
        var firstCount = 0
        var retryCount = 0
        fixture.connect(connected: { connected.fulfill() }, disconnected: { _ in disconnected.fulfill() })
        wait(for: [connected], timeout: 2)

        fixture.central.dispatchQueue.sync
        {
            fixture.peripheral.readValue(for: fixture.characteristic, timeout: 60)
            { data, error in
                firstCount += 1
                XCTAssertNil(data)
                XCTAssertEqual(error?.uuBluetoothErrorCode, .disconnected)
                fixture.peripheral.readValue(for: fixture.characteristic, timeout: 60)
                { data, error in
                    retryCount += 1
                    XCTAssertEqual(error?.uuBluetoothErrorCode, .notConnected)
                    retried.fulfill()
                }
            }
            fixture.peripheral.disconnect()
        }
        wait(for: [disconnected, retried], timeout: 2)
        fixture.central.dispatchQueue.sync
        {
            fixture.backend.deliverResponses()
            XCTAssertEqual(firstCount, 1)
            XCTAssertEqual(retryCount, 1)
        }
    }

    func test_disconnectRemovesNotificationSubscriptionWithoutSendingSyntheticData() throws
    {
        let fixture = Fixture()
        let connected = expectation(description: "connected")
        let disconnected = expectation(description: "disconnected")
        var notifications = 0
        var enabled = false
        fixture.connect(connected: { connected.fulfill() }, disconnected: { _ in disconnected.fulfill() })
        wait(for: [connected], timeout: 2)
        fixture.central.dispatchQueue.sync
        {
            fixture.peripheral.setNotifyValue(enabled: true, for: fixture.characteristic,
                notifyHandler: { _, _ in notifications += 1 }, completion:
                { error in
                    XCTAssertNil(error)
                    enabled = true
                })
            fixture.backend.deliverResponses()
            XCTAssertTrue(enabled)
            fixture.peripheral.disconnect()
        }
        wait(for: [disconnected], timeout: 2)
        fixture.central.dispatchQueue.sync
        {
            fixture.backend.delegate?.peripheral?(fixture.backend.backingPeripheral,
                didUpdateValueFor: fixture.characteristic, error: nil)
            XCTAssertEqual(notifications, 0)
        }
    }

    private func assertDisconnectCompletes(
        _ operation: Operation,
        timeout: TimeInterval = 60,
        disconnectError: Error? = nil,
        file: StaticString = #filePath,
        line: UInt = #line) throws
    {
        let fixture = Fixture()
        let connected = expectation(description: "connected")
        let disconnected = expectation(description: "connection disconnected")
        let completed = expectation(description: "pending \(operation) completes with disconnect error")
        completed.assertForOverFulfill = true
        var results: [Error?] = []

        fixture.connect(connected: { connected.fulfill() }, disconnected:
        { error in
            if disconnectError == nil
            {
                XCTAssertNil(error, "A clean connection disconnect should stay clean", file: file, line: line)
            }
            else
            {
                XCTAssertNotNil(error, file: file, line: line)
            }
            disconnected.fulfill()
        })
        wait(for: [connected], timeout: 2)

        fixture.central.dispatchQueue.sync
        {
            self.start(operation, fixture: fixture, timeout: timeout)
            { error in
                results.append(error)
                XCTAssertEqual(error?.uuBluetoothErrorCode, .disconnected, file: file, line: line)
                if let expected = disconnectError as NSError?
                {
                    let underlying = (error as NSError?)?.userInfo[NSUnderlyingErrorKey] as? NSError
                    XCTAssertEqual(underlying?.domain, expected.domain, file: file, line: line)
                    XCTAssertEqual(underlying?.code, expected.code, file: file, line: line)
                }
                completed.fulfill()
            }
            // Proves the operation reached the backend rather than failing validation.
            XCTAssertEqual(fixture.backend.responses.count, 1, file: file, line: line)
            XCTAssertTrue(results.isEmpty, "The response is explicitly held pending", file: file, line: line)
            fixture.mockCentral.mockCallbackError = disconnectError
            fixture.peripheral.disconnect()
        }

        wait(for: [disconnected, completed], timeout: 2)
        fixture.central.dispatchQueue.sync
        {
            XCTAssertEqual(results.count, 1, "Disconnect must complete pending work once", file: file, line: line)
            // A stale native response must not revive the operation or report success.
            fixture.backend.deliverResponses()
            XCTAssertEqual(results.count, 1, "A late response must not complete the operation again", file: file, line: line)
        }
    }

    private func start(_ operation: Operation, fixture: Fixture, timeout: TimeInterval,
                       completion: @escaping (Error?) -> Void)
    {
        let p = fixture.peripheral
        switch operation
        {
        case .services:
            p.discoverServices(timeout: timeout) { _, error in completion(error) }
        case .includedServices:
            p.discoverIncludedServices(includedServiceUUIDs: nil, for: fixture.service, timeout: timeout)
            { _, error in completion(error) }
        case .characteristics:
            p.discoverCharacteristics(characteristicUUIDs: nil, for: fixture.service, timeout: timeout)
            { _, error in completion(error) }
        case .descriptors:
            p.discoverDescriptors(for: fixture.characteristic, timeout: timeout)
            { _, error in completion(error) }
        case .characteristicRead:
            p.readValue(for: fixture.characteristic, timeout: timeout) { _, error in completion(error) }
        case .descriptorRead:
            p.readValue(for: fixture.descriptor, timeout: timeout) { _, error in completion(error) }
        case .characteristicWrite:
            p.writeValue(data: Data([1]), for: fixture.characteristic, timeout: timeout, completion: completion)
        case .descriptorWrite:
            p.writeValue(data: Data([1]), for: fixture.descriptor, timeout: timeout, completion: completion)
        case .notifyState:
            p.setNotifyValue(enabled: true, for: fixture.characteristic, timeout: timeout,
                             notifyHandler: nil, completion: completion)
        case .rssi:
            p.readRSSI(timeout: timeout) { _, error in completion(error) }
        case .channelOpen:
            p.openL2CAPChannel(psm: 128, timeout: timeout) { _, error in completion(error) }
        }
    }

    private final class Fixture
    {
        let service = CBMutableService(type: CBUUID(string: "180A"), primary: true)
        let characteristic = CBMutableCharacteristic(type: CBUUID(string: "2A29"),
            properties: [.read, .write, .notify], value: nil, permissions: [.readable, .writeable])
        let descriptor = CBMutableDescriptor(type: CBUUID(string: "2901"), value: "Test")
        let backend: HeldResponsePeripheral
        let central: UUCentralManager
        let mockCentral: UUMockCBCentralManager
        let peripheral: UUPeripheral

        init()
        {
            characteristic.descriptors = [descriptor]
            service.characteristics = [characteristic]
            // Match the existing mocks' GATT back-pointer setup.
            characteristic.setValue(service, forKey: "service")
            descriptor.setValue(characteristic, forKey: "characteristic")
            backend = HeldResponsePeripheral(services: [service])
            let native = backend.backingPeripheral
            var injected: UUMockCBCentralManager!
            central = UUCentralManager(options: UUCentralManagerOptions(), injection:
            { queue, options in
                let delegate = UUCentralManagerDelegate()
                let mock = UUMockCBCentralManager(delegate: delegate, queue: queue, options: options.coreBluetoothOptions)
                mock.mockPeripherals = [native]
                mock.mockDispatchQueue = queue
                mock.mockCallbackTime = 0
                injected = mock
                return (delegate, mock)
            })
            mockCentral = injected
            peripheral = UUPeripheral(centralManager: central, peripheral: backend,
                                      advertisement: UUAdvertisement(identifier: native.identifier))
        }

        func connect(connected: @escaping () -> Void, disconnected: @escaping (Error?) -> Void)
        {
            central.dispatchQueue.sync
            {
                peripheral.connect(connected: connected, disconnected: disconnected)
            }
        }
    }
}

/// Test-only backend: native responses are released by the test, never by sleeps.
/// It inherits the existing mock's native object bridge but bypasses delayed responses.
final class HeldResponsePeripheral: UUMockCBPeripheral
{
    var responses: [() -> Void] = []

    func deliverResponses()
    {
        let pending = responses
        responses.removeAll()
        pending.forEach { $0() }
    }

    override func discoverServices(_ serviceUUIDs: [CBUUID]?)
    {
        responses.append { self.delegate?.peripheral?(self.backingPeripheral, didDiscoverServices: nil) }
    }

    override func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, for service: CBService)
    {
        responses.append { self.delegate?.peripheral?(self.backingPeripheral, didDiscoverIncludedServicesFor: service, error: nil) }
    }

    override func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBService)
    {
        responses.append { self.delegate?.peripheral?(self.backingPeripheral, didDiscoverCharacteristicsFor: service, error: nil) }
    }

    override func discoverDescriptors(for characteristic: CBCharacteristic)
    {
        responses.append { self.delegate?.peripheral?(self.backingPeripheral, didDiscoverDescriptorsFor: characteristic, error: nil) }
    }

    override func readValue(for characteristic: CBCharacteristic)
    {
        responses.append { self.delegate?.peripheral?(self.backingPeripheral, didUpdateValueFor: characteristic, error: nil) }
    }

    override func readValue(for descriptor: CBDescriptor)
    {
        responses.append { self.delegate?.peripheral?(self.backingPeripheral, didUpdateValueFor: descriptor, error: nil) }
    }

    override func writeValue(_ data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType)
    {
        responses.append { self.delegate?.peripheral?(self.backingPeripheral, didWriteValueFor: characteristic, error: nil) }
    }

    override func writeValue(_ data: Data, for descriptor: CBDescriptor)
    {
        responses.append { self.delegate?.peripheral?(self.backingPeripheral, didWriteValueFor: descriptor, error: nil) }
    }

    override func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristic)
    {
        responses.append { self.delegate?.peripheral?(self.backingPeripheral, didUpdateNotificationStateFor: characteristic, error: nil) }
    }

    override func readRSSI()
    {
        responses.append { self.delegate?.peripheral?(self.backingPeripheral, didReadRSSI: -50, error: nil) }
    }

    override func openL2CAPChannel(_ PSM: CBL2CAPPSM)
    {
        responses.append { self.delegate?.peripheral?(self.backingPeripheral, didOpen: nil, error: nil) }
    }
}
