import Foundation
import CoreBluetooth
@testable import UUSwiftBluetooth

/// Test backend for the central's injection seam. Delivers results directly to
/// the library's registered blocks, without constructing a CBCentralManager.
/// Use subclasses to hold responses or record calls for ordering assertions.
class TestCentralManager: UUCBCentralManager
{
    var mockDispatchQueue: DispatchQueue
    var mockCallbackError: Error?
    var mockCallbackTime: TimeInterval = 0.01
    var mockPeripherals: [CBPeripheral] = []
    var delegate: (any CBCentralManagerDelegate)?
    var isScanning = false
    var state: CBManagerState = .poweredOn
    var authorization: CBManagerAuthorization = .allowedAlways
    static var authorization: CBManagerAuthorization = .allowedAlways

    required init(delegate: (any CBCentralManagerDelegate)?, queue: dispatch_queue_t?, options: [String: Any]?)
    {
        precondition(delegate == nil || delegate is UUCentralManagerDelegate)
        self.delegate = delegate
        mockDispatchQueue = queue ?? DispatchQueue(label: "TestCentralManager")
    }

#if os(iOS)
    static func supports(_ features: CBCentralManager.Feature) -> Bool { true }
    func registerForConnectionEvents(options: [CBConnectionEventMatchingOption: Any]?) {}
#endif

    func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [CBPeripheral]
    {
        mockPeripherals.filter { identifiers.contains($0.identifier) }
    }

    func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> [CBPeripheral]
    {
        mockPeripherals.filter { peripheral in
            peripheral.services?.contains { serviceUUIDs.contains($0.uuid) } ?? false
        }
    }

    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String: Any]?)
    {
        isScanning = true
    }

    func stopScan() { isScanning = false }

    func connect(_ peripheral: CBPeripheral, options: [String: Any]?)
    {
        peripheral.setValue(CBPeripheralState.connecting.rawValue, forKey: "state")
        dispatch
        {
            if let error = self.mockCallbackError
            {
                self.deliverConnectionFailure(peripheral, error: error)
            }
            else
            {
                self.deliverConnection(peripheral)
            }
        }
    }

    func cancelPeripheralConnection(_ peripheral: CBPeripheral)
    {
        peripheral.setValue(CBPeripheralState.disconnecting.rawValue, forKey: "state")
        dispatch { self.deliverDisconnection(peripheral, error: self.mockCallbackError) }
    }

    // Explicit event controls for tests which override automatic responses.
    func deliverConnection(_ peripheral: CBPeripheral)
    {
        peripheral.setValue(CBPeripheralState.connected.rawValue, forKey: "state")
        let delegate = delegate as? UUCentralManagerDelegate
        let block = delegate?.connectBlocks.removeValue(forKey: peripheral.identifier)
        block?(peripheral)
    }

    func deliverConnectionFailure(_ peripheral: CBPeripheral, error: Error)
    {
        peripheral.setValue(CBPeripheralState.disconnected.rawValue, forKey: "state")
        deliverEnd(peripheral, error: NSError.uuConnectionFailedError(error as NSError))
    }

    func deliverDisconnection(_ peripheral: CBPeripheral, error: Error? = nil)
    {
        peripheral.setValue(CBPeripheralState.disconnected.rawValue, forKey: "state")
        deliverEnd(peripheral, error: NSError.uuDisconnectedError(error as NSError?))
    }

    private func deliverEnd(_ peripheral: CBPeripheral, error: Error?)
    {
        let delegate = delegate as? UUCentralManagerDelegate
        let block = delegate?.disconnectBlocks.removeValue(forKey: peripheral.identifier)
        delegate?.connectBlocks.removeValue(forKey: peripheral.identifier)
        block?(peripheral, error)
    }

    private func dispatch(_ block: @escaping () -> Void)
    {
        mockDispatchQueue.asyncAfter(deadline: .now() + mockCallbackTime, execute: block)
    }
}
