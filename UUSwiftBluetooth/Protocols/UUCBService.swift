//
//  UUCBService.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 7/7/25.
//

import Foundation
import CoreBluetooth


public protocol UUCBService : UUCBAttribute
{
    /**
     * @property peripheral
     *
     * @discussion
     *      A back-pointer to the peripheral this service belongs to.
     *
     */
    var peripheral: CBPeripheral? { get }

    /**
     * @property isPrimary
     *
     * @discussion
     *      The type of the service (primary or secondary).
     *
     */
    var isPrimary: Bool { get }

    /**
     * @property includedServices
     *
     * @discussion
     *      A list of included CBServices that have so far been discovered in this service.
     *
     */
    var includedServices: [CBService]? { get }

    /**
     * @property characteristics
     *
     * @discussion
     *      A list of CBCharacteristics that have so far been discovered in this service.
     *
     */
    var characteristics: [CBCharacteristic]? { get }
}

extension CBService: UUCBService
{
}
