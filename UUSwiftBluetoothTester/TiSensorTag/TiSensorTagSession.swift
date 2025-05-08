//
//  TiSensorTagSession.swift
//  UUSwiftBluetoothTester
//
//  Created by Ryan DeVore on 5/5/25.
//

import Foundation
import CoreBluetooth
import UUSwiftBluetooth



//extension CBUUID
//{
    struct TiSensorTag
    {
        struct Keys
        {
            static let service = CBUUID(string: "FFE0")
            static let data = CBUUID(string: "FFE1") // Key Press State
        }
        
        struct Gyroscope
        {
            static let service  = CBUUID(string: "F000AA50-0451-4000-B000-000000000000")
            static let data     = CBUUID(string: "F000AA51-0451-4000-B000-000000000000")
            static let config   = CBUUID(string: "F000AA52-0451-4000-B000-000000000000")
            static let period   = CBUUID(string: "F000AA53-0451-4000-B000-000000000000")
        }
        
        struct Accelerometer
        {
            static let service  = CBUUID(string: "F000AA10-0451-4000-B000-000000000000")
            static let data     = CBUUID(string: "F000AA11-0451-4000-B000-000000000000")
            static let config   = CBUUID(string: "F000AA12-0451-4000-B000-000000000000")
            static let period   = CBUUID(string: "F000AA13-0451-4000-B000-000000000000")
        }
        
        struct Temperature
        {
            static let service  = CBUUID(string: "F000AA00-0451-4000-B000-000000000000")
            static let data     = CBUUID(string: "F000AA01-0451-4000-B000-000000000000")
            static let config   = CBUUID(string: "F000AA02-0451-4000-B000-000000000000")
            static let period   = CBUUID(string: "F000AA03-0451-4000-B000-000000000000")
        }
        
        struct Humidity
        {
            static let service  = CBUUID(string: "F000AA20-0451-4000-B000-000000000000")
            static let data     = CBUUID(string: "F000AA21-0451-4000-B000-000000000000")
            static let config   = CBUUID(string: "F000AA22-0451-4000-B000-000000000000")
            static let period   = CBUUID(string: "F000AA23-0451-4000-B000-000000000000")
        }
        
        struct Barometer
        {
            static let service      = CBUUID(string: "F000AA40-0451-4000-B000-000000000000")
            static let data         = CBUUID(string: "F000AA41-0451-4000-B000-000000000000")
            static let config       = CBUUID(string: "F000AA42-0451-4000-B000-000000000000")
            static let calibration  = CBUUID(string: "F000AA43-0451-4000-B000-000000000000")
            static let period       = CBUUID(string: "F000AA44-0451-4000-B000-000000000000")
        }
        
        struct Magnetometer
        {
            static let service  = CBUUID(string: "F000AA30-0451-4000-B000-000000000000")
            static let data     = CBUUID(string: "F000AA31-0451-4000-B000-000000000000")
            static let config   = CBUUID(string: "F000AA32-0451-4000-B000-000000000000")
            static let period   = CBUUID(string: "F000AA33-0451-4000-B000-000000000000")
        }
        
        struct Light
        {
            static let service  = CBUUID(string: "F000AA70-0451-4000-B000-000000000000")
            static let data     = CBUUID(string: "F000AA71-0451-4000-B000-000000000000")
            static let config   = CBUUID(string: "F000AA72-0451-4000-B000-000000000000")
            static let period   = CBUUID(string: "F000AA73-0451-4000-B000-000000000000")
        }
        
        struct Movement
        {
            static let service  = CBUUID(string: "F000AA80-0451-4000-B000-000000000000")
            static let data     = CBUUID(string: "F000AA81-0451-4000-B000-000000000000")
            static let config   = CBUUID(string: "F000AA82-0451-4000-B000-000000000000")
            static let period   = CBUUID(string: "F000AA83-0451-4000-B000-000000000000")
        }
        
        struct Services
        {
            
            static let oad = CBUUID(string: "F000FFC0-0451-4000-B000-000000000000")
            
            
            static let io = CBUUID(string: "F000AA64-0451-4000-B000-000000000000")
            
            
            static let register2 = CBUUID(string: "F000AC00-0451-4000-B000-000000000000")
            static let display = CBUUID(string: "F000AD00-0451-4000-B000-000000000000")
        }
        
        
        static let TI_OAD_IMAGE_NOTIFY = CBUUID(string: "F000FFC1-0451-4000-B000-000000000000")
        static let TI_OAD_IMAGE_BLOCK_REQUEST = CBUUID(string: "F000FFC2-0451-4000-B000-000000000000")
        static let TI_CONNECTION_CONTROL_SERVICE = CBUUID(string: "F000CCC0-0451-4000-B000-000000000000")
        static let TI_CONNECTION_CONTROL_CURRENT_USED_PARAMETERS = CBUUID(string: "F000CCC1-0451-4000-B000-000000000000")
        static let TI_CONNECTION_CONTROL_REQUEST_NEW_PARAMETERS = CBUUID(string: "F000CCC2-0451-4000-B000-000000000000")
        static let TI_CONNECTION_CONTROL_DISCONNECT_REQUEST = CBUUID(string: "F000CCC3-0451-4000-B000-000000000000")
        static let TI_CONNECTION_CONTROL_NAP_INTERVAL_SETTING = CBUUID(string: "F000CCC4-0451-4000-B000-000000000000")
        
        
        static let IO_DATA = CBUUID(string: "F000AA65-0451-4000-B000-000000000000")
        static let IO_CONFIG = CBUUID(string: "F000AA66-0451-4000-B000-000000000000")
        
        static let TWO_REGISTER_DATA = CBUUID(string: "F000AC01-0451-4000-B000-000000000000")
        static let TWO_REGISTER_ADDRESS = CBUUID(string: "F000AC02-0451-4000-B000-000000000000")
        static let TWO_REGISTER_DEVICE_ID = CBUUID(string: "F000AC03-0451-4000-B000-000000000000")
        
        static let TWO_DISPLAY_DATA = CBUUID(string: "F000AD01-0451-4000-B000-000000000000")
        static let TWO_DISPLAY_CONTROL = CBUUID(string: "F000AD02-0451-4000-B000-000000000000")
        
        private static func appSpecName(_ uuid: CBUUID, _ name: String)
        {
            UUCoreBluetooth.register(commonName: name, for: uuid.uuidString)
        }
        
        static func addSpecNames()
        {
            //CBUUID.uuRegisterCommonName("name", CBUUID())
            
            appSpecName(Keys.service, "TI SimpleLink Keys Service")
            appSpecName(Keys.data, "TI SimpleLink Keys Key Press State")
            
            appSpecName(Services.oad, "TI OAD Service")
            appSpecName(TI_OAD_IMAGE_NOTIFY, "TI OAD Image Notify")
            appSpecName(TI_OAD_IMAGE_BLOCK_REQUEST, "TI OAD Image Block Request")
            appSpecName(TI_CONNECTION_CONTROL_SERVICE, "TI Connection Control Service")
            appSpecName(TI_CONNECTION_CONTROL_CURRENT_USED_PARAMETERS, "TI Connection Control Current Used Parameters")
            appSpecName(TI_CONNECTION_CONTROL_REQUEST_NEW_PARAMETERS, "TI Connection Control Request New Parameters")
            appSpecName(TI_CONNECTION_CONTROL_DISCONNECT_REQUEST, "TI Connection Control Disconnect Request")
            appSpecName(TI_CONNECTION_CONTROL_NAP_INTERVAL_SETTING, "TI Connection Control Nap Interval Setting")
            
            appSpecName(Temperature.service, "TI SensorTag Temperature Service")
            appSpecName(Temperature.data, "TI SensorTag Temperature Data")
            appSpecName(Temperature.config, "TI SensorTag Temperature Config")
            appSpecName(Temperature.period, "TI SensorTag Temperature Period")
            
            appSpecName(Accelerometer.service, "TI SensorTag Accelerometer Service")
            appSpecName(Accelerometer.data, "TI SensorTag Accelerometer Data")
            appSpecName(Accelerometer.config, "TI SensorTag Accelerometer Config")
            appSpecName(Accelerometer.period, "TI SensorTag Accelerometer Period")
            
            appSpecName(Humidity.service, "TI SensorTag Humidity Service")
            appSpecName(Humidity.data, "TI SensorTag Humidity Data")
            appSpecName(Humidity.config, "TI SensorTag Humidity Config")
            appSpecName(Humidity.period, "TI SensorTag Humidity Period")
            
            appSpecName(Magnetometer.service, "TI SensorTag Magnetometer Service")
            appSpecName(Magnetometer.data, "TI SensorTag Magnetometer Data")
            appSpecName(Magnetometer.config, "TI SensorTag Magnetometer Config")
            appSpecName(Magnetometer.period, "TI SensorTag Magnetometer Period")
            
            appSpecName(Barometer.service, "TI SensorTag Barometer Service")
            appSpecName(Barometer.data, "TI SensorTag Barometer Data")
            appSpecName(Barometer.config, "TI SensorTag Barometer Config")
            appSpecName(Barometer.calibration, "TI SensorTag Barometer Calibration")
            appSpecName(Barometer.period, "TI SensorTag Barometer Period")
            
            appSpecName(Gyroscope.service, "TI SensorTag Gyroscope Service")
            
            appSpecName(Gyroscope.data, "TI SensorTag Gyroscope Data")
            appSpecName(Gyroscope.config, "TI SensorTag Gyroscope Config")
            appSpecName(Gyroscope.period, "TI SensorTag Gyroscope Period")
            
            appSpecName(Services.io, "TI SensorTag IO Service")
            appSpecName(IO_DATA, "TI SensorTag IO Data")
            appSpecName(IO_CONFIG, "TI SensorTag IO Config")
            
            appSpecName(Light.service, "TI SensorTag Light Sensor Service")
            appSpecName(Light.data, "TI SensorTag Light Sensor Data")
            appSpecName(Light.config, "TI SensorTag Light Sensor Config")
            appSpecName(Light.period, "TI SensorTag Light Sensor Period")
            
            appSpecName(Movement.service, "TI SensorTag Movement Service")
            appSpecName(Movement.data, "TI SensorTag Movement Data")
            appSpecName(Movement.config, "TI SensorTag Movement Config")
            appSpecName(Movement.period, "TI SensorTag Movement Period")
            
            appSpecName(Services.register2, "TI SensorTag Register Service")
            appSpecName(TWO_REGISTER_DATA, "TI SensorTag Register Data")
            appSpecName(TWO_REGISTER_ADDRESS, "TI SensorTag Register Address")
            appSpecName(TWO_REGISTER_DEVICE_ID, "TI SensorTag Register Device ID")
            
            appSpecName(Services.display, "TI SensorTag Display Service")
            appSpecName(TWO_DISPLAY_DATA, "TI SensorTag Display Data")
            appSpecName(TWO_DISPLAY_CONTROL, "TI SensorTag Display Control")
        }
    }
//}




public protocol TiSensorTagSession: UUPeripheralSession
{
    func readTemperature(_ completion: @escaping UUPeripheralSessionObjectErrorCallback<UInt8>)
}

public extension TiSensorTagSession // Async
{
    func readTemperature() async -> Result<UInt8, Error>
    {
        await withCheckedContinuation
        { continuation in
            self.readTemperature
            { session, keyState, error in
                
                if let err = error
                {
                    continuation.resume(returning: .failure(err))
                }
                else if let result = keyState
                {
                    continuation.resume(returning: .success(result))
                }
                else
                {
                    continuation.resume(returning: .failure(NSError(domain: "TiSensorTagSession", code: -1)))
                }
            }
        }
    }
}



public class TiSensorTagCoreBluetoothSession: UUCoreBluetoothPeripheralSession, TiSensorTagSession
{
    public required init(peripheral: UUPeripheral)
    {
        super.init(peripheral: peripheral)
    }
    
    public override func finishSessionStart(_ completion: @escaping () -> Void)
    {
        setupKeysService
        {
            //self.setupGyroscopeService
            //{
                self.setupHumidityService
                {   
                    self.setupTemperatureService
                    {
                        
                        self.setupMovementService
                        {
                            
                            self.setupBarometerService
                            {
                                
                                //self.setupMagnometerService
                                //{
                                    //self.setupAccelerometerService
                                    //{
                                        
                                        completion()
                                    //}
                                //}
                            }
                        }
                    }
                }
            //}
        }
    }
    
    public func readTemperature(_ completion: @escaping UUPeripheralSessionObjectErrorCallback<UInt8>)
    {
        readUInt8(from: TiSensorTag.Temperature.data, completion: completion)
    }
    
    
    private func setupKeysService(_ completion: @escaping ()->Void)
    {
        startListeningForDataChanges(
            from: TiSensorTag.Keys.data,
            dataChanged: handleKeysDataChanged, completion: completion,
            errorHandler: { error in
                
                // Don't end the session if the keys data char is not available
                return true
            })
    }
    
    private func setupGyroscopeService(_ completion: @escaping ()->Void)
    {
        writeConfiguration(
            TiSensorTag.Gyroscope.config,
            TiSensorTag.Gyroscope.period,
            TiSensorTag.Gyroscope.data,
            UInt8(1),
            UInt8(10),
            self.handleGryoscopeDataChanged,
            completion)
    }
    
    private func setupAccelerometerService(_ completion: @escaping ()->Void)
    {
        writeConfiguration(
            TiSensorTag.Accelerometer.config,
            TiSensorTag.Accelerometer.period,
            TiSensorTag.Accelerometer.data,
            UInt8(1),
            UInt8(10),
            self.handleAccelerometerDataChanged,
            completion)
    }
    
    private func setupTemperatureService(_ completion: @escaping ()->Void)
    {
        write(integer: UInt8(1), to: TiSensorTag.Temperature.config, withResponse: true)
        {
            self.startListeningForDataChanges(
                from: TiSensorTag.Temperature.data,
                dataChanged: self.handleTemperatureDataChanged,
                completion: completion,
                errorHandler:
                { error in
                    
                    return false
                })
        }
        
        /*
        writeConfiguration(
            TiSensorTag.Temperature.config,
            TiSensorTag.Temperature.period,
            TiSensorTag.Temperature.data,
            UInt8(1),
            UInt8(10),
            self.handleTemperatureDataChanged,
            completion)*/
    }
    
    private func setupMovementService(_ completion: @escaping ()->Void)
    {
        writeConfiguration(
            TiSensorTag.Movement.config,
            TiSensorTag.Movement.period,
            TiSensorTag.Movement.data,
            UInt16(0x00FF),
            UInt8(10),
            self.handleMovementDataChanged,
            completion)
    }
    
    private func setupBarometerService(_ completion: @escaping ()->Void)
    {
        writeConfiguration(
            TiSensorTag.Barometer.config,
            TiSensorTag.Barometer.period,
            TiSensorTag.Barometer.data,
            UInt8(1),
            UInt8(10),
            self.handleBarometerDataChanged,
            completion)
    }
    
    private func setupHumidityService(_ completion: @escaping ()->Void)
    {
        writeConfiguration(
            TiSensorTag.Humidity.config,
            TiSensorTag.Humidity.period,
            TiSensorTag.Humidity.data,
            UInt8(1),
            UInt8(10),
            self.handleHumidityDataChanged,
            completion)
    }
    
    private func setupMagnometerService(_ completion: @escaping ()->Void)
    {
        writeConfiguration(
            TiSensorTag.Magnetometer.config,
            TiSensorTag.Magnetometer.period,
            TiSensorTag.Magnetometer.data,
            UInt8(1),
            UInt8(10),
            self.handleMagnetometerDataChanged,
            completion)
    }
    
//    #define PERIOD_MIN 100
//    #define PERIOD_MAX 2550
//
    private func writeConfiguration(
        _ configCharacteristic: CBUUID,
        _ periodCharacteristic: CBUUID,
        _ dataCharacteristic: CBUUID,
        _ configValue: any FixedWidthInteger,
        _ periodValue: any FixedWidthInteger,
        _ dataChanged: @escaping (Data?) -> Void,
        _ completion: @escaping ()->Void)
    {
        write(integer: configValue, to: configCharacteristic, withResponse: true)
        {
            self.write(integer: periodValue, to: periodCharacteristic, withResponse: true)
            {
                self.startListeningForDataChanges(
                    from: dataCharacteristic,
                    dataChanged: dataChanged,
                    completion: completion,
                    errorHandler: { error in
                        
                        return false
                    })
            }
        }
    }
    
    private func handleKeysDataChanged(_ data: Data?)
    {
        NSLog("Keys data changed: \(data?.uuToHexString() ?? "nil")")
        
    }
    
    private func handleGryoscopeDataChanged(_ data: Data?)
    {
        NSLog("Gyroscope data changed: \(data?.uuToHexString() ?? "nil")")
    }
    
    private func handleAccelerometerDataChanged(_ data: Data?)
    {
        NSLog("Accelerometer data changed: \(data?.uuToHexString() ?? "nil")")
    }
    
    private func handleTemperatureDataChanged(_ data: Data?)
    {
        NSLog("Temperature data changed: \(data?.uuToHexString() ?? "nil")")
    }
    
    private func handleMovementDataChanged(_ data: Data?)
    {
        NSLog("Movement data changed: \(data?.uuToHexString() ?? "nil")")
    }
    
    private func handleBarometerDataChanged(_ data: Data?)
    {
        NSLog("Barometer data changed: \(data?.uuToHexString() ?? "nil")")
    }
    
    private func handleHumidityDataChanged(_ data: Data?)
    {
        NSLog("Humidity data changed: \(data?.uuToHexString() ?? "nil")")
    }
    
    private func handleLightDataChanged(_ data: Data?)
    {
        NSLog("Light data changed: \(data?.uuToHexString() ?? "nil")")
    }
    
    private func handleMagnetometerDataChanged(_ data: Data?)
    {
        NSLog("Magnetometer data changed: \(data?.uuToHexString() ?? "nil")")
    }
}
