import XCTest
import CoreBluetooth
@testable import UUSwiftBluetooth

final class UUScannerPowerStateTests: XCTestCase
{
    func test_unknownStartKeepsPendingScanThroughInitialEmptyList()
    {
        let fixture = Fixture(initialState: .unknown)
        let started = expectation(description: "Start accepted")
        fixture.scanner.started = { _ in started.fulfill() }
        fixture.scanner.start()
        wait(for: [started], timeout: 2)
        fixture.flush()

        XCTAssertTrue(fixture.scanner.isScanning)
        XCTAssertEqual(fixture.mock.scanCount, 0)
        XCTAssertEqual(fixture.endCount, 0)

        fixture.changeState(.poweredOn)
        XCTAssertEqual(fixture.mock.scanCount, 1)
        XCTAssertTrue(fixture.scanner.isScanning)
        fixture.scanner.stop()
    }

    func test_quietPowerOffEndsScanOnceAndPreventsAutomaticRestart()
    {
        let fixture = Fixture(initialState: .poweredOn)
        let started = expectation(description: "Start accepted")
        let ended = expectation(description: "Power off ended scan")
        fixture.scanner.started = { _ in started.fulfill() }
        fixture.scanner.ended = { _, error in
            XCTAssertNotNil(error)
            fixture.endCount += 1
            ended.fulfill()
        }
        fixture.scanner.start()
        wait(for: [started], timeout: 2)
        XCTAssertEqual(fixture.mock.scanCount, 1)

        fixture.changeState(.poweredOff)
        wait(for: [ended], timeout: 2)
        XCTAssertFalse(fixture.scanner.isScanning)

        fixture.changeState(.poweredOn)
        XCTAssertEqual(fixture.mock.scanCount, 1)
        fixture.scanner.stop()
        let mainDrained = expectation(description: "Main callbacks drained")
        DispatchQueue.main.async { mainDrained.fulfill() }
        wait(for: [mainDrained], timeout: 2)
        XCTAssertEqual(fixture.endCount, 1)
    }

    func test_pendingStartEndsIfPowerBecomesUnavailable()
    {
        let fixture = Fixture(initialState: .unknown)
        let started = expectation(description: "Start accepted")
        let ended = expectation(description: "Pending start ended")
        fixture.scanner.started = { _ in started.fulfill() }
        fixture.scanner.ended = { _, error in
            XCTAssertNotNil(error)
            ended.fulfill()
        }
        fixture.scanner.start()
        wait(for: [started], timeout: 2)
        fixture.changeState(.poweredOff)
        wait(for: [ended], timeout: 2)
        XCTAssertFalse(fixture.scanner.isScanning)

        fixture.changeState(.poweredOn)
        XCTAssertEqual(fixture.mock.scanCount, 0)
    }

    func test_queuedListChangeDoesNotDeliverAfterStop()
    {
        let fixture = Fixture(initialState: .poweredOn)
        var listChanges = 0
        fixture.scanner.listChanged = { _, _ in listChanges += 1 }
        fixture.scanner.start()
        fixture.flush() // Initial empty-list delivery has queued its main-thread callback.
        fixture.scanner.stop()

        let mainDrained = expectation(description: "Main callback queue drained")
        DispatchQueue.main.async { mainDrained.fulfill() }
        wait(for: [mainDrained], timeout: 2)
        XCTAssertEqual(listChanges, 0)
    }

    private final class Fixture
    {
        let delegate = UUCentralManagerDelegate()
        let central: UUCentralManager
        let mock: RecordingCentral
        let scanner: UUCoreBluetoothPeripheralScanner
        var endCount = 0

        init(initialState: CBManagerState)
        {
            let delegate = self.delegate
            var injected: RecordingCentral!
            central = UUCentralManager(options: UUCentralManagerOptions(), injection: { queue, options in
                let mock = RecordingCentral(delegate: delegate, queue: queue,
                    options: options.coreBluetoothOptions)
                mock.state = initialState
                injected = mock
                return (delegate, mock)
            })
            mock = injected
            scanner = UUCoreBluetoothPeripheralScanner(centralManager: central)
            scanner.config = UUPeripheralScannerConfig(callbackThrottle: 0)
        }

        func flush() { central.dispatchQueue.sync {} }

        func changeState(_ state: CBManagerState)
        {
            central.dispatchQueue.sync
            {
                mock.state = state
                delegate.centralStateChangedBlock?(state)
            }
        }
    }

    private final class RecordingCentral: UUMockCBCentralManager
    {
        var scanCount = 0
        override func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String: Any]?)
        {
            scanCount += 1
        }
    }
}
