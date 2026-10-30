import Foundation
import CoreBluetooth
@testable import UUSwiftBluetooth

/// A real UUPeripheral and UUCentralManager composed with test-only backends.
/// Used for operation tests and sorting inputs, never exported by the library.
final class TestPeripheralFixture: UUPeripheral
{
    let mockPeripheral: TestPeripheral
    let mockCentral: UUCentralManager
    private let centralBackend: TestCentralManager

    init(identifier: UUID = UUID(),
         advertisement: UUAdvertisement = UUAdvertisement(),
         rssi: Int = 0,
         name: String = "",
         friendlyName: String = "",
         firstDiscoveryTime: Date = Date(),
         peripheralState: CBPeripheralState = .disconnected,
         services: [CBMutableService]? = nil)
    {
        let backend = TestPeripheral(identifier: identifier, name: name,
                                     state: peripheralState, services: services)
        mockPeripheral = backend
        var injected: TestCentralManager!
        mockCentral = UUCentralManager(options: UUCentralManagerOptions(), injection: { queue, options in
            let delegate = UUCentralManagerDelegate()
            let central = TestCentralManager(delegate: delegate, queue: queue, options: options.coreBluetoothOptions)
            central.mockPeripherals = [backend.backingPeripheral]
            backend.mockDispatchQueue = queue
            injected = central
            return (delegate, central)
        })
        centralBackend = injected
        advertisement.timestamp = firstDiscoveryTime
        advertisement.rssi = rssi
        super.init(dispatchQueue: mockCentral.dispatchQueue, centralState: mockCentral.centralState,
                   peripheral: backend, advertisement: advertisement)
    }

    var mockCallbackError: Error?
    {
        didSet
        {
            mockPeripheral.mockCallbackError = mockCallbackError
            centralBackend.mockCallbackError = mockCallbackError
        }
    }
}
