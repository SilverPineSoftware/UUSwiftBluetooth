import XCTest
import CoreBluetooth
@testable import UUSwiftBluetooth

/// Review #7: refreshing scan results must preserve an active peripheral's
/// callbacks, subscriptions, and deadlines. Separate wrappers must also keep
/// their timers isolated when they share a native peripheral identifier.
final class UUPeripheralScanRestartTests: XCTestCase
{
    func test_scanRestartReusesTheSameWrapper() throws
    {
        let fixture = try connectedFixture()
        defer { fixture.cleanup() }
        fixture.central.dispatchQueue.sync
        {
            fixture.advertise(restart: true)
            XCTAssertTrue(fixture.latest === fixture.original)
        }
    }

    func test_centralPowerOffCompletesCachedPeripheralsPendingRead() throws
    {
        let fixture = try connectedFixture()
        defer { fixture.cleanup() }
        var results = 0
        fixture.original.readValue(for: fixture.characteristic, timeout: -1)
        { _, error in
            results += 1
            XCTAssertNotNil(error)
        }
        fixture.central.dispatchQueue.sync
        {
            XCTAssertEqual(fixture.backend.responses.count, 1)
            fixture.centralDelegate.centralStateChangedBlock?(.poweredOff)
            XCTAssertEqual(results, 1, "Power-off must complete a read even without a timer")
            fixture.backend.deliverResponses()
            XCTAssertEqual(results, 1)
        }
    }

    func test_centralAndItsCachedPeripheralsCanBeReleased()
    {
        func createAndReleaseCentral() -> WeakCentralBox
        {
            let backend = HeldResponsePeripheral()
            let native = backend.backingPeripheral
            let delegate = UUCentralManagerDelegate()
            let central = UUCentralManager(options: UUCentralManagerOptions(), injection: { queue, options in
                let mock = UUMockCBCentralManager(delegate: delegate, queue: queue, options: options.coreBluetoothOptions)
                mock.mockPeripherals = [native]
                return (delegate, mock)
            })
            central.dispatchQueue.sync
            {
                central.startScan(config: UUPeripheralScannerConfig(), advertisementHandler: { _ in })
                delegate.didDiscoverPeripheralBlock?(native, [:], NSNumber(value: -50))
                central.stopScan()
            }
            return WeakCentralBox(central)
        }
        let box = createAndReleaseCentral()
        XCTAssertNil(box.value, "The central's peripheral cache must not retain the central")
    }

    func test_repeatedAdvertisementWithoutRestartPreservesPendingRead() throws
    {
        try assertPendingReadSurvives(restart: false)
    }

    func test_scanRestartPreservesPendingRead() throws
    {
        try assertPendingReadSurvives(restart: true)
    }

    private func assertPendingReadSurvives(restart: Bool) throws
    {
        let fixture = try connectedFixture()
        defer { fixture.cleanup() }
        var completions = 0
        var observing = true
        fixture.original.readValue(for: fixture.characteristic, timeout: 60)
        { data, error in
            guard observing else { return }
            completions += 1
            XCTAssertNil(error)
            XCTAssertEqual(data, Data([0x42]))
        }
        fixture.central.dispatchQueue.sync
        {
            XCTAssertEqual(fixture.backend.responses.count, 1)
            fixture.advertise(restart: restart)
            fixture.characteristic.value = Data([0x42])
            fixture.backend.deliverResponses()
            XCTAssertEqual(completions, 1, "Rediscovery must not divert an existing read's native response")
            observing = false
        }
    }

    func test_repeatedAdvertisementWithoutRestartPreservesNotifications() throws
    {
        try assertNotificationsSurvive(restart: false)
    }

    func test_scanRestartPreservesNotifications() throws
    {
        try assertNotificationsSurvive(restart: true)
    }

    private func assertNotificationsSurvive(restart: Bool) throws
    {
        let fixture = try connectedFixture()
        defer { fixture.cleanup() }
        var values: [Data] = []
        var subscribed = false
        fixture.original.setNotifyValue(enabled: true, for: fixture.characteristic, timeout: 60,
            notifyHandler: { data, error in
                XCTAssertNil(error)
                if let data { values.append(data) }
            }, completion: { error in
                XCTAssertNil(error)
                subscribed = true
            })
        fixture.central.dispatchQueue.sync
        {
            fixture.backend.deliverResponses()
            XCTAssertTrue(subscribed)
            fixture.notify(Data([1]))
            XCTAssertEqual(values, [Data([1])], "Subscription must work before rediscovery")
            fixture.advertise(restart: restart)
            fixture.notify(Data([2]))
            XCTAssertEqual(values, [Data([1]), Data([2])], "The original subscription must survive rediscovery")
        }
    }

    func test_separateWrapperCannotReplaceOriginalWrappersTimer() throws
    {
        let fixture = try connectedFixture()
        defer { fixture.cleanup() }
        let deadline = expectation(description: "Original wrapper retains its deadline")
        fixture.central.dispatchQueue.sync
        {
            fixture.original.startTimer(name: "pending", timeout: 0.05) { deadline.fulfill() }
            fixture.makeSeparateWrapper()
            fixture.latest.startTimer(name: "pending", timeout: 60) {}
        }
        wait(for: [deadline], timeout: 1)
    }

    func test_separateWrapperCannotCancelOriginalWrappersTimer() throws
    {
        let fixture = try connectedFixture()
        defer { fixture.cleanup() }
        let deadline = expectation(description: "Canceling another wrapper's timer preserves the original deadline")
        fixture.central.dispatchQueue.sync
        {
            fixture.original.startTimer(name: "pending", timeout: 0.05) { deadline.fulfill() }
            fixture.makeSeparateWrapper()
            fixture.latest.cancelTimer(name: "pending")
        }
        wait(for: [deadline], timeout: 1)
    }

    func test_separateWrapperDisconnectCannotCancelOriginalWrappersTimer() throws
    {
        let fixture = try connectedFixture()
        defer { fixture.cleanup() }
        let deadline = expectation(description: "Original wrapper retains its deadline after other wrapper disconnects")
        fixture.central.dispatchQueue.sync
        {
            fixture.original.startTimer(name: "pending", timeout: 0.05) { deadline.fulfill() }
            fixture.makeSeparateWrapper()
            fixture.latest.connectionEnded(nil)
        }
        wait(for: [deadline], timeout: 1)
    }

    private func connectedFixture() throws -> Fixture
    {
        let fixture = Fixture()
        try fixture.central.dispatchQueue.sync
        {
            fixture.scanner.start()
            fixture.advertise(restart: false)
            fixture.original = try XCTUnwrap(fixture.scanner.getPeripheral(identifier: fixture.backend.identifier))
        }
        let connected = expectation(description: "Original wrapper connects")
        fixture.central.connect(fixture.original, connected: { connected.fulfill() }, disconnected: { _ in })
        wait(for: [connected], timeout: 2)
        return fixture
    }

    private final class Fixture
    {
        let characteristic = CBMutableCharacteristic(type: CBUUID(string: "2A29"),
            properties: [.read, .notify], value: nil, permissions: [.readable])
        let backend: HeldResponsePeripheral
        let central: UUCentralManager
        let centralDelegate: UUCentralManagerDelegate
        let scanner: UUCoreBluetoothPeripheralScanner
        var original: UUPeripheral!
        var latest: UUPeripheral!

        init()
        {
            let service = CBMutableService(type: CBUUID(string: "180A"), primary: true)
            service.characteristics = [characteristic]
            characteristic.setValue(service, forKey: "service")
            backend = HeldResponsePeripheral(services: [service])
            let native = backend.backingPeripheral
            let delegate = UUCentralManagerDelegate()
            centralDelegate = delegate
            central = UUCentralManager(options: UUCentralManagerOptions(), injection: { queue, options in
                let mock = UUMockCBCentralManager(delegate: delegate, queue: queue, options: options.coreBluetoothOptions)
                mock.mockPeripherals = [native]
                mock.mockDispatchQueue = queue
                mock.mockCallbackTime = 0
                return (delegate, mock)
            })
            scanner = UUCoreBluetoothPeripheralScanner(centralManager: central)
            scanner.config = UUPeripheralScannerConfig(callbackThrottle: 0)
        }

        // Run on the central queue. Deliver an advertisement through the central
        // delegate's normal scanner callback, using the real scanner cache path.
        func advertise(restart: Bool)
        {
            if restart
            {
                scanner.stop()
                scanner.start()
            }
            centralDelegate.didDiscoverPeripheralBlock?(backend.backingPeripheral, [:], NSNumber(value: -50))
            latest = scanner.getPeripheral(identifier: backend.identifier)
            // The scanner retrieves the mock's native CBPeripheral. Replace only
            // its operation transport with our held-response backend for testing.
            // Both reference the SAME native peripheral and delegate; this does
            // not reassign or restore the delegate installed by the scanner.
            latest?.underlyingPeripheral = backend
        }

        // Isolate the timer-ownership defect from scanner caching. A future
        // canonical scanner wrapper must not make this regression vacuous.
        func makeSeparateWrapper()
        {
            latest = UUPeripheral(dispatchQueue: central.dispatchQueue, centralState: central.centralState, peripheral: backend,
                                  advertisement: UUAdvertisement(identifier: backend.identifier))
        }

        func notify(_ value: Data)
        {
            characteristic.value = value
            backend.delegate?.peripheral?(backend.backingPeripheral,
                                          didUpdateValueFor: characteristic, error: nil)
        }

        func cleanup()
        {
            central.dispatchQueue.sync
            {
                scanner.stop()
                original.cancelTimer(name: "pending")
                latest.cancelTimer(name: "pending")
                // Drain the original owner's pending operations without waiting
                // for the long fallback deadlines used in native-response tests.
                central.notifyDisconnect(backend.identifier, nil)
                backend.responses.removeAll()
            }
        }
    }

    private final class WeakCentralBox
    {
        weak var value: UUCentralManager?

        init(_ central: UUCentralManager)
        {
            value = central
        }
    }
}
