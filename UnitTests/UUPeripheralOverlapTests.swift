import XCTest
import CoreBluetooth
@testable import UUSwiftBluetooth

/// Review #4: every overlapping request must complete or be explicitly rejected.
/// These regressions intentionally remain failing until operation ownership is fixed.
final class UUPeripheralOverlapTests: XCTestCase
{
    private enum Operation
    {
        case services, includedServices, characteristics, descriptors
        case notifyState, rssi, channelOpen
    }

    func test_overlappingServiceDiscoveryCompleteBothCallers()
    {
        assertBothComplete(.services)
    }

    func test_overlappingIncludedServiceDiscoveryCompleteBothCallers()
    {
        assertBothComplete(.includedServices)
    }

    func test_overlappingCharacteristicDiscoveryCompleteBothCallers()
    {
        assertBothComplete(.characteristics)
    }

    func test_overlappingDescriptorDiscoveryCompleteBothCallers()
    {
        assertBothComplete(.descriptors)
    }

    func test_overlappingNotifyStateChangesCompleteBothCallers()
    {
        assertBothComplete(.notifyState)
    }

    func test_overlappingRSSIReadsCompleteBothCallers()
    {
        assertBothComplete(.rssi)
    }

    func test_overlappingChannelOpensCompleteBothCallers()
    {
        assertBothComplete(.channelOpen)
    }

    private func assertBothComplete(_ operation: Operation,
                                    file: StaticString = #filePath, line: UInt = #line)
    {
        let fixture = connectedFixture()
        var counts = [0, 0]
        fixture.central.dispatchQueue.sync
        {
            for index in 0..<2
            {
                self.start(operation, fixture: fixture, timeout: 60)
                { _ in counts[index] += 1 }
            }
            // Drain also supports a future implementation that serializes requests:
            // releasing the first response may submit the queued second request.
            while !fixture.backend.responses.isEmpty { fixture.backend.deliverResponses() }
            XCTAssertEqual(counts, [1, 1], "Every caller needs a result or explicit rejection", file: file, line: line)
        }
        disconnect(fixture)
    }

    func test_secondReadDoesNotReplaceFirstReadsTimeout()
    {
        assertReadTimeoutSurvivesOverlap(completeFirst: false)
    }

    func test_firstReadCompletionDoesNotCancelSecondReadsTimeout()
    {
        assertReadTimeoutSurvivesOverlap(completeFirst: true)
    }

    private func assertReadTimeoutSurvivesOverlap(completeFirst: Bool,
                                                file: StaticString = #filePath, line: UInt = #line)
    {
        let fixture = connectedFixture()
        let timedOut = expectation(description: "Pending read keeps its own deadline")
        var observing = true
        var counts = [0, 0]
        fixture.central.dispatchQueue.sync
        {
            fixture.peripheral.readValue(for: fixture.characteristic, timeout: 0.05)
            { _, error in
                counts[0] += 1
                guard observing else { return }
                if completeFirst { XCTAssertNil(error, file: file, line: line) }
                else
                {
                    XCTAssertEqual(error?.uuBluetoothErrorCode, .timeout, file: file, line: line)
                    timedOut.fulfill()
                }
            }
            fixture.peripheral.readValue(for: fixture.otherCharacteristic, timeout: completeFirst ? 0.05 : 60)
            { _, error in
                counts[1] += 1
                guard observing, completeFirst else { return }
                XCTAssertNotNil(error, "A missing native response must terminate with an error", file: file, line: line)
                timedOut.fulfill()
            }
            if completeFirst { fixture.backend.responses.removeFirst()() }
        }
        // The short interval is the API deadline under test, not a scheduling sleep.
        wait(for: [timedOut], timeout: 2)
        fixture.central.dispatchQueue.sync
        {
            XCTAssertEqual(counts[completeFirst ? 1 : 0], 1, file: file, line: line)
            observing = false
        }
        disconnect(fixture)
    }

    func test_CharacteristicWriteStartPreservesOtherTimeout()
    {
        assertAttributeTimeouts(kind: .characteristicWrite, completeFirst: false)
    }

    func test_CharacteristicWriteCompletionPreservesOtherTimeout()
    {
        assertAttributeTimeouts(kind: .characteristicWrite, completeFirst: true)
    }

    func test_DescriptorReadStartPreservesOtherTimeout()
    {
        assertAttributeTimeouts(kind: .descriptorRead, completeFirst: false)
    }

    func test_DescriptorReadCompletionPreservesOtherTimeout()
    {
        assertAttributeTimeouts(kind: .descriptorRead, completeFirst: true)
    }

    func test_DescriptorWriteStartPreservesOtherTimeout()
    {
        assertAttributeTimeouts(kind: .descriptorWrite, completeFirst: false)
    }

    func test_DescriptorWriteCompletionPreservesOtherTimeout()
    {
        assertAttributeTimeouts(kind: .descriptorWrite, completeFirst: true)
    }

    private enum AttributeOperation
    {
        case characteristicWrite, descriptorRead, descriptorWrite
    }

    private func assertAttributeTimeouts(kind: AttributeOperation, completeFirst: Bool)
    {
        let fixture = connectedFixture()
        let timedOut = expectation(description: "Independent attribute timeout")
        var observing = true
        fixture.central.dispatchQueue.sync
        {
            let descriptors = [
                CBMutableDescriptor(type: CBUUID(string: "2901"), value: "First"),
                CBMutableDescriptor(type: CBUUID(string: "2904"), value: Data([0]))]
            fixture.characteristic.descriptors = descriptors
            descriptors.forEach { $0.setValue(fixture.characteristic, forKey: "characteristic") }
            for index in 0..<2
            {
                let timeout: TimeInterval = index == 0 || completeFirst ? 0.05 : 60
                let completion: (Error?) -> Void = { error in
                    guard observing else { return }
                    if index == (completeFirst ? 1 : 0)
                    {
                        XCTAssertEqual(error?.uuBluetoothErrorCode, .timeout)
                        timedOut.fulfill()
                    }
                    else if completeFirst { XCTAssertNil(error) }
                }
                switch kind
                {
                case .characteristicWrite:
                    fixture.peripheral.writeValue(data: Data([1]),
                        for: index == 0 ? fixture.characteristic : fixture.otherCharacteristic,
                        timeout: timeout, completion: completion)
                case .descriptorRead:
                    fixture.peripheral.readValue(for: descriptors[index], timeout: timeout)
                    { _, error in completion(error) }
                case .descriptorWrite:
                    fixture.peripheral.writeValue(data: Data([1]), for: descriptors[index],
                        timeout: timeout, completion: completion)
                }
            }
            XCTAssertEqual(fixture.backend.responses.count, 2)
            if completeFirst { fixture.backend.responses.removeFirst()() }
        }
        wait(for: [timedOut], timeout: 2)
        fixture.central.dispatchQueue.sync { observing = false }
        disconnect(fixture)
    }

    func test_isolatedReadTimesOutWithoutNativeResponse()
    {
        let fixture = connectedFixture()
        let timedOut = expectation(description: "Isolated read times out")
        fixture.central.dispatchQueue.sync
        {
            fixture.peripheral.readValue(for: fixture.characteristic, timeout: 0.05)
            { _, error in
                XCTAssertEqual(error?.uuBluetoothErrorCode, .timeout)
                timedOut.fulfill()
            }
        }
        wait(for: [timedOut], timeout: 2)
        disconnect(fixture)
    }

    func test_overlappingConnectsCompleteBothCallers()
    {
        let fixture = Fixture()
        let completed = expectation(description: "Both connection attempts terminate")
        completed.expectedFulfillmentCount = 2
        completed.assertForOverFulfill = true
        var counts = [0, 0]
        var observing = true
        fixture.central.dispatchQueue.sync
        {
            // Mock callbacks use this same queue, so neither can arrive until
            // both requests have registered their connection callbacks.
            for index in 0..<2
            {
                fixture.peripheral.connect(timeout: 60, connected:
                {
                    counts[index] += 1
                    if observing { completed.fulfill() }
                }, disconnected:
                { error in
                    if observing
                    {
                        XCTAssertNotNil(error)
                        counts[index] += 1
                        completed.fulfill()
                    }
                })
            }
        }
        wait(for: [completed], timeout: 2)
        fixture.central.dispatchQueue.sync
        {
            XCTAssertEqual(counts, [1, 1])
            observing = false
        }
        disconnect(fixture)
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
            // Synchronous teardown cancels outstanding deadlines and drains handlers.
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
        let otherCharacteristic = CBMutableCharacteristic(type: CBUUID(string: "2A24"),
            properties: [.read, .write], value: nil, permissions: [.readable, .writeable])
        let backend: HeldResponsePeripheral
        let central: UUCentralManager
        let mockCentral: UUMockCBCentralManager
        let peripheral: UUPeripheral

        init()
        {
            characteristic.descriptors = [CBMutableDescriptor(type: CBUUID(string: "2901"), value: "Test")]
            service.characteristics = [characteristic, otherCharacteristic]
            otherCharacteristic.setValue(service, forKey: "service")
            // Match the existing mocks' GATT back-pointer setup.
            characteristic.setValue(service, forKey: "service")
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
