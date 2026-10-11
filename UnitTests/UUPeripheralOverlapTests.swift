import XCTest
import CoreBluetooth
@testable import UUSwiftBluetooth

/// Review #4: every overlapping request must complete or be explicitly rejected.
/// Distinct targets proceed independently; conflicting requests preserve their owner.
final class UUPeripheralOverlapTests: XCTestCase
{
    private enum Operation: CaseIterable
    {
        case services, includedServices, characteristics, descriptors
        case notifyState, rssi, channelOpen
        case characteristicRead, characteristicWrite, descriptorRead, descriptorWrite
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

    func test_overlappingCharacteristicReadRejectsDuplicate()
    {
        assertBothComplete(.characteristicRead)
    }

    func test_overlappingCharacteristicWriteRejectsDuplicate()
    {
        assertBothComplete(.characteristicWrite)
    }

    func test_overlappingDescriptorReadRejectsDuplicate()
    {
        assertBothComplete(.descriptorRead)
    }

    func test_overlappingDescriptorWriteRejectsDuplicate()
    {
        assertBothComplete(.descriptorWrite)
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
                { error in
                    counts[index] += 1
                    if index == 0 { XCTAssertNil(error, file: file, line: line) }
                    else { XCTAssertEqual(error?.uuBluetoothErrorCode, .operationInProgress, file: file, line: line) }
                }
            }
        }
        fixture.central.dispatchQueue.sync
        {
            XCTAssertEqual(counts, [0, 1], file: file, line: line)
            XCTAssertEqual(fixture.backend.responses.count, 1, file: file, line: line)
            // Only the original request reaches the backend.
            while !fixture.backend.responses.isEmpty { fixture.backend.deliverResponses() }
            XCTAssertEqual(counts, [1, 1], "Every caller needs a result or explicit rejection", file: file, line: line)
            self.start(operation, fixture: fixture, timeout: 60)
            { error in
                XCTAssertNil(error, file: file, line: line)
                counts[0] += 1
            }
        }
        fixture.central.dispatchQueue.sync
        {
            fixture.backend.deliverResponses()
            XCTAssertEqual(counts, [2, 1], "Completed keys must be reusable", file: file, line: line)
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
        }
        fixture.central.dispatchQueue.sync
        {
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
        }
        fixture.central.dispatchQueue.sync
        {
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
                        XCTAssertEqual(error?.uuBluetoothErrorCode, .operationInProgress)
                        XCTAssertEqual(index, 1)
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

    func test_distinctCharacteristicsCompleteIndependently()
    {
        assertDistinctTargets(.characteristics, disconnectPending: false)
    }

    func test_distinctCharacteristicsDrainOnDisconnect()
    {
        assertDistinctTargets(.characteristics, disconnectPending: true)
    }

    func test_distinctIncludedServicesCompleteIndependently()
    {
        assertDistinctTargets(.includedServices, disconnectPending: false)
    }

    func test_distinctIncludedServicesDrainOnDisconnect()
    {
        assertDistinctTargets(.includedServices, disconnectPending: true)
    }

    func test_distinctDescriptorsCompleteIndependently()
    {
        assertDistinctTargets(.descriptors, disconnectPending: false)
    }

    func test_distinctDescriptorsDrainOnDisconnect()
    {
        assertDistinctTargets(.descriptors, disconnectPending: true)
    }

    func test_distinctNotifyStateCompleteIndependently()
    {
        assertDistinctTargets(.notifyState, disconnectPending: false)
    }

    func test_distinctNotifyStateDrainOnDisconnect()
    {
        assertDistinctTargets(.notifyState, disconnectPending: true)
    }

    private func assertDistinctTargets(_ operation: Operation, disconnectPending: Bool)
    {
        let fixture = connectedFixture()
        var counts = [0, 0]
        fixture.central.dispatchQueue.sync
        {
            for index in 0..<2
            {
                let service = index == 0 ? fixture.service : fixture.otherService
                let characteristic = index == 0 ? fixture.characteristic : fixture.otherCharacteristic
                let completion: (Error?) -> Void = { error in
                    counts[index] += 1
                    if disconnectPending { XCTAssertEqual(error?.uuBluetoothErrorCode, .disconnected) }
                    else { XCTAssertNil(error) }
                }
                switch operation
                {
                case .characteristics:
                    fixture.peripheral.discoverCharacteristics(characteristicUUIDs: nil, for: service, timeout: 60)
                    { values, error in
                        if !disconnectPending { XCTAssertEqual(values?.first?.uuid, service.characteristics?.first?.uuid) }
                        completion(error)
                    }
                case .includedServices:
                    fixture.peripheral.discoverIncludedServices(includedServiceUUIDs: nil, for: service, timeout: 60)
                    { values, error in
                        if !disconnectPending { XCTAssertEqual(values?.first?.uuid, service.includedServices?.first?.uuid) }
                        completion(error)
                    }
                case .descriptors:
                    fixture.peripheral.discoverDescriptors(for: characteristic, timeout: 60)
                    { values, error in
                        if !disconnectPending { XCTAssertEqual(values?.first?.uuid, characteristic.descriptors?.first?.uuid) }
                        completion(error)
                    }
                case .notifyState:
                    fixture.peripheral.setNotifyValue(enabled: true, for: characteristic, timeout: 60,
                        notifyHandler: nil, completion: completion)
                default: XCTFail("Unsupported test operation")
                }
            }
        }
        fixture.central.dispatchQueue.sync
        {
            XCTAssertEqual(fixture.backend.responses.count, 2)
            if !disconnectPending
            {
                fixture.backend.responses.removeLast()()
                XCTAssertEqual(counts, [0, 1], "The response must reach its own target")
                fixture.backend.deliverResponses()
                XCTAssertEqual(counts, [1, 1])
            }
        }
        disconnect(fixture)
        fixture.central.dispatchQueue.sync { XCTAssertEqual(counts, [1, 1]) }
    }

    func test_duplicateNotifyChangePreservesOriginalSubscription()
    {
        let fixture = connectedFixture()
        var notifications = 0
        fixture.central.dispatchQueue.sync
        {
            fixture.peripheral.setNotifyValue(enabled: true, for: fixture.characteristic, notifyHandler:
                { _, _ in notifications += 1 }, completion: { XCTAssertNil($0) })
            fixture.peripheral.setNotifyValue(enabled: false, for: fixture.characteristic, notifyHandler: nil,
                completion: { XCTAssertEqual($0?.uuBluetoothErrorCode, .operationInProgress) })
        }
        fixture.central.dispatchQueue.sync
        {
            fixture.backend.deliverResponses()
            fixture.backend.delegate?.peripheral?(fixture.backend.backingPeripheral,
                didUpdateValueFor: fixture.characteristic, error: nil)
            XCTAssertEqual(notifications, 1)
        }
        disconnect(fixture)
    }

    func test_connectWhileConnectedPreservesOriginalDisconnectCallback()
    {
        let fixture = Fixture()
        let connected = expectation(description: "Original connection")
        let disconnected = expectation(description: "Original owner disconnected")
        fixture.connect(connected: { connected.fulfill() }, disconnected:
            { error in XCTAssertNil(error); disconnected.fulfill() })
        wait(for: [connected], timeout: 2)
        fixture.peripheral.connect(connected: { XCTFail("Duplicate connect succeeded") }, disconnected:
            { XCTAssertEqual($0?.uuBluetoothErrorCode, .operationInProgress) })
        disconnect(fixture)
        wait(for: [disconnected], timeout: 2)
    }

    func test_readCompletionCanImmediatelyStartSameRead()
    {
        let fixture = connectedFixture()
        var completions = 0
        fixture.peripheral.readValue(for: fixture.characteristic, timeout: 60)
        { _, error in
            XCTAssertNil(error)
            completions += 1
            fixture.peripheral.readValue(for: fixture.characteristic, timeout: 60)
            { _, error in XCTAssertNil(error); completions += 1 }
        }
        fixture.central.dispatchQueue.sync
        {
            fixture.backend.deliverResponses()
        }
        fixture.central.dispatchQueue.sync
        {
            fixture.backend.deliverResponses()
            XCTAssertEqual(completions, 2)
        }
        disconnect(fixture)
    }

    func test_simultaneousCallersReserveReadAtomically()
    {
        let fixture = connectedFixture()
        var accepted = 0
        var rejected = 0
        DispatchQueue.concurrentPerform(iterations: 20)
        { _ in
            fixture.peripheral.readValue(for: fixture.characteristic, timeout: 60)
            { _, error in
                // All completions run on the central queue.
                if let error = error
                {
                    XCTAssertEqual(error.uuBluetoothErrorCode, .operationInProgress)
                    rejected += 1
                }
                else { accepted += 1 }
            }
        }
        fixture.central.dispatchQueue.sync
        {
            XCTAssertEqual(fixture.backend.responses.count, 1)
            XCTAssertEqual(rejected, 19)
            fixture.backend.deliverResponses()
            XCTAssertEqual(accepted, 1)
        }
        disconnect(fixture)
    }

    func test_setupAndBusyRejectionAreDeferredEvenOnCentralQueue()
    {
        let fixture = connectedFixture()
        var completions = 0
        fixture.central.dispatchQueue.sync
        {
            for operation in Operation.allCases
            {
                self.start(operation, fixture: fixture, timeout: 60)
                { error in XCTAssertNil(error); completions += 1 }
                self.start(operation, fixture: fixture, timeout: 60)
                { error in
                    XCTAssertEqual(error?.uuBluetoothErrorCode, .operationInProgress)
                    completions += 1
                }
            }
            XCTAssertTrue(fixture.backend.responses.isEmpty, "Setup must always be queued")
            XCTAssertEqual(completions, 0, "No inline rejection on the central queue")
        }
        fixture.central.dispatchQueue.sync
        {
            XCTAssertEqual(completions, Operation.allCases.count)
            XCTAssertEqual(fixture.backend.responses.count, Operation.allCases.count)
            fixture.backend.deliverResponses()
            XCTAssertEqual(completions, Operation.allCases.count * 2)
        }
        disconnect(fixture)
    }

    func test_callDoesNotWaitForCentralQueue()
    {
        let fixture = connectedFixture()
        let returned = expectation(description: "Call returns while central queue is suspended")
        let caller = DispatchQueue(label: "OverlapTests.caller", qos: .userInteractive)

        // Hold queued work without blocking a high-priority worker on a semaphore.
        // A separate caller keeps XCTest's timeout usable if synchronous dispatch regresses.
        fixture.central.dispatchQueue.suspend()
        do
        {
            defer { fixture.central.dispatchQueue.resume() }
            caller.async
            {
                fixture.peripheral.readValue(for: fixture.characteristic, timeout: 60)
                { _, error in XCTAssertNil(error) }
                returned.fulfill()
            }
            wait(for: [returned], timeout: 2)
        }
        // Join the caller after resuming, including on the test's failure path.
        caller.sync {}
        fixture.central.dispatchQueue.sync
        {
            XCTAssertEqual(fixture.backend.responses.count, 1)
            fixture.backend.deliverResponses()
        }
        disconnect(fixture)
    }

    func test_compositeKeysRouteCharacteristicReadAcrossServices()
    {
        assertCompositeRouting(.characteristicRead)
    }

    func test_compositeKeysRouteCharacteristicWriteAcrossServices()
    {
        assertCompositeRouting(.characteristicWrite)
    }

    func test_compositeKeysRouteDescriptorReadAcrossServices()
    {
        assertCompositeRouting(.descriptorRead)
    }

    func test_compositeKeysRouteDescriptorWriteAcrossServices()
    {
        assertCompositeRouting(.descriptorWrite)
    }

    func test_compositeKeysRouteNotifyStateAcrossServices()
    {
        assertCompositeRouting(.notifyState)
    }

    func test_compositeKeysRouteDescriptorsAcrossServices()
    {
        assertCompositeRouting(.descriptors)
    }

    func test_compositeKeysRouteDescriptorReadWithinService()
    {
        assertCompositeRouting(.descriptorRead, sameService: true)
    }

    func test_compositeKeysRouteDescriptorWriteWithinService()
    {
        assertCompositeRouting(.descriptorWrite, sameService: true)
    }

    func test_compositeKeysPreserveCharacteristicReadTimeout()
    {
        assertCompositeRouting(.characteristicRead, secondTimesOut: true)
    }

    func test_compositeKeysPreserveCharacteristicWriteTimeout()
    {
        assertCompositeRouting(.characteristicWrite, secondTimesOut: true)
    }

    func test_compositeKeysPreserveDescriptorReadTimeout()
    {
        assertCompositeRouting(.descriptorRead, secondTimesOut: true)
    }

    func test_compositeKeysPreserveDescriptorWriteTimeout()
    {
        assertCompositeRouting(.descriptorWrite, secondTimesOut: true)
    }

    private func assertCompositeRouting(_ operation: Operation, sameService: Bool = false,
                                        secondTimesOut: Bool = false)
    {
        let fixture = connectedFixture(duplicateUUIDs: !sameService)
        let completed = expectation(description: "Both paths complete independently")
        completed.expectedFulfillmentCount = 2
        completed.assertForOverFulfill = true
        var counts = [0, 0]
        fixture.central.dispatchQueue.sync
        {
            if sameService
            {
                fixture.otherService.characteristics = []
                fixture.service.characteristics = [fixture.characteristic, fixture.otherCharacteristic]
                fixture.otherCharacteristic.setValue(fixture.service, forKey: "service")
                let descriptor = CBMutableDescriptor(type: CBUUID(string: "2901"), value: "Other")
                descriptor.setValue(fixture.otherCharacteristic, forKey: "characteristic")
                fixture.otherCharacteristic.descriptors = [descriptor]
            }
            for (index, characteristic) in [fixture.characteristic, fixture.otherCharacteristic].enumerated()
            {
                let timeout: TimeInterval = secondTimesOut && index == 1 ? 0.05 : 60
                let completion: (Error?) -> Void = { error in
                    counts[index] += 1
                    if secondTimesOut && index == 1 { XCTAssertEqual(error?.uuBluetoothErrorCode, .timeout) }
                    else { XCTAssertNil(error) }
                    completed.fulfill()
                }
                switch operation
                {
                case .characteristicRead:
                    fixture.peripheral.readValue(for: characteristic, timeout: timeout) { _, error in completion(error) }
                case .characteristicWrite:
                    fixture.peripheral.writeValue(data: Data([1]), for: characteristic, timeout: timeout, completion: completion)
                case .descriptorRead:
                    fixture.peripheral.readValue(for: characteristic.descriptors![0], timeout: timeout)
                    { value, error in
                        if error == nil { XCTAssertEqual(value as? String, index == 0 ? "Test" : "Other") }
                        completion(error)
                    }
                case .descriptorWrite:
                    fixture.peripheral.writeValue(data: Data([1]), for: characteristic.descriptors![0], timeout: timeout, completion: completion)
                case .notifyState:
                    fixture.peripheral.setNotifyValue(enabled: true, for: characteristic, timeout: timeout, notifyHandler: nil, completion: completion)
                case .descriptors:
                    fixture.peripheral.discoverDescriptors(for: characteristic, timeout: timeout)
                    { values, error in
                        XCTAssertEqual(values?.first?.value as? String, characteristic.descriptors?.first?.value as? String)
                        completion(error)
                    }
                default: XCTFail("Unsupported composite-key test")
                }
            }
        }
        fixture.central.dispatchQueue.sync
        {
            XCTAssertEqual(fixture.backend.responses.count, 2)
            guard fixture.backend.responses.count == 2 else { return }
            if secondTimesOut
            {
                fixture.backend.responses.removeFirst()()
                XCTAssertEqual(counts, [1, 0])
            }
            else
            {
                fixture.backend.responses.removeLast()()
                XCTAssertEqual(counts, [0, 1], "Response must reach the correct UUID path")
                fixture.backend.deliverResponses()
            }
        }
        wait(for: [completed], timeout: 2)
        fixture.central.dispatchQueue.sync { XCTAssertEqual(counts, [1, 1]) }
        disconnect(fixture)
    }

    func test_compositeKeysKeepNotificationSubscriptionsIndependent()
    {
        let fixture = connectedFixture(duplicateUUIDs: true)
        var notifications = [0, 0]
        for (index, characteristic) in [fixture.characteristic, fixture.otherCharacteristic].enumerated()
        {
            fixture.peripheral.setNotifyValue(enabled: true, for: characteristic,
                notifyHandler: { _, error in XCTAssertNil(error); notifications[index] += 1 },
                completion: { XCTAssertNil($0) })
        }
        fixture.central.dispatchQueue.sync
        {
            fixture.backend.deliverResponses()
            fixture.backend.delegate?.peripheral?(fixture.backend.backingPeripheral,
                didUpdateValueFor: fixture.otherCharacteristic, error: nil)
            XCTAssertEqual(notifications, [0, 1])
        }
        fixture.peripheral.setNotifyValue(enabled: false, for: fixture.characteristic,
            notifyHandler: nil, completion: { XCTAssertNil($0) })
        fixture.central.dispatchQueue.sync
        {
            fixture.backend.deliverResponses()
            for characteristic in [fixture.characteristic, fixture.otherCharacteristic]
            {
                fixture.backend.delegate?.peripheral?(fixture.backend.backingPeripheral,
                    didUpdateValueFor: characteristic, error: nil)
            }
            XCTAssertEqual(notifications, [0, 2], "Disabling one path must preserve the other subscription")
        }
        disconnect(fixture)
    }

    private func connectedFixture(duplicateUUIDs: Bool = false) -> Fixture
    {
        let fixture = Fixture(duplicateUUIDs: duplicateUUIDs)
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
        case .characteristicRead:
            p.readValue(for: fixture.characteristic, timeout: timeout) { _, error in completion(error) }
        case .characteristicWrite:
            p.writeValue(data: Data([1]), for: fixture.characteristic, timeout: timeout, completion: completion)
        case .descriptorRead:
            p.readValue(for: fixture.characteristic.descriptors![0], timeout: timeout) { _, error in completion(error) }
        case .descriptorWrite:
            p.writeValue(data: Data([1]), for: fixture.characteristic.descriptors![0], timeout: timeout, completion: completion)
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
        let otherService = CBMutableService(type: CBUUID(string: "180F"), primary: true)
        let characteristic = CBMutableCharacteristic(type: CBUUID(string: "2A29"),
            properties: [.read, .write, .notify], value: nil, permissions: [.readable, .writeable])
        let otherCharacteristic: CBMutableCharacteristic
        let backend: HeldResponsePeripheral
        let central: UUCentralManager
        let mockCentral: UUMockCBCentralManager
        let peripheral: UUPeripheral

        init(duplicateUUIDs: Bool = false)
        {
            otherCharacteristic = CBMutableCharacteristic(type: CBUUID(string: duplicateUUIDs ? "2A29" : "2A24"),
                properties: [.read, .write, .notify], value: nil, permissions: [.readable, .writeable])
            characteristic.descriptors = [CBMutableDescriptor(type: CBUUID(string: "2901"), value: "Test")]
            characteristic.descriptors![0].setValue(characteristic, forKey: "characteristic")
            service.characteristics = [characteristic]
            otherService.characteristics = [otherCharacteristic]
            service.includedServices = [otherService]
            otherService.includedServices = [CBMutableService(type: CBUUID(string: "1810"), primary: false)]
            otherCharacteristic.descriptors = [CBMutableDescriptor(type: CBUUID(string: duplicateUUIDs ? "2901" : "2904"), value: duplicateUUIDs ? "Other" as Any : Data([0]) as Any)]
            otherCharacteristic.descriptors![0].setValue(otherCharacteristic, forKey: "characteristic")
            otherCharacteristic.setValue(otherService, forKey: "service")
            // Match the existing mocks' GATT back-pointer setup.
            characteristic.setValue(service, forKey: "service")
            backend = HeldResponsePeripheral(services: [service, otherService])
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
