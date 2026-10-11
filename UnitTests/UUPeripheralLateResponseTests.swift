import XCTest
import CoreBluetooth
@testable import UUSwiftBluetooth

/// Review #5: a timed-out native request must not consume a later request's callback.
/// These regressions intentionally fail until timeout recovery has a safe boundary.
final class UUPeripheralLateResponseTests: XCTestCase
{
    private enum Operation
    {
        case services, includedServices, characteristics, descriptors
        case characteristicRead, descriptorRead, characteristicWrite, descriptorWrite
        case notifyState, rssi, channelOpen
    }

    func test_lateServiceDiscoveryResponseDoesNotCompleteRetry()
    {
        assertLateResponseDoesNotCompleteRetry(.services)
    }

    func test_lateIncludedServiceDiscoveryResponseDoesNotCompleteRetry()
    {
        assertLateResponseDoesNotCompleteRetry(.includedServices)
    }

    func test_lateCharacteristicDiscoveryResponseDoesNotCompleteRetry()
    {
        assertLateResponseDoesNotCompleteRetry(.characteristics)
    }

    func test_lateDescriptorDiscoveryResponseDoesNotCompleteRetry()
    {
        assertLateResponseDoesNotCompleteRetry(.descriptors)
    }

    func test_lateCharacteristicReadResponseDoesNotCompleteRetry()
    {
        assertLateResponseDoesNotCompleteRetry(.characteristicRead)
    }

    func test_lateDescriptorReadResponseDoesNotCompleteRetry()
    {
        assertLateResponseDoesNotCompleteRetry(.descriptorRead)
    }

    func test_lateCharacteristicWriteResponseDoesNotCompleteRetry()
    {
        assertLateResponseDoesNotCompleteRetry(.characteristicWrite)
    }

    func test_lateDescriptorWriteResponseDoesNotCompleteRetry()
    {
        assertLateResponseDoesNotCompleteRetry(.descriptorWrite)
    }

    func test_lateNotifyStateResponseDoesNotCompleteRetry()
    {
        assertLateResponseDoesNotCompleteRetry(.notifyState)
    }

    func test_lateRSSIReadResponseDoesNotCompleteRetry()
    {
        assertLateResponseDoesNotCompleteRetry(.rssi)
    }

    func test_lateChannelOpenResponseDoesNotCompleteRetry()
    {
        assertLateResponseDoesNotCompleteRetry(.channelOpen)
    }

    func test_lateReadErrorDoesNotFailRetry()
    {
        assertLateResponseDoesNotCompleteRetry(.characteristicRead,
            lateError: NSError(domain: "LateResponseFromRequestA", code: 42))
    }

    private func assertLateResponseDoesNotCompleteRetry(
        _ operation: Operation, lateError: Error? = nil,
        file: StaticString = #filePath, line: UInt = #line)
    {
        let fixture = connectedFixture()
        defer { disconnect(fixture) }
        let timedOut = expectation(description: "A times out before B starts")
        var firstCount = 0
        var retryResults: [Error?] = []
        start(operation, fixture: fixture, timeout: 0.05)
        { error in
            firstCount += 1
            XCTAssertEqual(error?.uuBluetoothErrorCode, .timeout, file: file, line: line)
            timedOut.fulfill()
        }
        wait(for: [timedOut], timeout: 2)
        start(operation, fixture: fixture, timeout: 60)
        { error in retryResults.append(error) }
        fixture.central.dispatchQueue.sync
        {
            XCTAssertEqual(firstCount, 1, file: file, line: line)
            // A recovery policy may reject B until the old native request is drained.
            if fixture.backend.responses.count == 1
            {
                XCTAssertEqual(retryResults.count, 1, file: file, line: line)
                XCTAssertNotNil(retryResults.first ?? nil, "Unsubmitted retry needs an explicit error", file: file, line: line)
                fixture.backend.responses.removeFirst()(lateError)
                XCTAssertEqual(retryResults.count, 1, file: file, line: line)
                return
            }
            XCTAssertEqual(fixture.backend.responses.count, 2, file: file, line: line)
            XCTAssertTrue(retryResults.isEmpty, file: file, line: line)
            guard fixture.backend.responses.count == 2 else { return }
            fixture.backend.responses.removeFirst()(lateError)
            XCTAssertTrue(retryResults.isEmpty,
                "A's late response must not consume accepted request B's completion", file: file, line: line)
            fixture.backend.responses.removeFirst()(nil)
            XCTAssertEqual(retryResults.count, 1, "B must complete exactly once", file: file, line: line)
            XCTAssertNil(retryResults.first ?? nil, "B's own response succeeds", file: file, line: line)
            XCTAssertEqual(firstCount, 1, file: file, line: line)
        }
    }

    func test_lateReadReturnsNeitherStaleDataNorCancelsRetryDeadline()
    {
        let fixture = connectedFixture()
        defer { disconnect(fixture) }
        let timedOut = expectation(description: "A timeout")
        let retryTimedOut = expectation(description: "B retains its own timeout")
        var retryResults: [(Data?, Error?)] = []
        var observing = true
        fixture.peripheral.readValue(for: fixture.characteristic, timeout: 0.05)
        { _, error in
            XCTAssertEqual(error?.uuBluetoothErrorCode, .timeout)
            timedOut.fulfill()
        }
        wait(for: [timedOut], timeout: 2)
        fixture.peripheral.readValue(for: fixture.characteristic, timeout: 0.05)
        { data, error in
            guard observing else { return }
            retryResults.append((data, error))
            if error != nil { retryTimedOut.fulfill() }
        }
        fixture.central.dispatchQueue.sync
        {
            fixture.characteristic.value = Data([0xAA])
            XCTAssertFalse(fixture.backend.responses.isEmpty)
            fixture.backend.responses.removeFirst()(nil)
            if let result = retryResults.first
            {
                // Explicit recovery rejection is valid; a stale success is not.
                XCTAssertNotNil(result.1, "B must not succeed with A's data")
                XCTAssertNil(result.0)
            }
        }
        wait(for: [retryTimedOut], timeout: 2)
        fixture.central.dispatchQueue.sync
        {
            XCTAssertEqual(retryResults.count, 1)
            XCTAssertNotNil(retryResults.first?.1)
            observing = false
        }
    }

    func test_queuedTimeoutDoesNotConsumeRetryAfterNativeSuccess()
    {
        let fixture = connectedFixture()
        defer { disconnect(fixture) }
        var firstResults: [Error?] = []
        var retryResults: [Error?] = []
        fixture.peripheral.readValue(for: fixture.characteristic, timeout: 60)
        { _, error in firstResults.append(error) }
        fixture.central.dispatchQueue.sync
        {
            // Capture A's actual timeout closure before its native response cancels it.
            guard let timeout = fixture.peripheral.takeTimeout() else
            {
                XCTFail("A must own a timeout")
                return
            }
            // Queue order after this block: native A success, B setup, synthetic A timeout.
            fixture.central.dispatchQueue.async { fixture.backend.responses.removeFirst()(nil) }
            fixture.peripheral.readValue(for: fixture.characteristic, timeout: 60)
            { _, error in retryResults.append(error) }
            timeout()
        }
        fixture.central.dispatchQueue.sync
        {
            XCTAssertEqual(firstResults.count, 1)
            XCTAssertNil(firstResults.first ?? nil)
            XCTAssertTrue(retryResults.isEmpty, "A's queued timeout must not time out B")
            XCTAssertEqual(fixture.backend.responses.count, 1)
            fixture.backend.deliverResponses()
            XCTAssertEqual(retryResults.count, 1)
            XCTAssertNil(retryResults.first ?? nil, "B must receive its own successful response")
        }
    }

    func test_lateResponseWithoutRetryDoesNotCompleteTwice()
    {
        let fixture = connectedFixture()
        defer { disconnect(fixture) }
        let timedOut = expectation(description: "A timeout")
        var count = 0
        fixture.peripheral.readValue(for: fixture.characteristic, timeout: 0.05)
        { _, error in
            XCTAssertEqual(error?.uuBluetoothErrorCode, .timeout)
            count += 1
            timedOut.fulfill()
        }
        wait(for: [timedOut], timeout: 2)
        fixture.central.dispatchQueue.sync
        {
            fixture.backend.deliverResponses()
            XCTAssertEqual(count, 1)
        }
    }

    func test_successfulReadCanBeFollowedByAnotherRead()
    {
        let fixture = connectedFixture()
        defer { disconnect(fixture) }
        var values: [Data?] = []
        for value: UInt8 in [0xAA, 0xBB]
        {
            fixture.peripheral.readValue(for: fixture.characteristic, timeout: 60)
            { data, error in XCTAssertNil(error); values.append(data) }
            fixture.central.dispatchQueue.sync
            {
                fixture.characteristic.value = Data([value])
                fixture.backend.deliverResponses()
            }
        }
        fixture.central.dispatchQueue.sync { XCTAssertEqual(values, [Data([0xAA]), Data([0xBB])]) }
    }

    private func connectedFixture() -> Fixture
    {
        let fixture = Fixture()
        let connected = expectation(description: "Connected")
        fixture.connect(connected: { connected.fulfill() }, disconnected: { _ in })
        wait(for: [connected], timeout: 2)
        return fixture
    }

    private func disconnect(_ fixture: Fixture)
    {
        fixture.central.dispatchQueue.sync
        {
            fixture.backend.mockSetState(.disconnected)
            fixture.central.notifyDisconnect(fixture.backend.identifier, nil)
            fixture.backend.deliverResponses()
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
        let backend: LateResponsePeripheral
        let central: UUCentralManager
        let mockCentral: UUMockCBCentralManager
        let peripheral: CapturedTimeoutPeripheral

        init()
        {
            characteristic.descriptors = [descriptor]
            service.characteristics = [characteristic]
            // Match the existing mocks' GATT back-pointer setup.
            characteristic.setValue(service, forKey: "service")
            descriptor.setValue(characteristic, forKey: "characteristic")
            backend = LateResponsePeripheral(services: [service])
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
            peripheral = CapturedTimeoutPeripheral(centralManager: central, peripheral: backend,
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

final class LateResponsePeripheral: UUMockCBPeripheral
{
    var responses: [(Error?) -> Void] = []

    func deliverResponses()
    {
        let pending = responses
        responses.removeAll()
        pending.forEach { $0(nil) }
    }

    override func discoverServices(_ serviceUUIDs: [CBUUID]?)
    {
        responses.append { error in self.delegate?.peripheral?(self.backingPeripheral, didDiscoverServices: error) }
    }

    override func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, for service: CBService)
    {
        responses.append { error in self.delegate?.peripheral?(self.backingPeripheral, didDiscoverIncludedServicesFor: service, error: error) }
    }

    override func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBService)
    {
        responses.append { error in self.delegate?.peripheral?(self.backingPeripheral, didDiscoverCharacteristicsFor: service, error: error) }
    }

    override func discoverDescriptors(for characteristic: CBCharacteristic)
    {
        responses.append { error in self.delegate?.peripheral?(self.backingPeripheral, didDiscoverDescriptorsFor: characteristic, error: error) }
    }

    override func readValue(for characteristic: CBCharacteristic)
    {
        responses.append { error in self.delegate?.peripheral?(self.backingPeripheral, didUpdateValueFor: characteristic, error: error) }
    }

    override func readValue(for descriptor: CBDescriptor)
    {
        responses.append { error in self.delegate?.peripheral?(self.backingPeripheral, didUpdateValueFor: descriptor, error: error) }
    }

    override func writeValue(_ data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType)
    {
        responses.append { error in self.delegate?.peripheral?(self.backingPeripheral, didWriteValueFor: characteristic, error: error) }
    }

    override func writeValue(_ data: Data, for descriptor: CBDescriptor)
    {
        responses.append { error in self.delegate?.peripheral?(self.backingPeripheral, didWriteValueFor: descriptor, error: error) }
    }

    override func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristic)
    {
        responses.append { error in self.delegate?.peripheral?(self.backingPeripheral, didUpdateNotificationStateFor: characteristic, error: error) }
    }

    override func readRSSI()
    {
        responses.append { error in self.delegate?.peripheral?(self.backingPeripheral, didReadRSSI: -50, error: error) }
    }

    override func openL2CAPChannel(_ PSM: CBL2CAPPSM)
    {
        responses.append { error in self.delegate?.peripheral?(self.backingPeripheral, didOpen: nil, error: error) }
    }
}

/// Test-only access to the real scheduled timeout closure, for a deterministic queue interleaving.
/// Normal tests still use real timers; no production scheduling code is replaced.
private final class CapturedTimeoutPeripheral: UUPeripheral
{
    private var timeouts: [String: () -> Void] = [:]

    override func startTimer(name: String, timeout: TimeInterval, block: @escaping () -> Void)
    {
        timeouts[name] = block
        super.startTimer(name: name, timeout: timeout, block: block)
    }

    override func cancelTimer(name: String)
    {
        timeouts.removeValue(forKey: name)
        super.cancelTimer(name: name)
    }

    func takeTimeout() -> (() -> Void)?
    {
        guard timeouts.count == 1, let entry = timeouts.first else { return nil }
        cancelTimer(name: entry.key)
        return entry.value
    }
}
