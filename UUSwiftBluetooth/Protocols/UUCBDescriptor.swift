
//
//  UUCBDescriptor.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 7/7/25.
//

import Foundation
import CoreBluetooth

public protocol UUCBDescriptor : UUCBAttribute
{

   /**
    *  @property characteristic
    *
    *  @discussion
    *      A back-pointer to the characteristic this descriptor belongs to.
    *
    */
   //var characteristic: CBCharacteristic? { get }

   /**
    *  @property value
    *
    *  @discussion
    *      The value of the descriptor. The corresponding value types for the various descriptors are detailed in @link CBUUID.h @/link.
    *
    */
   var value: Any? { get }
}


extension CBDescriptor: UUCBDescriptor
{
}
