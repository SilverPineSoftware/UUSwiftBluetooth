import XCTest
import CoreBluetooth
@testable import UUSwiftBluetooth

final class UUCentralRestorationTests: XCTestCase
{
    func test_restorationBeforeRegistrationIsDeliveredOnceAndPeripheralIsAvailable()
    {
        let fixture = Fixture(restoreDuringConstruction: true)
        var received: [[String: Any]] = []
        fixture.central.registerForRestoration { received.append($0) }

        XCTAssertEqual(received.count, 1)
        let wrapper = fixture.central.getPeripheral(identifier: fixture.native.identifier)
        XCTAssertNotNil(wrapper)
        XCTAssertNotNil(fixture.native.delegate)

        fixture.central.registerForRestoration { received.append($0) }
        XCTAssertEqual(received.count, 1, "Re-registration must not replay an already delivered state")
    }

    func test_restorationAfterRegistrationIsDeliveredOnce()
    {
        let fixture = Fixture()
        var received: [[String: Any]] = []
        fixture.central.registerForRestoration { received.append($0) }
        fixture.restore()
        XCTAssertEqual(received.count, 1)
        XCTAssertTrue(fixture.central.getPeripheral(identifier: fixture.native.identifier) != nil)

        fixture.central.registerForRestoration { received.append($0) }
        XCTAssertEqual(received.count, 1)
    }

    func test_scannerStartDoesNotConsumePendingRestoration()
    {
        let fixture = Fixture(restoreDuringConstruction: true)
        let scanner = UUCoreBluetoothPeripheralScanner(centralManager: fixture.central)
        scanner.start()
        var received = 0
        fixture.central.registerForRestoration { _ in received += 1 }
        XCTAssertEqual(received, 1)
        scanner.stop()
    }

    func test_existingScanRestorationCallbackReceivesBufferedState()
    {
        let fixture = Fixture(restoreDuringConstruction: true)
        var received = 0
        fixture.central.startScan(config: UUPeripheralScannerConfig(),
            advertisementHandler: { _ in },
            willRestoreCallback: { _ in received += 1 })
        XCTAssertEqual(received, 1)
        fixture.central.stopScan()
    }

    func test_restorationReusesDiscoveredWrapperAndRebindsNativeDelegate()
    {
        let fixture = Fixture()
        fixture.central.startScan(config: UUPeripheralScannerConfig(), advertisementHandler: { _ in })
        fixture.central.dispatchQueue.sync
        {
            fixture.delegate.didDiscoverPeripheralBlock?(fixture.native, [:], NSNumber(value: -50))
        }
        let wrapper = fixture.central.getPeripheral(identifier: fixture.native.identifier)
        let restoredNative = UUMockCBPeripheral(identifier: fixture.native.identifier).backingPeripheral
        fixture.restore(peripheral: restoredNative)

        XCTAssertTrue(fixture.central.getPeripheral(identifier: fixture.native.identifier) === wrapper)
        XCTAssertTrue((wrapper?.underlyingPeripheral as? CBPeripheral) === restoredNative)
        XCTAssertNotNil(restoredNative.delegate)
        fixture.central.stopScan()
    }

    func test_emptyRestorationIdentifierIsOmittedFromCoreBluetoothOptions()
    {
        let options = UUCentralManagerOptions(stateRestorationIdentifier: "")
        XCTAssertFalse(options.usesStateRestoration)
        XCTAssertNil(options.coreBluetoothOptions?[CBCentralManagerOptionRestoreIdentifierKey])
    }

    private final class Fixture
    {
        let backend = UUMockCBPeripheral()
        let delegate = UUCentralManagerRestoringDelegate()
        let central: UUCentralManager
        var native: CBPeripheral { backend.backingPeripheral }

        init(restoreDuringConstruction: Bool = false)
        {
            let native = backend.backingPeripheral
            let restoringDelegate = delegate
            central = UUCentralManager(
                options: UUCentralManagerOptions(stateRestorationIdentifier: "unit-test-restoration"),
                injection: { queue, options in
                    let mock = UUMockCBCentralManager(delegate: restoringDelegate, queue: queue,
                        options: options.coreBluetoothOptions)
                    mock.mockPeripherals = [native]
                    if restoreDuringConstruction
                    {
                        restoringDelegate.receiveRestorationState([
                            CBCentralManagerRestoredStatePeripheralsKey: [native]
                        ])
                    }
                    return (restoringDelegate, mock)
                })
        }

        func restore(peripheral: CBPeripheral? = nil)
        {
            central.dispatchQueue.sync
            {
                delegate.receiveRestorationState([
                    CBCentralManagerRestoredStatePeripheralsKey: [peripheral ?? native]
                ])
            }
        }
    }
}
