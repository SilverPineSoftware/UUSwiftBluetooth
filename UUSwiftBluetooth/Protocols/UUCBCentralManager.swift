//
//  UUCBCentralManager.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 7/4/25.
//

import Foundation
import CoreBluetooth

public protocol UUCBCentralManager : UUCBManager
{
    /**
     *  @property delegate
     *
     *  @discussion The delegate object that will receive central events.
     *
     */
    var delegate: (any CBCentralManagerDelegate)? { get set }

    /**
     *  @property isScanning
     *
     *  @discussion Whether or not the central is currently scanning.
     *
     */
    @available(iOS 9.0, *)
    var isScanning: Bool { get }

    /**
     *  @method supportsFeatures
     *
     *  @param features    One or more features you would like to check if supported.
     *
     *  @discussion     Returns a boolean value representing the support for the provided features.
     *
     */
    @available(iOS 13.0, *)
    static func supports(_ features: CBCentralManager.Feature) -> Bool

    //convenience init()

    /**
     *  @method initWithDelegate:queue:
     *
     *  @param delegate The delegate that will receive central role events.
     *  @param queue    The dispatch queue on which the events will be dispatched.
     *
     *  @discussion     The initialization call. The events of the central role will be dispatched on the provided queue.
     *                  If <i>nil</i>, the main queue will be used.
     *
     */
    //init(delegate: (any CBCentralManagerDelegate)?, queue: dispatch_queue_t?)

    /**
     *  @method initWithDelegate:queue:options:
     *
     *  @param delegate The delegate that will receive central role events.
     *  @param queue    The dispatch queue on which the events will be dispatched.
     *  @param options  An optional dictionary specifying options for the manager.
     *
     *  @discussion     The initialization call. The events of the central role will be dispatched on the provided queue.
     *                  If <i>nil</i>, the main queue will be used.
     *
     *    @seealso        CBCentralManagerOptionShowPowerAlertKey
     *    @seealso        CBCentralManagerOptionRestoreIdentifierKey
     *
     */
    //@available(iOS 7.0, *)
    //public
    init(delegate: (any CBCentralManagerDelegate)?, queue: dispatch_queue_t?, options: [String : Any]?)

    /**
     *  @method retrievePeripheralsWithIdentifiers:
     *
     *  @param identifiers    A list of <code>NSUUID</code> objects.
     *
     *  @discussion            Attempts to retrieve the <code>CBPeripheral</code> object(s) with the corresponding <i>identifiers</i>.
     *
     *    @return                A list of <code>CBPeripheral</code> objects.
     *
     */
    //@available(iOS 7.0, *)
    func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [CBPeripheral]

    /**
     *  @method retrieveConnectedPeripheralsWithServices
     *
     *  @discussion Retrieves all peripherals that are connected to the system and implement any of the services listed in <i>serviceUUIDs</i>.
     *                Note that this set can include peripherals which were connected by other applications, which will need to be connected locally
     *                via {@link connectPeripheral:options:} before they can be used.
     *
     *    @return        A list of <code>CBPeripheral</code> objects.
     *
     */
    //@available(iOS 7.0, *)
    func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> [CBPeripheral]

    /**
     *  @method scanForPeripheralsWithServices:options:
     *
     *  @param serviceUUIDs A list of <code>CBUUID</code> objects representing the service(s) to scan for.
     *  @param options      An optional dictionary specifying options for the scan.
     *
     *  @discussion         Starts scanning for peripherals that are advertising any of the services listed in <i>serviceUUIDs</i>. Although strongly discouraged,
     *                      if <i>serviceUUIDs</i> is <i>nil</i> all discovered peripherals will be returned. If the central is already scanning with different
     *                      <i>serviceUUIDs</i> or <i>options</i>, the provided parameters will replace them.
     *                      Applications that have specified the <code>bluetooth-central</code> background mode are allowed to scan while backgrounded, with two
     *                      caveats: the scan must specify one or more service types in <i>serviceUUIDs</i>, and the <code>CBCentralManagerScanOptionAllowDuplicatesKey</code>
     *                      scan option will be ignored.
     *
     *  @see                centralManager:didDiscoverPeripheral:advertisementData:RSSI:
     *  @seealso            CBCentralManagerScanOptionAllowDuplicatesKey
     *    @seealso            CBCentralManagerScanOptionSolicitedServiceUUIDsKey
     *
     */
    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String : Any]?)

    /**
     *  @method stopScan:
     *
     *  @discussion Stops scanning for peripherals.
     *
     */
    func stopScan()

    /**
     *  @method connectPeripheral:options:
     *
     *  @param peripheral   The <code>CBPeripheral</code> to be connected.
     *  @param options      An optional dictionary specifying connection behavior options.
     *
     *  @discussion         Initiates a connection to <i>peripheral</i>. Connection attempts never time out and, depending on the outcome, will result
     *                      in a call to either {@link centralManager:didConnectPeripheral:} or {@link centralManager:didFailToConnectPeripheral:error:}.
     *                      Pending attempts are cancelled automatically upon deallocation of <i>peripheral</i>, and explicitly via {@link cancelPeripheralConnection}.
     *
     *  @see                centralManager:didConnectPeripheral:
     *  @see                centralManager:didFailToConnectPeripheral:error:
     *  @seealso            CBConnectPeripheralOptionNotifyOnConnectionKey
     *  @seealso            CBConnectPeripheralOptionNotifyOnDisconnectionKey
     *  @seealso            CBConnectPeripheralOptionNotifyOnNotificationKey
     *  @seealso            CBConnectPeripheralOptionEnableTransportBridgingKey
     *    @seealso            CBConnectPeripheralOptionRequiresANCS
     *  @seealso            CBConnectPeripheralOptionEnableAutoReconnect
     *
     */
    func connect(_ peripheral: CBPeripheral, options: [String : Any]?)

    /**
     *  @method cancelPeripheralConnection:
     *
     *  @param peripheral   A <code>CBPeripheral</code>.
     *
     *  @discussion         Cancels an active or pending connection to <i>peripheral</i>. Note that this is non-blocking, and any <code>CBPeripheral</code>
     *                      commands that are still pending to <i>peripheral</i> may or may not complete.
     *
     *  @see                centralManager:didDisconnectPeripheral:error:
     *
     */
    func cancelPeripheralConnection(_ peripheral: CBPeripheral)

    /**
     *  @method registerForConnectionEventsWithOptions:
     *
     *  @param options        A dictionary specifying connection event options.
     *
     *  @discussion         Calls {@link centralManager:connectionEventDidOccur:forPeripheral:} when a connection event occurs matching any of the given options.
     *                      Passing nil in the option parameter clears any prior registered matching options.
     *
     *  @see                centralManager:connectionEventDidOccur:forPeripheral:
     *  @seealso            CBConnectionEventMatchingOptionServiceUUIDs
     *  @seealso            CBConnectionEventMatchingOptionPeripheralUUIDs
     */
    //@available(iOS 13.0, *)
    func registerForConnectionEvents(options: [CBConnectionEventMatchingOption : Any]?)
}


// Declare conformance 
extension CBCentralManager: UUCBCentralManager
{
    
}



