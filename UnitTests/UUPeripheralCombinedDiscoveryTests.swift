import XCTest
import CoreBluetooth
@testable import UUSwiftBluetooth

/// Regression coverage for review finding #9.
final class UUPeripheralCombinedDiscoveryTests: XCTestCase
{
    func test_serviceFailurePreservesErrorAndDisconnectsOnce()
    {
        let fixture = Fixture()
        let discoveryError = TestError.service
        fixture.start()
        fixture.deliverServices(error: discoveryError)
        fixture.flush()

        XCTAssertEqual(fixture.cancelCount, 1)
        XCTAssertTrue(fixture.results.isEmpty, "Completion should wait for teardown")
        fixture.finishDisconnect()
        XCTAssertEqual(fixture.results.count, 1)
        assertError(fixture.results.first.flatMap { $0 }, matches: discoveryError)
    }

    func test_characteristicFailureSurvivesCleanDisconnect()
    {
        let fixture = Fixture()
        fixture.start()
        fixture.deliverServices(services: [fixture.service])
        fixture.flush()
        fixture.deliverCharacteristics(error: TestError.characteristic)
        fixture.flush()

        XCTAssertEqual(fixture.cancelCount, 1)
        fixture.finishDisconnect()
        XCTAssertEqual(fixture.results.count, 1)
        assertError(fixture.results.first.flatMap { $0 }, matches: TestError.characteristic)
    }

    func test_missingServiceListStillDisconnectsAndCompletesOnce()
    {
        let fixture = Fixture()
        fixture.start()
        fixture.deliverServices(services: nil)
        fixture.flush()

        XCTAssertEqual(fixture.cancelCount, 1)
        fixture.finishDisconnect()
        XCTAssertEqual(fixture.results.count, 1)
        XCTAssertNil(fixture.results.first!)
    }

    func test_discoveryErrorTakesPrecedenceOverDisconnectError()
    {
        let fixture = Fixture()
        fixture.start()
        fixture.deliverServices(services: [fixture.service])
        fixture.flush()
        fixture.deliverCharacteristics(error: TestError.characteristic)
        fixture.flush()
        fixture.finishDisconnect(error: TestError.disconnect)

        XCTAssertEqual(fixture.results.count, 1)
        assertError(fixture.results.first.flatMap { $0 }, matches: TestError.characteristic)
    }

    func test_successfulDiscoveryCompletesAfterDisconnect()
    {
        let fixture = Fixture()
        fixture.start()
        fixture.deliverServices(services: [fixture.service])
        fixture.flush()
        fixture.deliverCharacteristics(error: nil)
        fixture.flush()

        XCTAssertEqual(fixture.cancelCount, 1)
        XCTAssertTrue(fixture.results.isEmpty)
        fixture.finishDisconnect()
        XCTAssertEqual(fixture.results.count, 1)
        XCTAssertNil(fixture.results.first!)
    }

    func test_serviceDiscoveryUsesSuppliedTimeoutAndTearsDown()
    {
        let fixture = Fixture()
        let cancellation = expectation(description: "Discovery timeout requested teardown")
        fixture.onCancel = { cancellation.fulfill() }
        fixture.start(timeout: 0.05)

        wait(for: [cancellation], timeout: 2)
        XCTAssertEqual(fixture.cancelCount, 1)
        fixture.finishDisconnect()
        XCTAssertEqual(fixture.results.count, 1)
        XCTAssertEqual(fixture.results.first.flatMap { $0 }?.uuBluetoothErrorCode, .timeout)
    }

    private func assertError(_ actual: Error?, matches expected: NSError,
                             file: StaticString = #filePath, line: UInt = #line)
    {
        let error = actual as NSError?
        XCTAssertEqual(error?.uuBluetoothErrorCode, .operationFailed, file: file, line: line)
        let underlying = error?.userInfo[NSUnderlyingErrorKey] as? NSError
        XCTAssertEqual(underlying?.domain, expected.domain, file: file, line: line)
        XCTAssertEqual(underlying?.code, expected.code, file: file, line: line)
    }

    private enum TestError
    {
        static let service = NSError(domain: "CombinedDiscoveryTests", code: 1)
        static let characteristic = NSError(domain: "CombinedDiscoveryTests", code: 2)
        static let disconnect = NSError(domain: "CombinedDiscoveryTests", code: 3)
    }

    private final class Fixture
    {
        let service = CBMutableService(type: CBUUID(string: "180A"), primary: true)
        let backend = ControlledPeripheral()
        let delegate = UUCentralManagerDelegate()
        let central: UUCentralManager
        let peripheral: UUPeripheral
        var results: [Error?] = []
        var cancelCount: Int { mockCentral.cancelCount }
        var onCancel: (() -> Void)?
        private let mockCentral: ControlledCentral

        init()
        {
            let native = backend.backingPeripheral
            let centralDelegate = delegate
            var injected: ControlledCentral!
            central = UUCentralManager(options: UUCentralManagerOptions(), injection: { queue, options in
                let mock = ControlledCentral(delegate: centralDelegate, queue: queue, options: options.coreBluetoothOptions)
                mock.mockPeripherals = [native]
                injected = mock
                return (centralDelegate, mock)
            })
            mockCentral = injected
            peripheral = UUPeripheral(dispatchQueue: central.dispatchQueue,
                centralState: central.centralState, peripheral: backend,
                advertisement: UUAdvertisement(identifier: native.identifier))
            mockCentral.onCancel = { [weak self] in self?.onCancel?() }
        }

        func start(timeout: TimeInterval = 60)
        {
            peripheral.discoverAllServicesAndCharacteristics(using: central, timeout: timeout)
            { [self] error in results.append(error) }
            flush()
            central.dispatchQueue.sync
            {
                backend.mockSetState(.connected)
                delegate.connectBlocks[peripheral.identifier]?(backend.backingPeripheral)
            }
            flush()
        }

        func deliverServices(services: [CBMutableService]? = nil, error: Error? = nil)
        {
            central.dispatchQueue.sync
            {
                backend.backingPeripheral.setValue(services, forKey: "services")
                backend.delegate?.peripheral?(backend.backingPeripheral, didDiscoverServices: error)
            }
        }

        func deliverCharacteristics(error: Error?)
        {
            central.dispatchQueue.sync
            {
                backend.delegate?.peripheral?(backend.backingPeripheral,
                    didDiscoverCharacteristicsFor: service, error: error)
            }
        }

        func finishDisconnect(error: Error? = nil)
        {
            central.dispatchQueue.sync
            {
                backend.mockSetState(.disconnected)
                central.notifyDisconnect(peripheral.identifier, error)
            }
            flush()
        }

        func flush() { central.dispatchQueue.sync {} }
    }

    private final class ControlledPeripheral: UUMockCBPeripheral
    {
        override func discoverServices(_ serviceUUIDs: [CBUUID]?) {}
        override func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBService) {}
    }

    private final class ControlledCentral: UUMockCBCentralManager
    {
        var cancelCount = 0
        var onCancel: (() -> Void)?
        override func connect(_ peripheral: CBPeripheral, options: [String: Any]?) {}
        override func cancelPeripheralConnection(_ peripheral: CBPeripheral)
        {
            cancelCount += 1
            onCancel?()
        }
    }
}
