//
//  UUL2CapChannel.swift
//  UUSwiftBluetooth
//
//  Created by Rhonda DeVore on 9/21/23.
//

import Foundation
import CoreBluetooth
import UUSwiftCore

public class UUL2CapChannel:NSObject//, StreamDelegate
{
    private var channel:CBL2CAPChannel? = nil
    private let peripheral:UUPeripheral
    private var psm:CBL2CAPPSM = 0

    private(set) public var dispatchQueue = DispatchQueue(label: "UUL2CapChannelQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .inherit, target: nil)

    private var dataReceivedCallback:((Data?) -> Void)? = nil
    
    public class Defaults
    {
        public static var openTimeout: TimeInterval = 10.0
        public static var operationTimeout: TimeInterval = 10.0
        
    }
    
    public init(_ peripheral: UUPeripheral)
    {
        self.peripheral = peripheral
        self.timerPool = UUTimerPool.getPool("UUL2CapChannel_\(peripheral.identifier)", queue: dispatchQueue)

        super.init()
    }
    
    public func open(psm:CBL2CAPPSM, timeout:TimeInterval = Defaults.openTimeout, completion: @escaping ((Error?) -> Void))
    {
        self.psm = psm //Not sure if this is necessary
        let timerId = TimerId.open
        
        self.peripheral.setDidOpenL2ChannelCallback
        { peripheral, l2CapChannel, error in
            
            self.peripheral.setDidOpenL2ChannelCallback(callback: nil)
            self.cancelTimer(timerId)
            
            NSLog("Open L2CapChannel with psm:\(psm) succeeded for peripheral:\(self.peripheral.identifier)")
            self.channel = l2CapChannel
            self.openStreams()
            
            completion(error)
        }
        
        self.startTimer(timerId, timeout)
        {
            self.peripheral.setDidOpenL2ChannelCallback(callback: nil)
            self.cancelTimer(timerId)

            NSLog("Open L2CapChannel with psm:\(psm) timeout for peripheral:\(self.peripheral.identifier)")
            let err = NSError.uuCoreBluetoothError(.timeout)
            
            completion(err)
        }
        
        self.peripheral.underlyingPeripheral.openL2CAPChannel(psm)        
    }
    
    
    

    
    
    
    
    

    private func openStreams()
    {
        self.channel?.inputStream.delegate = self
        self.channel?.outputStream.delegate = self
        
        self.channel?.inputStream.schedule(in: RunLoop.main, forMode: .default)
        self.channel?.outputStream.schedule(in: RunLoop.main, forMode: .default)
        
        self.channel?.inputStream.open()
        self.channel?.outputStream.open()
    }
    

    private func closeStreams()
    {
        self.channel?.inputStream.close()
        self.channel?.outputStream.close()
        
        self.channel?.inputStream.remove(from: RunLoop.main, forMode: .default)
        self.channel?.outputStream.remove(from: RunLoop.main, forMode: .default)
        
        self.channel?.inputStream.delegate = nil
        self.channel?.outputStream.delegate = nil
    }
    
    /**
     Sends data without waiting for a response
     */
    public func sendData(_ data:Data,
                         _ progress:((UInt32) -> Void)? = nil,
                         _ completion: @escaping ((Int?) -> Void))
    {
        
        guard let outputStream = self.channel?.outputStream else
        {
            completion(nil)
            return
        }
        
        self.uuWriteAllData(outputStream: outputStream, data: data, progress: progress, completion: completion)
    }
    
    /**
     Sends a message and returns a response in the completion
     */
    public func sendMessage(_ data:Data,
                            _ timeout:TimeInterval = Defaults.operationTimeout,
                            _ sendProgress:((UInt32) -> Void)? = nil,
                            _ completion: @escaping ((Int?, Data?, Error?) -> Void))
    {
        //TODO: Set timeouts and stuff!

        let timerId = TimerId.operation

        guard let outputStream = self.channel?.outputStream, (self.channel?.inputStream != nil) else
        {
            completion(nil, nil, nil)
            return
        }
        
        self.startTimer(timerId, timeout)
        {
            self.cancelTimer(timerId)

            NSLog("sendMessage timeout for peripheral:\(self.peripheral.identifier)")
            let err = NSError.uuCoreBluetoothError(.timeout)
            
            completion(nil, nil, err)
        }
        
        
        NSLog("Sending message...")
        self.uuWriteAllData(outputStream:outputStream, data:data, queue: dispatchQueue, progress: sendProgress)
        { numberOfBytesSent in
            
            NSLog("Message fully sent, waiting for data response...")
            
            self.dataReceivedCallback =
            { bytesReceived in
                
                self.cancelTimer(timerId)
                
                NSLog("Received Response for message")
                completion(numberOfBytesSent, bytesReceived, nil)
                
                self.dataReceivedCallback = nil
            }
            
        }
        
    }
    

    
    
    private func readAvailableData(_ stream:InputStream)
    {
        self.uuReadAllData(inputStream:stream, bufferLength:1024, queue: dispatchQueue)
        { dataRead in
         
            if let callback = self.dataReceivedCallback
            {
                callback(dataRead)
            }
            else
            {
                NSLog("Received data in stream but do not have anywhere to show it!")
            }
            
        }
        
    }
    
    private func handleStreamOpened(stream:Stream)
    {
        
    }
    
    private func handleStreameEndEncountered(stream:Stream)
    {
        
    }
    
    private func handleStreamHasBytesAvailable(stream:Stream)
    {
        if let inputStream = stream as? InputStream
        {
            self.readAvailableData(inputStream)
        }
        else
        {
            NSLog("Stream is not InputStream, cannot read data!")
        }
    }
    
    private func handleStreamHasSpaceAvailable(stream:Stream)
    {
        
    }
    
    private func handleStreamErrorOccurred(stream:Stream)
    {
        
    }
    
    /**
     Reads available data from input stream and continues reading until there
     is nothing left to read
     */
    func uuReadAllData(inputStream:InputStream, bufferLength:Int, queue:DispatchQueue = .main, completion: @escaping ((Data?) -> Void))
    {
        NSLog("Called uuReadData")
        queue.async
        {
            self.uuReadAllDataChunks(inputStream:inputStream, bufferLength:bufferLength, data: nil, completion: completion)
        }
    }
    
    private func uuReadAllDataChunks(inputStream:InputStream, bufferLength:Int, data:Data?, completion:((Data?) -> Void))
    {
        var workingData:Data? = data
        
        let dataRead = inputStream.uuReadData(bufferLength)

        NSLog("Read a chunk of data!")
        if let data = dataRead
        {
            if (workingData == nil)
            {
                workingData = Data()
                workingData?.append(data)
            }
        }
        
        if (inputStream.hasBytesAvailable)
        {
            NSLog("Have more data to read, trying again!")
            self.uuReadAllDataChunks(inputStream:inputStream, bufferLength:bufferLength, data: workingData, completion: completion)
        }
        else
        {
            NSLog("No more data to read, calling completion!")
            completion(workingData)
        }
    }
    
    /**
     Writes data to an output stream.
     */
    func uuWriteAllData(outputStream:OutputStream, data:Data?, queue:DispatchQueue = .main, progress:((UInt32) -> Void)?, completion: @escaping ((Int?) -> Void))
    {
        NSLog("Called uuWriteData")

        guard let d = data, !d.isEmpty else
        {
            NSLog("Data is nil or empty, cannot write!")
            completion(nil)
            return
        }
        
        guard outputStream.hasSpaceAvailable else
        {
            NSLog("No space available! (try again later?)")
            completion(nil)
            return
        }

        queue.async
        {
            self.uuWriteAllDataChunks(outputStream:outputStream, data: d, bytesSent: nil, progress: progress, completion: completion)
        }
    }
    
    private func uuWriteAllDataChunks(outputStream:OutputStream, data:Data, bytesSent:Int?, progress:((UInt32)->Void)?, completion:((Int?) -> Void))
    {
        let numberOfBytesSent = outputStream.uuWriteData(data: data)
        let totalBytesSent = (bytesSent ?? 0) + numberOfBytesSent

        NSLog("Sent one chunk of data (\(totalBytesSent) bytes)!")
        if (numberOfBytesSent < data.count)
        {
            progress?(UInt32(totalBytesSent))
            
            NSLog("Have more bytes to send...")

            let workingData = data.advanced(by: numberOfBytesSent)
            uuWriteAllDataChunks(outputStream:outputStream, data: workingData, bytesSent: numberOfBytesSent, progress: progress, completion: completion)
        }
        else
        {
            NSLog("No more bytes to send! Completing!")
            completion(totalBytesSent)
        }
    }
    
    
    //MARK: Timer stuff
    private let timerPool: UUTimerPool

    private enum TimerId: String
    {
        case open
        case operation
    }
    
    private func formatTimerId(_ bucket: TimerId) -> String
    {
        return "\(peripheral.identifier)__L2Cap__\(bucket.rawValue)"
    }
    
    private func startTimer(_ timerBucket: TimerId, _ timeout: TimeInterval, _ block: @escaping ()->())
    {
        let timerId = formatTimerId(timerBucket)
        NSLog("Starting bucket timer \(timerId) with timeout: \(timeout)")
        
        timerPool.start(identifier: timerId, timeout: timeout, userInfo: nil)
        { _ in
            block()
        }
    }
    
    private func cancelTimer(_ timerBucket: TimerId)
    {
        let timerId = formatTimerId(timerBucket)
        timerPool.cancel(by: timerId)
    }
    
}

extension UUL2CapChannel:StreamDelegate
{
    public func stream(_ stream: Stream, handle eventCode: Stream.Event)
    {
        switch eventCode
        {
        case Stream.Event.openCompleted:
            self.handleStreamOpened(stream: stream)
            NSLog("Stream Opened: \(stream.debugDescription)")

        case Stream.Event.endEncountered:
            self.handleStreameEndEncountered(stream: stream)
            NSLog("Stream End Encountered: \(stream.debugDescription)")

        case Stream.Event.hasBytesAvailable:
            self.handleStreamHasBytesAvailable(stream: stream)
            NSLog("Stream HasBytesAvailable: \(stream.debugDescription)")

        case Stream.Event.hasSpaceAvailable:
            self.handleStreamHasSpaceAvailable(stream: stream)
            NSLog("Stream Has Space Available: \(stream.debugDescription)")

        case Stream.Event.errorOccurred:
            self.handleStreamErrorOccurred(stream: stream)
            NSLog("Stream Error Occurred: \(stream.debugDescription)")

        default:
            NSLog("Unhandled Stream event code: \(eventCode)")
        }
    }
}



public extension InputStream
{
    func uuReadData(_ bufferLength:Int) -> Data?
    {
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferLength)
        
        defer
        {
            buffer.deallocate()
        }
        
        let rawBytesRead = self.read(buffer, maxLength: bufferLength)
        
        var data = Data()
        
        data.append(buffer, count: rawBytesRead)
        
        return data
    }
}

public extension OutputStream
{
    func uuWriteData(data:Data) -> Int
    {
        return data.withUnsafeBytes({ (unsafeRawBufferPointer:UnsafeRawBufferPointer) -> Int in
            
            let pointer = unsafeRawBufferPointer.bindMemory(to: UInt8.self)
            
            if let baseAddress = pointer.baseAddress
            {
                return self.write(baseAddress, maxLength: data.count)
            }
            else
            {
                return 0
            }
        })
    }
}


