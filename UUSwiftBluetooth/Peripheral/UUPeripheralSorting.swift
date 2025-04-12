//
//  UUPeripheralSorting.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 12/12/24.
//

import UIKit

public struct UUPeripheralRssiSortComparator: SortComparator
{
    public typealias Compared = UUPeripheral
    
    public var order: SortOrder = .forward
    
    public func compare(_ lhs: UUPeripheral, _ rhs: UUPeripheral) -> ComparisonResult
    {
        return compareNumbers(order, lhs.rssi, rhs.rssi)
    }
    
    public init(order: SortOrder)
    {
        self.order = order
    }
}

public struct UUPeripheralFirstDiscoveryTimeComparator: SortComparator
{
    public typealias Compared = UUPeripheral
    
    public var order: SortOrder = .forward
    
    public func compare(_ lhs: UUPeripheral, _ rhs: UUPeripheral) -> ComparisonResult
    {
        return compareDates(order, lhs.firstDiscoveryTime, rhs.firstDiscoveryTime)
    }
    
    public init(order: SortOrder)
    {
        self.order = order
    }
}

public struct UUPeripheralFriendlyNameComparator: SortComparator
{
    public typealias Compared = UUPeripheral
    
    public var order: SortOrder = .forward
    
    public func compare(_ lhs: UUPeripheral, _ rhs: UUPeripheral) -> ComparisonResult
    {
        return compareStrings(order, lhs.friendlyName, rhs.friendlyName)
    }
    
    public init(order: SortOrder)
    {
        self.order = order
    }
}

internal func compareNumbers<T: BinaryInteger>(_ order: SortOrder, _ lhs: T?, _ rhs: T?) -> ComparisonResult
{
    if (lhs == nil && rhs == nil)
    {
        return .orderedSame
    }
    
    if (lhs == nil && rhs != nil)
    {
        return descending(order)
    }
    
    if (rhs == nil && lhs != nil)
    {
        return ascending(order)
    }
    
    if let left = lhs, let right = rhs
    {
        if (left < right)
        {
            return ascending(order)
        }
        else if (right < left)
        {
            return descending(order)
        }
    }
    
    return .orderedSame
}

fileprivate func compareStrings(_ order: SortOrder, _ lhs: String?, _ rhs: String?) -> ComparisonResult
{
    if (lhs == nil && rhs == nil)
    {
        return .orderedSame
    }
    
    if (lhs == nil && rhs != nil)
    {
        return descending(order)
    }
    
    if (rhs == nil && lhs != nil)
    {
        return ascending(order)
    }
    
    if let left = lhs, let right = rhs
    {
        if (order == .forward)
        {
            return left.localizedCompare(right)
        }
        else
        {
            return right.localizedCompare(left)
        }
    }
    
    return .orderedSame
}

fileprivate func compareDates(_ order: SortOrder, _ lhs: Date?, _ rhs: Date?) -> ComparisonResult
{
    if (lhs == nil && rhs == nil)
    {
        return .orderedSame
    }
    
    if (lhs == nil && rhs != nil)
    {
        return descending(order)
    }
    
    if (rhs == nil && lhs != nil)
    {
        return ascending(order)
    }
    
    if let left = lhs, let right = rhs
    {
        if (order == .forward)
        {
            return left.compare(right)
        }
        else
        {
            return right.compare(left)
        }
    }
    
    return .orderedSame
}
    
fileprivate func ascending(_ order: SortOrder) -> ComparisonResult
{
    return order == .forward ? .orderedAscending : .orderedDescending
}

fileprivate func descending(_ order: SortOrder) -> ComparisonResult
{
    return order == .forward ? .orderedDescending : .orderedAscending
}
