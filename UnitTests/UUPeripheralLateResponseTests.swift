import XCTest
import CoreBluetooth
@testable import UUSwiftBluetooth

/// Review #5: native responses may satisfy the current matching request, but
/// local timeout work must only complete the request that scheduled it.
final class UUPeripheralLateResponseTests: XCTestCase
{
    private enum Operation
    {
        case services, includedServices, characteristics, descriptors
        case characteristicRead, descriptorRead, characteristicWrite, descriptorWrite
        case notifyState, rssi, channelOpen
    }

    func test_lateServiceDiscoveryResponseCompletesRetryOnce()
    {
        assertLateResponseCompletesRetryOnce(.services)
    }

    func test_lateIncludedServiceDiscoveryResponseCompletesRetryOnce()
    {
        assertLateResponseCompletesRetryOnce(.includedServices)
    }

    func test_lateCharacteristicDiscoveryResponseCompletesRetryOnce()
    {
        assertLateResponseCompletesRetryOnce(.characteristics)
    }

    func test_lateDescriptorDiscoveryResponseCompletesRetryOnce()
    {
        assertLateResponseCompletesRetryOnce(.descriptors)
    }

    func test_lateCharacteristicReadResponseCompletesRetryOnce()
    {
        assertLateResponseCompletesRetryOnce(.characteristicRead)
    }

    func test_lateDescriptorReadResponseCompletesRetryOnce()
    {
        assertLateResponseCompletesRetryOnce(.descriptorRead)
    }

    func test_lateCharacteristicWriteResponseCompletesRetryOnce()
    {
        assertLateResponseCompletesRetryOnce(.characteristicWrite)
    }

    func test_lateDescriptorWriteResponseCompletesRetryOnce()
    {
        assertLateResponseCompletesRetryOnce(.descriptorWrite)
    }

    func test_lateNotifyStateResponseCompletesRetryOnce()
    {
        assertLateResponseCompletesRetryOnce(.notifyState)
    }

    func test_lateRSSIReadResponseCompletesRetryOnce()
    {
        assertLateResponseCompletesRetryOnce(.rssi)
    }

    func test_lateChannelOpenResponseCompletesRetryOnce()
    {
        assertLateResponseCompletesRetryOnce(.channelOpen)
    }

    func test_lateReadErrorCompletesRetryOnce()
    {
        assertLateResponseCompletesRetryOnce(.characteristicRead,
            lateError: NSError(domain: "LateResponseFromRequestA", code: 42))
    }

    private func assertLateResponseCompletesRetryOnce(
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
            XCTAssertEqual(fixture.backend.responses.count, 2, file: file, line: line)
            XCTAssertTrue(retryResults.isEmpty, file: file, line: line)
            guard fixture.backend.responses.count == 2 else { return }
            fixture.backend.responses.removeFirst()(lateError)
            XCTAssertEqual(retryResults.count, 1, "A matching native response satisfies B", file: file, line: line)
            if let expected = lateError as NSError?
            {
                XCTAssertEqual((retryResults.first ?? nil)?.uuBluetoothErrorCode, .operationFailed, file: file, line: line)
                let underlying = ((retryResults.first ?? nil) as NSError?)?.userInfo[NSUnderlyingErrorKey] as? NSError
                XCTAssertEqual(underlying?.domain, expected.domain, file: file, line: line)
                XCTAssertEqual(underlying?.code, expected.code, file: file, line: line)
            }
            else { XCTAssertNil(retryResults.first ?? nil, file: file, line: line) }
            fixture.backend.responses.removeFirst()(nil)
            XCTAssertEqual(retryResults.count, 1, "Later responses must not complete B twice", file: file, line: line)
            XCTAssertEqual(firstCount, 1, file: file, line: line)
        }
    }

    func test_retryWithoutNativeResponseTimesOut()
    {
        let fixture = connectedFixture()
        defer { disconnect(fixture) }
        var counts = [0, 0]
        for index in 0..<2
        {
            let timedOut = expectation(description: "Request \(index) times out")
            fixture.peripheral.readValue(for: fixture.characteristic, timeout: 0.05)
            { _, error in
                counts[index] += 1
                XCTAssertEqual(error?.uuBluetoothErrorCode, .timeout)
                timedOut.fulfill()
            }
            wait(for: [timedOut], timeout: 2)
        }
        fixture.central.dispatchQueue.sync
        {
            fixture.backend.deliverResponses()
            XCTAssertEqual(counts, [1, 1])
        }
    }

    func test_lateReadDataCompletesRetryAndInvalidatesItsTimeout()
    {
        let fixture = connectedFixture()
        defer { disconnect(fixture) }
        let timedOut = expectation(description: "A timeout")
        fixture.peripheral.readValue(for: fixture.characteristic, timeout: 0.05)
        { _, error in
            XCTAssertEqual(error?.uuBluetoothErrorCode, .timeout)
            timedOut.fulfill()
        }
        wait(for: [timedOut], timeout: 2)
        var results: [(Data?, Error?)] = []
        fixture.peripheral.readValue(for: fixture.characteristic, timeout: 60)
        { data, error in results.append((data, error)) }
        fixture.central.dispatchQueue.sync
        {
            guard let timeout = fixture.peripheral.takeTimeout() else { return XCTFail("B needs a timer") }
            fixture.characteristic.value = Data([0xAA])
            fixture.backend.responses.removeFirst()(nil)
            XCTAssertEqual(results.count, 1)
            XCTAssertEqual(results.first?.0, Data([0xAA]))
            XCTAssertNil(results.first?.1)
            timeout()
            fixture.backend.deliverResponses()
        }
        fixture.central.dispatchQueue.sync { XCTAssertEqual(results.count, 1) }
    }

    func test_queuedTimeoutDoesNotConsumeServicesRetry()
    {
        assertQueuedTimeoutDoesNotConsumeRetry(.services)
    }

    func test_queuedTimeoutDoesNotConsumeIncludedServicesRetry()
    {
        assertQueuedTimeoutDoesNotConsumeRetry(.includedServices)
    }

    func test_queuedTimeoutDoesNotConsumeCharacteristicsRetry()
    {
        assertQueuedTimeoutDoesNotConsumeRetry(.characteristics)
    }

    func test_queuedTimeoutDoesNotConsumeDescriptorsRetry()
    {
        assertQueuedTimeoutDoesNotConsumeRetry(.descriptors)
    }

    func test_queuedTimeoutDoesNotConsumeCharacteristicReadRetry()
    {
        assertQueuedTimeoutDoesNotConsumeRetry(.characteristicRead)
    }

    func test_queuedTimeoutDoesNotConsumeDescriptorReadRetry()
    {
        assertQueuedTimeoutDoesNotConsumeRetry(.descriptorRead)
    }

    func test_queuedTimeoutDoesNotConsumeCharacteristicWriteRetry()
    {
        assertQueuedTimeoutDoesNotConsumeRetry(.characteristicWrite)
    }

    func test_queuedTimeoutDoesNotConsumeDescriptorWriteRetry()
    {
        assertQueuedTimeoutDoesNotConsumeRetry(.descriptorWrite)
    }

    func test_queuedTimeoutDoesNotConsumeNotifyStateRetry()
    {
        assertQueuedTimeoutDoesNotConsumeRetry(.notifyState)
    }

    func test_queuedTimeoutDoesNotConsumeRssiRetry()
    {
        assertQueuedTimeoutDoesNotConsumeRetry(.rssi)
    }

    func test_queuedTimeoutDoesNotConsumeChannelOpenRetry()
    {
        assertQueuedTimeoutDoesNotConsumeRetry(.channelOpen)
    }

    private func assertQueuedTimeoutDoesNotConsumeRetry(_ operation: Operation)
    {
        let fixture = connectedFixture()
        defer { disconnect(fixture) }
        var firstResults: [Error?] = []
        var retryResults: [Error?] = []
        start(operation, fixture: fixture, timeout: 60)
        { error in firstResults.append(error) }
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
            self.start(operation, fixture: fixture, timeout: 60)
            { error in retryResults.append(error) }
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

    func test_oldTimeoutDoesNotCancelRetryDeadline()
    {
        let fixture = connectedFixture()
        defer { disconnect(fixture) }
        let retryTimedOut = expectation(description: "B reaches its own deadline")
        var firstCount = 0
        var retryCount = 0
        fixture.peripheral.readValue(for: fixture.characteristic, timeout: 60)
        { _, error in XCTAssertNil(error); firstCount += 1 }
        fixture.central.dispatchQueue.sync
        {
            guard let timeout = fixture.peripheral.takeTimeout() else { return XCTFail("A needs a timer") }
            fixture.central.dispatchQueue.async { fixture.backend.responses.removeFirst()(nil) }
            fixture.peripheral.readValue(for: fixture.characteristic, timeout: 0.05)
            { _, error in
                XCTAssertEqual(error?.uuBluetoothErrorCode, .timeout)
                retryCount += 1
                retryTimedOut.fulfill()
            }
            timeout()
        }
        fixture.central.dispatchQueue.sync
        {
            XCTAssertEqual(firstCount, 1)
            XCTAssertEqual(retryCount, 0, "A's queued timeout must not finish B early")
        }
        wait(for: [retryTimedOut], timeout: 2)
        fixture.central.dispatchQueue.sync
        {
            fixture.backend.deliverResponses()
            XCTAssertEqual(retryCount, 1)
        }
    }

    func test_oldTimeoutIsInvalidAfterDisconnectAndReconnect()
    {
        let fixture = connectedFixture()
        defer { disconnect(fixture) }
        var oldTimeout: (() -> Void)?
        var firstCount = 0
        var retryResults: [Error?] = []
        fixture.peripheral.readValue(for: fixture.characteristic, timeout: 60)
        { _, error in
            XCTAssertEqual(error?.uuBluetoothErrorCode, .disconnected)
            firstCount += 1
        }
        fixture.central.dispatchQueue.sync { oldTimeout = fixture.peripheral.takeTimeout() }
        XCTAssertNotNil(oldTimeout)
        disconnect(fixture)
        let connected = expectation(description: "Reconnected")
        fixture.connect(connected: { connected.fulfill() }, disconnected: { _ in })
        wait(for: [connected], timeout: 2)
        fixture.peripheral.readValue(for: fixture.characteristic, timeout: 60)
        { _, error in retryResults.append(error) }
        fixture.central.dispatchQueue.sync { oldTimeout?() }
        fixture.central.dispatchQueue.sync
        {
            XCTAssertEqual(firstCount, 1)
            XCTAssertTrue(retryResults.isEmpty)
            fixture.backend.deliverResponses()
            XCTAssertEqual(retryResults.count, 1)
            XCTAssertNil(retryResults.first ?? nil)
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
        // Stop only the underlying timer source; preserve the accepted request
        // just as a fired one-shot source would, so its queued work can be interleaved.
        cancelTimer(name: entry.key)
        return entry.value
    }
}
