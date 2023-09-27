//
//  UUL2CapServer.swift
//  UUSwiftBluetooth
//
//  Created by Rhonda DeVore on 9/26/23.
//

import CoreBluetooth
import UUSwiftCore

public class UUL2CapServer:NSObject, CBPeripheralManagerDelegate, StreamDelegate
{
    public var uuid:CBUUID
    
    private var manager: CBPeripheralManager? = nil
    private var psm:CBL2CAPPSM? = nil
    private var channel:CBL2CAPChannel? = nil
    private(set) public var dispatchQueue = DispatchQueue(label: "UUL2CapServerQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .inherit, target: nil)

    public var didReceiveDataCallback:((Data?) -> Void)? = nil
    
    public var isRunning:Bool
    {
        get
        {
            manager?.isAdvertising == true 
        }
    }
    
    public var peerIdentifier:UUID?
    {
        get
        {
            channel?.peer.identifier
        }
    }
    
    public init(uuid:CBUUID)
    {
        self.uuid = uuid
        self.timerPool = UUTimerPool.getPool("UUL2CapServer_\(uuid)", queue: dispatchQueue)
        
        super.init()
    }
    
    
    
    
    
    private var didPeripheralPowerOnBlock:((Error?) -> Void)? = nil
    private var didPublishChannelBlock:((Error?) -> Void)? = nil
    private var didStartAdvertisingBlock:((Error?) -> Void)? = nil
    
    public func start(secure:Bool, completion: @escaping (CBL2CAPPSM?, Error?) -> Void)
    {
        let timerId = TimerId.start
        
        self.startTimer(timerId, 10)
        {
            self.cancelStart(timerId)

            NSLog("start timeout for uul2capserver:\(self.uuid)")
            let err = NSError.uuCoreBluetoothError(.timeout)
            
            completion(nil, err)
        }
        
        self.didPeripheralPowerOnBlock =
        { error in
            
            self.didPeripheralPowerOnBlock = nil
            
            if let err = error
            {
                self.cancelStart(timerId)
                completion(nil, err)
            }
            else
            {
                self.publishChannel(timerId: timerId, secure: secure, completion: completion)
            }
        }
        
        
        //Queue up the manager
        self.manager = CBPeripheralManager(delegate: self, queue: nil)
        
        
    }
    
    private func cancelStart(_ timerId:TimerId)
    {
        self.cancelTimer(timerId)
        self.didPeripheralPowerOnBlock = nil
        self.didPublishChannelBlock = nil
        self.didStartAdvertisingBlock = nil
        self.stop()
    }
    
    private func publishChannel(timerId:TimerId, secure:Bool, completion: @escaping (CBL2CAPPSM?, Error?) -> Void)
    {
        guard let manager = manager else
        {
            self.cancelStart(timerId)
            let err = NSError.uuCoreBluetoothError(.centralNotReady, userInfo: ["l2capserver":"manager is nil!"])
            completion(nil, err)
            return
        }
                
        self.didPublishChannelBlock =
        { error in
            
            self.didPublishChannelBlock = nil
            
            if let err = error
            {
                self.cancelStart(timerId)
                completion(nil, err)
            }
            else
            {
                self.startAdvertising(timerId: timerId, completion: completion)
            }
        }
        
        manager.publishL2CAPChannel(withEncryption: secure)
    }
    
    private func startAdvertising(timerId:TimerId, completion: @escaping (CBL2CAPPSM?, Error?) -> Void)
    {
        guard let manager = manager else
        {
            self.cancelStart(timerId)
            let err = NSError.uuCoreBluetoothError(.centralNotReady, userInfo: ["l2capserver":"manager is nil!"])
            completion(nil, err)
            return
        }
        
        
        let uuidlist = [uuid]

        var name:String = "L2CapServer-"
        if let num = psm
        {
            name += "\(num)"
        }

        let advertisingData: [String:Any] = [CBAdvertisementDataServiceUUIDsKey:uuidlist, CBAdvertisementDataLocalNameKey:name]
        
        
        self.didStartAdvertisingBlock =
        { error in
            
            self.cancelTimer(timerId)
            self.didPeripheralPowerOnBlock = nil
            self.didPublishChannelBlock = nil
            self.didStartAdvertisingBlock = nil
            
            completion(self.psm, error)
        }

        manager.startAdvertising(advertisingData)
    }
    
    private var didUnpublishChannelBlock:((Error?) -> Void)? = nil
    
    public func stop()
    {
        self.closeChannelStreams()
        self.channel = nil
        
        if let manager = self.manager,
           let psm = self.psm
        {
            self.didUnpublishChannelBlock =
            { error in
                
                self.manager = nil
            }
            
            manager.unpublishL2CAPChannel(psm)
        }
    }
    
    //MARK: Streams
    private func openChannelStreams()
    {
        self.channel?.inputStream.delegate = self
        self.channel?.outputStream.delegate = self
        
        self.channel?.inputStream.schedule(in: RunLoop.main, forMode: .default)
        self.channel?.outputStream.schedule(in: RunLoop.main, forMode: .default)
        
        self.channel?.inputStream.open()
        self.channel?.outputStream.open()
    }
    
    private func closeChannelStreams()
    {
        self.channel?.inputStream.close()
        self.channel?.outputStream.close()
        
        self.channel?.inputStream.remove(from: RunLoop.main, forMode: .default)
        self.channel?.outputStream.remove(from: RunLoop.main, forMode: .default)
        
        self.channel?.inputStream.delegate = nil
        self.channel?.outputStream.delegate = nil
    }
    
   
    //MARK: Timer stuff
    private let timerPool: UUTimerPool

    private enum TimerId: String
    {
        case start
    }
    
    private func formatTimerId(_ bucket: TimerId) -> String
    {
        return "\(uuid)__L2CapServer__\(bucket.rawValue)"
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
        NSLog("Cancelling bucket timer \(timerId)")
        timerPool.cancel(by: timerId)
    }
    
    
    //MARK: CBPeripheralManagerDelegate
    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager)
    {
        var error:NSError? = nil
        
        if (peripheral.state != .poweredOn)
        {
            error = NSError.uuCoreBluetoothError(.centralNotReady, userInfo: ["peripheral_state":"\(peripheral.state)"])
        }
        
        if let powerOnBlock = didPeripheralPowerOnBlock
        {
            powerOnBlock(error)
        }
    }
    
    public func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?)
    {
        if let didStartBlock = didStartAdvertisingBlock
        {
            didStartBlock(error)
        }
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, didPublishL2CAPChannel PSM: CBL2CAPPSM, error: Error?)
    {
        self.psm = PSM
        self.didPublishChannelBlock?(error)
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, didUnpublishL2CAPChannel PSM: CBL2CAPPSM, error: Error?)
    {
        self.channel = nil //Should already be nil at this point but just for safety do it here too!
        
        if let didUnpublishBlock = didUnpublishChannelBlock
        {
            didUnpublishBlock(error)
        }
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, didOpen channel: CBL2CAPChannel?, error: Error?)
    {
        self.channel = channel
        self.openChannelStreams()
    }
    
    //MARK: StreamDelegate
    public func stream(_ stream: Stream, handle eventCode: Stream.Event)
    {
        switch eventCode
        {
        case Stream.Event.openCompleted:
            NSLog("Stream Opened: \(stream.debugDescription)")

        case Stream.Event.endEncountered:
            NSLog("Stream End Encountered: \(stream.debugDescription)")

        case Stream.Event.hasBytesAvailable:
            NSLog("Stream HasBytesAvailable: \(stream.debugDescription)")
            if let inputStream = stream as? InputStream
            {
                self.readAvailableData(inputStream: inputStream, data: nil)
                { bytesReceived in
                    
                    self.didReceiveDataCallback?(bytesReceived)
                    self.echoBack(bytesReceived)
                }
            }

        case Stream.Event.hasSpaceAvailable:
            NSLog("Stream Has Space Available: \(stream.debugDescription)")

        case Stream.Event.errorOccurred:
            NSLog("Stream Error Occurred: \(stream.debugDescription)")

        default:
            NSLog("Unhandled Stream event code: \(eventCode)")
        }
    }
    
    private func readAvailableData(inputStream:InputStream, data:Data?, completion:((Data?) -> Void))
    {
        var workingData:Data? = data
        
        let dataRead = inputStream.uuReadData(1024)

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
            self.readAvailableData(inputStream:inputStream, data: workingData, completion: completion)
        }
        else
        {
            completion(workingData)
        }
    }
    
    private var bytesToSend:Data? = nil

    private func echoBack(_ receivedBytes:Data?)
    {
        
        let tx = String("\(receivedBytes?.uuToHexString() ?? "nil")".reversed())
        
        self.bytesToSend = Data(tx.uuToHexData() ?? NSData())
        
        if let outputStream = self.channel?.outputStream as? OutputStream
        {
            self.sendData(outputStream: outputStream, bytesPreviouslySent: nil)
            { totalBytesSent in
                                
                if let total = totalBytesSent
                {
                    NSLog("\(total) Total Bytes Sent!")
                }
                else
                {
                    NSLog("Total Bytes Sent is nil!")
                }
                
            }
        }
    }
    
    private func sendData(outputStream:OutputStream, bytesPreviouslySent:Int?, completion:((Int?) -> Void))
    {
        guard let dataToSend = bytesToSend, dataToSend.count > 0 else
        {
            completion(bytesPreviouslySent)
            return
        }
        
        
        let numberOfBytesSent = outputStream.uuWriteData(data: dataToSend)
        let totalBytesSent = (bytesPreviouslySent ?? 0) + numberOfBytesSent

        if (numberOfBytesSent < (self.bytesToSend?.count ?? 0))
        {
            self.bytesToSend = self.bytesToSend?.advanced(by: numberOfBytesSent)
            sendData(outputStream: outputStream, bytesPreviouslySent: totalBytesSent, completion: completion)
        }
        else
        {
            completion(totalBytesSent)
        }
    }
}
