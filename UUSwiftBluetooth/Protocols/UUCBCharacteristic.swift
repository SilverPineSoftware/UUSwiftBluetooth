//
//  UUCBService.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 7/7/25.
//

import Foundation
import CoreBluetooth

public protocol UUCBCharacteristic : UUCBAttribute
{

    /**
     * @property service
     *
     *  @discussion
     *      A back-pointer to the service this characteristic belongs to.
     *
     */
    //weak open var service: CBService? { get }

    /**
     * @property properties
     *
     *  @discussion
     *      The properties of the characteristic.
     *
     */
    var properties: CBCharacteristicProperties { get }

    /**
     * @property value
     *
     *  @discussion
     *      The value of the characteristic.
     *
     */
    var value: Data? { get }

    /**
     * @property descriptors
     *
     *  @discussion
     *      A list of the CBDescriptors that have so far been discovered in this characteristic.
     *
     */
    var descriptors: [CBDescriptor]? { get }

    /**
     * @property isBroadcasted
     *
     *  @discussion
     *      Whether the characteristic is currently broadcasted or not.
     *
     */
    //@available(iOS, introduced: 5.0, deprecated: 8.0)
    //open var isBroadcasted: Bool { get }

    /**
     * @property isNotifying
     *
     *  @discussion
     *      Whether the characteristic is currently notifying or not.
     *
     */
    var isNotifying: Bool { get }
}

extension CBCharacteristic: UUCBCharacteristic
{
}
