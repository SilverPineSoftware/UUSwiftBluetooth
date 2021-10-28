//
//  UUTimer.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 8/17/21.
//

import UIKit

public typealias UUTimerBlock = ((UUTimer)->())
public typealias UUWatchdogTimerBlock = ((Any?)->())

public class UUTimer: NSObject
{
    private(set) var timerId: String = ""
    private(set) var userInfo: Any? = nil
    private(set) var interval: TimeInterval = 0
    private(set) var lastFireTime: TimeInterval = 0
    
    private var shouldRepeat: Bool = false
    //private var callback: UUTimerBlock? = nil
    private var dispatchSource: DispatchSourceTimer? = nil
    
    private static var uuActiveTimers: [String:UUTimer] = [:]
    private static let uuActiveTimersMutex = NSRecursiveLock()
    
    convenience init(
        _ interval: TimeInterval,
        _ userInfo: Any?,
        _ shouldRepeat: Bool,
        _ queue: DispatchQueue,
        _ block: @escaping UUTimerBlock)
    {
        self.init(UUID().uuidString, interval, userInfo, shouldRepeat, queue, block)
    }
    
    required init(
        _ timerId: String,
        _ interval: TimeInterval,
        _ userInfo: Any?,
        _ shouldRepeat: Bool,
        _ queue: DispatchQueue,
        _ block: @escaping UUTimerBlock)
    {
        self.timerId = timerId
        self.interval = interval
        self.userInfo = userInfo
        self.shouldRepeat = shouldRepeat
        self.lastFireTime = 0
        
        self.dispatchSource = DispatchSource.makeTimerSource(flags: [], queue: queue)
        
        self.lastFireTime = Date().timeIntervalSinceReferenceDate
        
        super.init()
        
        var repeatingInterval: DispatchTimeInterval = .never
        if (shouldRepeat)
        {
            repeatingInterval = .milliseconds(Int(interval * 1000.0))
        }
        
        var fireTime: DispatchTime = .distantFuture
        if (!shouldRepeat)
        {
            fireTime = .now() + interval
        }
        
        self.dispatchSource?.schedule(deadline: fireTime, repeating: repeatingInterval, leeway: .never)
        self.dispatchSource?.setEventHandler
        {
            block(self)
            
            if (!shouldRepeat)
            {
                self.cancel()
            }
        }
    }
    
    // Returns a shared serial queue for executing timers on a background thread
    public static func backgroundThreadTimerQueue() -> DispatchQueue
    {
        return DispatchQueue.global(qos: .userInteractive)
    }
    
    // Alias for DispatchQueue.main
    public static func mainThreadTimerQueue() -> DispatchQueue
    {
        return DispatchQueue.main
    }
    
    // Find an active timer by its ID
    public static func findActiveTimer(_ timerId: String) -> UUTimer?
    {
        defer { uuActiveTimersMutex.unlock() }
        uuActiveTimersMutex.lock()
        
        return uuActiveTimers[timerId]
    }
    
    // Lists all active timers
    static func listActiveTimers() -> [UUTimer]
    {
        defer { uuActiveTimersMutex.unlock() }
        uuActiveTimersMutex.lock()
        
        return uuActiveTimers.values.compactMap({ $0 })
    }
    
    
    
    
    public func start()
    {
        if let src = dispatchSource
        {
            //NSLog("Starting timer \(timerId), interval: \(interval), repeat: \(shouldRepeat), dispatchSource: \(String(describing: dispatchSource)), userInfo: \(String(describing: userInfo))")
            UUTimer.addTimer(self)
            src.resume()
        }
        else
        {
            //NSLog("Cannot start timer \(timerId) because dispatch source is nil")
        }
    }
    
    public func cancel()
    {
        //NSLog("Cancelling timer \(timerId), dispatchSource: \(String(describing: dispatchSource)), userInfo: \(String(describing: userInfo))")
        
        if let src = dispatchSource
        {
            src.cancel()
            
            self.dispatchSource = nil
        }
        
        UUTimer.removeTimer(self)
    }
    
    private static func addTimer(_ timer: UUTimer)
    {
        defer { uuActiveTimersMutex.unlock() }
        uuActiveTimersMutex.lock()
        
        uuActiveTimers[timer.timerId] = timer
    }
    
    private static func removeTimer(_ timer: UUTimer)
    {
        defer { uuActiveTimersMutex.unlock() }
        uuActiveTimersMutex.lock()
        
        uuActiveTimers.removeValue(forKey: timer.timerId)
    }
}

public extension UUTimer
{
    static func startWatchdogTimer(_ timerId: String, _ timeout: TimeInterval, _ userInfo: Any?, queue: DispatchQueue = UUTimer.backgroundThreadTimerQueue(), _ block: UUWatchdogTimerBlock?)
    {
        cancelWatchdogTimer(timerId)
        
        if (timeout > 0)
        {
            let t = UUTimer(timerId, timeout, userInfo, false, queue)
            { _ in
                if let b = block
                {
                    b(userInfo)
                }
            }
            
            t.start()
        }
    }
    
    static func cancelWatchdogTimer(_ timerId: String)
    {
        if let t = findActiveTimer(timerId)
        {
            t.cancel()
        }
    }
}
