//
//  UUPeripheralSorting.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 12/12/24.
//

import Foundation

public protocol UUPeripheralComparator
{
    var ascending: Bool { get }
    func compare(lhs: UUPeripheral, rhs: UUPeripheral) -> Bool
}

public class UUPeripheralRssiComparator: UUPeripheralComparator
{
    public var ascending: Bool = false
    
    public init(ascending: Bool = false)
    {
        self.ascending = ascending
    }
    
    public func compare(lhs: UUPeripheral, rhs: UUPeripheral) -> Bool
    {
        return compareNumbers(ascending, lhs.rssi, rhs.rssi)
    }
}

public class UUPeripheralFirstDiscoveryTimeComparator: UUPeripheralComparator
{
    public var ascending: Bool = true
    
    public init(ascending: Bool = true)
    {
        self.ascending = ascending
    }
    
    public func compare(lhs: UUPeripheral, rhs: UUPeripheral) -> Bool
    {
        return compareDates(ascending, lhs.firstDiscoveryTime, rhs.firstDiscoveryTime)
    }
}

public class UUPeripheralFriendlyNameComparator: UUPeripheralComparator
{
    public var ascending: Bool = true
    
    public init(ascending: Bool = true)
    {
        self.ascending = ascending
    }
    
    public func compare(lhs: UUPeripheral, rhs: UUPeripheral) -> Bool
    {
        return compareStrings(ascending, lhs.friendlyName, rhs.friendlyName)
    }
}


fileprivate func compareNumbers<T: BinaryInteger>(_ ascending: Bool, _ lhs: T?, _ rhs: T?) -> Bool
{
    if (lhs == nil && rhs == nil)
    {
        return !ascending
    }
    
    if (lhs == nil && rhs != nil)
    {
        return ascending
    }
    
    if (rhs == nil && lhs != nil)
    {
        return !ascending
    }
    
    if let left = lhs, let right = rhs
    {
        if (ascending)
        {
            return (left < right)
        }
        else
        {
            return (right < left)
        }
    }
    
    return !ascending
}

fileprivate func compareDates(_ ascending: Bool, _ lhs: Date?, _ rhs: Date?) -> Bool
{
    if (lhs == nil && rhs == nil)
    {
        return !ascending
    }
    
    if (lhs == nil && rhs != nil)
    {
        return ascending
    }
    
    if (rhs == nil && lhs != nil)
    {
        return !ascending
    }
    
    if let left = lhs, let right = rhs
    {
        if (ascending)
        {
            return (left < right)
        }
        else
        {
            return (right < left)
        }
    }
    
    return !ascending
}

fileprivate func compareStrings(_ ascending: Bool, _ lhs: String?, _ rhs: String?) -> Bool
{
    if (lhs == nil && rhs == nil)
    {
        return !ascending
    }
    
    if (lhs == nil && rhs != nil)
    {
        return ascending
    }
    
    if (rhs == nil && lhs != nil)
    {
        return !ascending
    }
    
    if let left = lhs, let right = rhs
    {
        switch left.localizedCompare(right)
        {
            case .orderedAscending: return ascending
            case .orderedDescending: return !ascending
            case .orderedSame: return true
        }
    }
    
    return !ascending
}
