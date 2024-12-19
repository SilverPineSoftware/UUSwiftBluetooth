//
//  UUL2CapServer.swift
//  UUSwiftBluetooth
//
//  Created by Rhonda DeVore on 9/26/23.
//

import CoreBluetooth
import UUSwiftCore

public class UUL2CapConstants
{
    public static  let UU_L2CAP_SERVICE_UUID = CBUUID(string: "0EF98E22-A048-4B8E-892E-1FDBD97191D5")
    public static let UU_L2CAP_PSM_CHARACTERISTIC_UUID = CBUUID(string: "6E53FA48-4063-45B6-9665-0BA0F4F93596")
    public static let UU_L2CAP_CHANNEL_ENCRYPTED_CHARACTERISTIC_UUID = CBUUID(string: "CE67C620-6302-4456-B97C-89337D2AD7C2")
}

public class UUL2CapServer:NSObject, CBPeripheralManagerDelegate, StreamDelegate
{
    public var uuid:CBUUID
    
  
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
        
    
    public func start(secure:Bool, completion: @escaping (CBL2CAPPSM?, Error?) -> Void)
    {
        let timerId = TimerId.start
        
        self.startTimer(timerId, 10)
        {
            self.cancelStart(timerId)

            UUDebugLog("start timeout for uul2capserver:\(self.uuid)")
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
    
    public func stop()
    {
        self.closeChannelStreams()
        self.channel = nil
        
        if let manager = self.manager,
           let psm = self.psm
        {
            self.didUnpublishChannelBlock =
            { error in
                
                self.unpublishService()
                self.manager = nil
            }
            
            manager.unpublishL2CAPChannel(psm)
        }
    }
    
    public func sendData(_ data:Data,
                         _ completion: @escaping ((Int?) -> Void))
    {
        
        guard let outputStream = self.channel?.outputStream else
        {
            completion(nil)
            return
        }
        
        outputStream.uuWriteData(data: data, chunkSize: nil, progressCallback: nil, completionCallback: completion)
    }
 
    
    private var manager: CBPeripheralManager? = nil
    private var psm:CBL2CAPPSM? = nil
    private var channel:CBL2CAPChannel? = nil
    private var service:CBMutableService? = nil
    private var psmCharacteristic:CBMutableCharacteristic? = nil
    private var encryptedCharacteristic:CBMutableCharacteristic? = nil

    
    
    private(set) public var dispatchQueue = DispatchQueue(label: "UUL2CapServerQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .inherit, target: nil)

    
    
    private var didPeripheralPowerOnBlock:((Error?) -> Void)? = nil
    private var didPublishChannelBlock:((Error?) -> Void)? = nil
    private var didPublishServiceBlock:((Error?) -> Void)? = nil
    private var didStartAdvertisingBlock:((Error?) -> Void)? = nil

    
    
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
        guard let manager = self.manager else
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
                self.publishService(timerId: timerId, secure: secure,  completion: completion)
            }
        }
        
        manager.publishL2CAPChannel(withEncryption: secure)
    }
    
    private func publishService(timerId:TimerId, secure:Bool, completion: @escaping (CBL2CAPPSM?, Error?) -> Void)
    {
        guard let manager = self.manager, let psm = self.psm else
        {
            self.cancelStart(timerId)
            let err = NSError.uuCoreBluetoothError(.centralNotReady, userInfo: ["l2capserver":"manager is nil!"])
            completion(nil, err)
            return
        }
    
        
        self.didPublishServiceBlock =
        { error in
            
            self.didPublishServiceBlock = nil
            
            if let err = error
            {
                UUDebugLog("Publish Service Error! \(err)")
                self.cancelStart(timerId)
                completion(nil, err)
            }
            else
            {
                self.startAdvertising(timerId: timerId, completion: completion)
            }
        }
        
        
        self.service = CBMutableService(type: UUL2CapConstants.UU_L2CAP_SERVICE_UUID, primary: true)
        
        var psmData = Data()
        psmData.uuAppend((UInt32(psm)))
        self.psmCharacteristic = CBMutableCharacteristic(type: UUL2CapConstants.UU_L2CAP_PSM_CHARACTERISTIC_UUID, properties: [.read], value: psmData, permissions: [.readable])
        
        var secureCopy = secure
        let secureData = Data(bytes: &secureCopy, count: MemoryLayout<UInt8>.size)
        self.encryptedCharacteristic = CBMutableCharacteristic(type: UUL2CapConstants.UU_L2CAP_CHANNEL_ENCRYPTED_CHARACTERISTIC_UUID, properties: [.read], value: secureData, permissions: [.readable])
        
        self.service?.characteristics = [self.psmCharacteristic!, self.encryptedCharacteristic!]
        
        manager.add(self.service!)
    }
    
    
    private func startAdvertising(timerId:TimerId, completion: @escaping (CBL2CAPPSM?, Error?) -> Void)
    {
        guard let manager = self.manager else
        {
            self.cancelStart(timerId)
            let err = NSError.uuCoreBluetoothError(.centralNotReady, userInfo: ["l2capserver":"manager is nil!"])
            completion(nil, err)
            return
        }
        
        
        let uuidlist = [uuid]

        let advertisingData: [String:Any] = [CBAdvertisementDataServiceUUIDsKey:uuidlist, CBAdvertisementDataLocalNameKey:"UUL2CapServer"]
        
        
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
    
    private func unpublishService()
    {
        self.manager?.stopAdvertising()
        self.manager?.removeAllServices()
        self.psmCharacteristic = nil
        self.encryptedCharacteristic = nil
        self.service = nil
    }
    
    private var didUnpublishChannelBlock:((Error?) -> Void)? = nil
    
   
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
        UUDebugLog("Starting bucket timer \(timerId) with timeout: \(timeout)")
        
        timerPool.start(identifier: timerId, timeout: timeout, userInfo: nil)
        { _ in
            block()
        }
    }
    
    private func cancelTimer(_ timerBucket: TimerId)
    {
        let timerId = formatTimerId(timerBucket)
        UUDebugLog("Cancelling bucket timer \(timerId)")
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
        
        if let powerOnBlock = self.didPeripheralPowerOnBlock
        {
            powerOnBlock(error)
        }
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) 
    {
        if let didAddServiceBlock = self.didPublishServiceBlock
        {
            didAddServiceBlock(error)
        }
    }
    
    public func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?)
    {
        if let didStartBlock = self.didStartAdvertisingBlock
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
        
        if let didUnpublishBlock = self.didUnpublishChannelBlock
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
            UUDebugLog("Stream Opened")

        case Stream.Event.endEncountered:
            UUDebugLog("Stream End Encountered")

        case Stream.Event.hasBytesAvailable:
            UUDebugLog("Stream HasBytesAvailable")
        
            if let inputStream = stream as? InputStream
            {
                let dataRead = inputStream.uuReadData(10240)
                UUDebugLog("Requested 10240 bytes read, actually read \(dataRead?.count ?? 0)")
                self.didReceiveDataCallback?(dataRead)
            }
            

        case Stream.Event.hasSpaceAvailable:
            UUDebugLog("Stream Has Space Available")

        case Stream.Event.errorOccurred:
            UUDebugLog("Stream Error Occurred")

        default:
            UUDebugLog("Unhandled Stream event code")
        }
    }
    
    /*
    private var rxQueue:[Data]? = nil
    private func handleRxFrameReceived(_ data:Data?)
    {
        guard let d = data else
        {
            return
        }
        
        if (rxQueue == nil)
        {
            rxQueue = []
        }
        
        rxQueue?.append(d)
        
        self.debounceDataReceived()
    }
    
    private func debounceDataReceived()
    {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.handleRxQueueComplete), object: nil)
        self.perform(#selector(self.handleRxQueueComplete), with: nil, afterDelay: 1.0)
    }
    
    @objc private func handleRxQueueComplete()
    {
        if (self.channel?.inputStream.hasBytesAvailable == false)
        {
            var fullDataSet = Data()
            
            for block in self.rxQueue ?? []
            {
                fullDataSet.append(block)
            }
            
            self.rxQueue = nil
            
            self.didReceiveDataCallback?(fullDataSet)
        }
    }*/
    
//    private var amReadingData:Bool = false
//    
//    private func readAvailableData(inputStream:InputStream, data:Data?, completion:((Data?) -> Void))
//    {
//        UUDebugLog("Setting amReadingData to true!")
//
//        amReadingData = true
//        var workingData:Data? = data
//        
//        let dataRead = inputStream.uuReadData(10240)
//
//        if let data = dataRead
//        {
//            if (workingData == nil)
//            {
//                workingData = Data()
//                workingData?.append(data)
//            }
//        }
//        
//        if (inputStream.hasBytesAvailable)
//        {
//            UUDebugLog("Reading Data, still have bytes available.... calling again")
//
//            self.readAvailableData(inputStream:inputStream, data: workingData, completion: completion)
//        }
//        else
//        {
//            UUDebugLog("Reading Data, no more bytes available, returning!")
//
//            completion(workingData)
//        }
//    }

}
