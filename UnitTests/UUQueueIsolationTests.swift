import XCTest
import CoreBluetooth
@testable import UUSwiftBluetooth

/// Review #8: these tests deliberately overlap public calls with the central's
/// callback queue. Run with Thread Sanitizer to detect unsynchronized accesses;
/// ordinary XCTest assertions alone cannot prove that a data race occurred.
final class UUQueueIsolationTests: XCTestCase
{
    func test_scanStateReadOverlapsStartAndStop()
    {
        let fixture = Fixture()
        let finished = expectation(description: "Scan caller and callback queue finish")
        finished.expectedFulfillmentCount = 2

        DispatchQueue.global(qos: .userInitiated).async
        {
            for _ in 0..<200
            {
                fixture.central.startScan(config: UUPeripheralScannerConfig(), advertisementHandler: { _ in })
                fixture.central.stopScan()
            }
            finished.fulfill()
        }

        fixture.central.dispatchQueue.async
        {
            for _ in 0..<200
            {
                _ = fixture.central.isScanning
                fixture.delegate.centralStateChangedBlock?(.poweredOn)
            }
            finished.fulfill()
        }

        wait(for: [finished], timeout: 5)
        fixture.central.stopScan()
    }

    func test_stateListenerRegistrationOverlapsDelivery()
    {
        let fixture = Fixture()
        let finished = expectation(description: "Listener registration and state delivery finish")
        finished.expectedFulfillmentCount = 2

        DispatchQueue.global(qos: .userInitiated).async
        {
            for index in 0..<100
            {
                fixture.central.registerForStateChanges(identifier: "listener-\(index)", handler: { _ in })
            }
            finished.fulfill()
        }

        fixture.central.dispatchQueue.async
        {
            for _ in 0..<100
            {
                fixture.delegate.centralStateChangedBlock?(.poweredOn)
            }
            finished.fulfill()
        }

        wait(for: [finished], timeout: 5)
    }

    func test_stateListenerCanRegisterAnotherListenerDuringDelivery()
    {
        let fixture = Fixture()
        var secondListenerCalls = 0
        var handlingTestEvent = false
        fixture.central.registerForStateChanges(identifier: "first")
        { _ in
            guard handlingTestEvent else { return }
            fixture.central.registerForStateChanges(identifier: "second")
            { _ in
                if handlingTestEvent { secondListenerCalls += 1 }
            }
        }

        fixture.central.dispatchQueue.sync
        {
            // Ignore CoreBluetooth's asynchronous initial state notification.
            handlingTestEvent = true
            fixture.delegate.centralStateChangedBlock?(.resetting)
            XCTAssertEqual(secondListenerCalls, 0)
            fixture.delegate.centralStateChangedBlock?(.resetting)
            XCTAssertEqual(secondListenerCalls, 1)
            handlingTestEvent = false
        }
    }

    func test_scanUsesConfigurationCapturedAtStart()
    {
        let fixture = Fixture()
        let scanner = UUCoreBluetoothPeripheralScanner(centralManager: fixture.central)
        scanner.config = UUPeripheralScannerConfig(
            discoveryFilters: [RejectAllFilter()], callbackThrottle: 0)

        fixture.central.dispatchQueue.sync
        {
            scanner.start()
            scanner.config = UUPeripheralScannerConfig(callbackThrottle: 0)
            fixture.delegate.didDiscoverPeripheralBlock?(fixture.peripheral.backingPeripheral, [:], NSNumber(value: -50))
            XCTAssertTrue(scanner.peripherals.isEmpty)

            scanner.stop()
            scanner.start()
            fixture.delegate.didDiscoverPeripheralBlock?(fixture.peripheral.backingPeripheral, [:], NSNumber(value: -50))
            XCTAssertEqual(scanner.peripherals.count, 1)
            scanner.stop()
        }
    }

    func test_scannerLookupOverlapsAdvertisementUpdates()
    {
        let fixture = Fixture()
        let scanner = UUCoreBluetoothPeripheralScanner(centralManager: fixture.central)
        scanner.config = UUPeripheralScannerConfig(callbackThrottle: 0)
        scanner.start()
        let finished = expectation(description: "Advertisements and scanner lookups finish")
        finished.expectedFulfillmentCount = 2

        fixture.central.dispatchQueue.async
        {
            for _ in 0..<200
            {
                fixture.delegate.didDiscoverPeripheralBlock?(fixture.peripheral.backingPeripheral, [:], NSNumber(value: -50))
            }
            finished.fulfill()
        }

        DispatchQueue.global(qos: .userInitiated).async
        {
            for _ in 0..<200
            {
                _ = scanner.getPeripheral(identifier: fixture.peripheral.identifier)
                _ = scanner.peripherals
            }
            finished.fulfill()
        }

        wait(for: [finished], timeout: 5)
        scanner.stop()
    }

    private final class Fixture
    {
        let peripheral = UUMockCBPeripheral()
        let delegate = UUCentralManagerDelegate()
        let central: UUCentralManager

        init()
        {
            let peripheral = self.peripheral
            let delegate = self.delegate
            central = UUCentralManager(options: UUCentralManagerOptions(), injection: { queue, options in
                let mock = UUMockCBCentralManager(delegate: delegate, queue: queue, options: options.coreBluetoothOptions)
                mock.mockPeripherals = [peripheral.backingPeripheral]
                return (delegate, mock)
            })
        }
    }

    private struct RejectAllFilter: UUPeripheralFilter
    {
        func shouldDiscover(_ peripheral: UUPeripheral) -> Bool { false }
    }
}
