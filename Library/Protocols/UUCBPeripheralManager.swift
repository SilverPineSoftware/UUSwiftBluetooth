//
//  UUCBPeripheralManager.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 7/4/25.
//

import Foundation
import CoreBluetooth

public protocol UUCBPeripheralManager: UUCBManager
{

    /**
     *  @property delegate
     *
     *  @discussion The delegate object that will receive peripheral events.
     *
     */
    var delegate: (any CBPeripheralManagerDelegate)? { get set }

    /**
     *  @property isAdvertising
     *
     *  @discussion Whether or not the peripheral is currently advertising data.
     *
     */
    var isAdvertising: Bool { get }

    /**
     *  @method authorizationStatus
     *
     *  @discussion    This method does not prompt the user for access. You can use it to detect restricted access and simply hide UI instead of
     *                prompting for access.
     *
     *  @return        The current authorization status for sharing data while backgrounded. For the constants returned, see {@link CBPeripheralManagerAuthorizationStatus}.
     *
     *  @see        CBPeripheralManagerAuthorizationStatus
     */
    //@available(iOS, introduced: 7.0, deprecated: 13.0, message: "Use CBManagerAuthorization instead")
    //open class func authorizationStatus() -> CBPeripheralManagerAuthorizationStatus

    //public convenience init()

    /**
     *  @method initWithDelegate:queue:
     *
     *  @param delegate The delegate that will receive peripheral role events.
     *  @param queue    The dispatch queue on which the events will be dispatched.
     *
     *  @discussion     The initialization call. The events of the peripheral role will be dispatched on the provided queue.
     *                  If <i>nil</i>, the main queue will be used.
     *
     */
    //@available(iOS 6.0, *)
    //public convenience init(delegate: (any CBPeripheralManagerDelegate)?, queue: dispatch_queue_t?)

    /**
     *  @method initWithDelegate:queue:options:
     *
     *  @param delegate The delegate that will receive peripheral role events.
     *  @param queue    The dispatch queue on which the events will be dispatched.
     *  @param options  An optional dictionary specifying options for the manager.
     *
     *  @discussion     The initialization call. The events of the peripheral role will be dispatched on the provided queue.
     *                  If <i>nil</i>, the main queue will be used.
     *
     *    @seealso        CBPeripheralManagerOptionShowPowerAlertKey
     *    @seealso        CBPeripheralManagerOptionRestoreIdentifierKey
     *
     */
    //@available(iOS 7.0, *)
    init(delegate: (any CBPeripheralManagerDelegate)?, queue: dispatch_queue_t?, options: [String : Any]?)

    /**
     *  @method startAdvertising:
     *
     *  @param advertisementData    An optional dictionary containing the data to be advertised.
     *
     *  @discussion                 Starts advertising. Supported advertising data types are <code>CBAdvertisementDataLocalNameKey</code>
     *                              and <code>CBAdvertisementDataServiceUUIDsKey</code>.
     *                              When in the foreground, an application can utilize up to 28 bytes of space in the initial advertisement data for
     *                              any combination of the supported advertising data types. If this space is used up, there are an additional 10 bytes of
     *                              space in the scan response that can be used only for the local name. Note that these sizes do not include the 2 bytes
     *                              of header information that are required for each new data type. Any service UUIDs that do not fit in the allotted space
     *                              will be added to a special "overflow" area, and can only be discovered by an iOS device that is explicitly scanning
     *                              for them.
     *                              While an application is in the background, the local name will not be used and all service UUIDs will be placed in the
     *                              "overflow" area. However, applications that have not specified the "bluetooth-peripheral" background mode will not be able
     *                              to advertise anything while in the background.
     *
     *  @see                        peripheralManagerDidStartAdvertising:error:
     *  @seealso                    CBAdvertisementData.h
     *
     */
    func startAdvertising(_ advertisementData: [String : Any]?)

    /**
     *  @method stopAdvertising
     *
     *  @discussion Stops advertising.
     *
     */
    func stopAdvertising()

    /**
     *  @method setDesiredConnectionLatency:forCentral:
     *
     *  @param latency  The desired connection latency.
     *  @param central  A connected central.
     *
     *  @discussion     Sets the desired connection latency for an existing connection to <i>central</i>. Connection latency changes are not guaranteed, so the
     *                  resultant latency may vary. If a desired latency is not set, the latency chosen by <i>central</i> at the time of connection establishment
     *                  will be used. Typically, it is not necessary to change the latency.
     *
     *  @see            CBPeripheralManagerConnectionLatency
     *
     */
    func setDesiredConnectionLatency(_ latency: CBPeripheralManagerConnectionLatency, for central: CBCentral)

    /**
     *  @method addService:
     *
     *  @param service  A GATT service.
     *
     *  @discussion     Publishes a service and its associated characteristic(s) to the local database. If the service contains included services,
     *                  they must be published first.
     *
     *  @see            peripheralManager:didAddService:error:
     */
    func add(_ service: CBMutableService)

    /**
     *  @method removeService:
     *
     *  @param service  A GATT service.
     *
     *  @discussion     Removes a published service from the local database. If the service is included by other service(s), they must be removed
     *                  first.
     *
     */
    func remove(_ service: CBMutableService)

    /**
     *  @method removeAllServices
     *
     *  @discussion Removes all published services from the local database.
     *
     */
    func removeAllServices()

    /**
     *  @method respondToRequest:withResult:
     *
     *  @param request  The original request that was received from the central.
     *  @param result   The result of attempting to fulfill <i>request</i>.
     *
     *  @discussion     Used to respond to request(s) received via the @link peripheralManager:didReceiveReadRequest: @/link or
     *                  @link peripheralManager:didReceiveWriteRequests: @/link delegate methods.
     *
     *  @see            peripheralManager:didReceiveReadRequest:
     *  @see            peripheralManager:didReceiveWriteRequests:
     */
    func respond(to request: CBATTRequest, withResult result: CBATTError.Code)

    /**
     *  @method updateValue:forCharacteristic:onSubscribedCentrals:
     *
     *  @param value            The value to be sent via a notification/indication.
     *  @param characteristic   The characteristic whose value has changed.
     *  @param centrals         A list of <code>CBCentral</code> objects to receive the update. Note that centrals which have not subscribed to
     *                          <i>characteristic</i> will be ignored. If <i>nil</i>, all centrals that are subscribed to <i>characteristic</i> will be updated.
     *
     *  @discussion             Sends an updated characteristic value to one or more centrals, via a notification or indication. If <i>value</i> exceeds
     *                            {@link maximumUpdateValueLength}, it will be truncated to fit.
     *
     *  @return                 <i>YES</i> if the update could be sent, or <i>NO</i> if the underlying transmit queue is full. If <i>NO</i> was returned,
     *                          the delegate method @link peripheralManagerIsReadyToUpdateSubscribers: @/link will be called once space has become
     *                          available, and the update should be re-sent if so desired.
     *
     *  @see                    peripheralManager:central:didSubscribeToCharacteristic:
     *  @see                    peripheralManager:central:didUnsubscribeFromCharacteristic:
     *  @see                    peripheralManagerIsReadyToUpdateSubscribers:
     *    @seealso                maximumUpdateValueLength
     */
    func updateValue(_ value: Data, for characteristic: CBMutableCharacteristic, onSubscribedCentrals centrals: [CBCentral]?) -> Bool

    /**
     *  @method publishL2CAPChannelWithEncryption:
     *
     *  @param encryptionRequired        YES if the service requires the link to be encrypted before a stream can be established.  NO if the service can be used over
     *                                    an unsecured link.
     *
     *  @discussion     Create a listener for incoming L2CAP Channel connections.  The system will determine an unused PSM at the time of publishing, which will be returned
     *                    with @link peripheralManager:didPublishL2CAPChannel:error: @/link.  L2CAP Channels are not discoverable by themselves, so it is the application's
     *                    responsibility to handle PSM discovery on the client.
     *
     */
    //@available(iOS 11.0, *)
    func publishL2CAPChannel(withEncryption encryptionRequired: Bool)

    /**
     *  @method unpublishL2CAPChannel:
     *
     *  @param PSM        The service PSM to be removed from the system.
     *
     *  @discussion     Removes a published service from the local system.  No new connections for this PSM will be accepted, and any existing L2CAP channels
     *                    using this PSM will be closed.
     *
     */
    //@available(iOS 11.0, *)
    func unpublishL2CAPChannel(_ PSM: CBL2CAPPSM)
}
