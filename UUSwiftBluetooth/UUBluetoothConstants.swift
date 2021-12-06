//
//  UUBluetoothConstants.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 12/6/21.
//

import UIKit
import CoreBluetooth

public struct UUBluetoothConstants
{
    public struct Services
    {
        /**
        * SpecificationName: Alert Notification Service
        * SpecificationType: org.bluetooth.service.alert_notification
        * AssignedNumber: 0x1811
        */
        public static let alertNotificationService = CBUUID(string: "1811")

        /**
        * SpecificationName: Automation IO
        * SpecificationType: org.bluetooth.service.automation_io
        * AssignedNumber: 0x1815
        */
        public static let automationIo = CBUUID(string: "1815")

        /**
        * SpecificationName: Battery Service
        * SpecificationType: org.bluetooth.service.battery_service
        * AssignedNumber: 0x180F
        */
        public static let batteryService = CBUUID(string: "180F")

        /**
        * SpecificationName: Blood Pressure
        * SpecificationType: org.bluetooth.service.blood_pressure
        * AssignedNumber: 0x1810
        */
        public static let bloodPressure = CBUUID(string: "1810")

        /**
        * SpecificationName: Body Composition
        * SpecificationType: org.bluetooth.service.body_composition
        * AssignedNumber: 0x181B
        */
        public static let bodyComposition = CBUUID(string: "181B")

        /**
        * SpecificationName: Bond Management
        * SpecificationType: org.bluetooth.service.bond_management
        * AssignedNumber: 0x181E
        */
        public static let bodyManagement = CBUUID(string: "181E")

        /**
        * SpecificationName: Continuous Glucose Monitoring
        * SpecificationType: org.bluetooth.service.continuous_glucose_monitoring
        * AssignedNumber: 0x181F
        */
        public static let continuousGlucoseMonitoring = CBUUID(string: "181F")

        /**
        * SpecificationName: Current Time Service
        * SpecificationType: org.bluetooth.service.current_time
        * AssignedNumber: 0x1805
        */
        public static let currentTimeService = CBUUID(string: "1805")

        /**
        * SpecificationName: Cycling Power
        * SpecificationType: org.bluetooth.service.cycling_power
        * AssignedNumber: 0x1818
        */
        public static let cyclingPower = CBUUID(string: "1818")

        /**
        * SpecificationName: Cycling Speed and Cadence
        * SpecificationType: org.bluetooth.service.cycling_speed_and_cadence
        * AssignedNumber: 0x1816
        */
        public static let cyclingSpeedAndCadence = CBUUID(string: "1816")

        /**
        * SpecificationName: Device Information
        * SpecificationType: org.bluetooth.service.device_information
        * AssignedNumber: 0x180A
        */
        public static let deviceInformation = CBUUID(string: "180A")

        /**
        * SpecificationName: Environmental Sensing
        * SpecificationType: org.bluetooth.service.environmental_sensing
        * AssignedNumber: 0x181A
        */
        public static let environmentalSensing = CBUUID(string: "181A")

        /**
        * SpecificationName: Generic Access
        * SpecificationType: org.bluetooth.service.generic_access
        * AssignedNumber: 0x1800
        */
        public static let genericAccess = CBUUID(string: "1800")

        /**
        * SpecificationName: Generic Attribute
        * SpecificationType: org.bluetooth.service.generic_attribute
        * AssignedNumber: 0x1801
        */
        public static let genericAttribute = CBUUID(string: "1801")

        /**
        * SpecificationName: Glucose
        * SpecificationType: org.bluetooth.service.glucose
        * AssignedNumber: 0x1808
        */
        public static let glucose = CBUUID(string: "1808")

        /**
        * SpecificationName: Health Thermometer
        * SpecificationType: org.bluetooth.service.health_thermometer
        * AssignedNumber: 0x1809
        */
        public static let healthThermometer = CBUUID(string: "1809")

        /**
        * SpecificationName: Heart Rate
        * SpecificationType: org.bluetooth.service.heart_rate
        * AssignedNumber: 0x180D
        */
        public static let heartRate = CBUUID(string: "180D")

        /**
        * SpecificationName: HTTP Proxy
        * SpecificationType: org.bluetooth.service.http_proxy
        * AssignedNumber: 0x1823
        */
        public static let httpProxy = CBUUID(string: "1823")

        /**
        * SpecificationName: Human Interface Device
        * SpecificationType: org.bluetooth.service.human_interface_device
        * AssignedNumber: 0x1812
        */
        public static let humanInterfaceDevice = CBUUID(string: "1812")

        /**
        * SpecificationName: Immediate Alert
        * SpecificationType: org.bluetooth.service.immediate_alert
        * AssignedNumber: 0x1802
        */
        public static let immediateAlert = CBUUID(string: "1802")

        /**
        * SpecificationName: Indoor Positioning
        * SpecificationType: org.bluetooth.service.indoor_positioning
        * AssignedNumber: 0x1821
        */
        public static let indoorPositioning = CBUUID(string: "1821")

        /**
        * SpecificationName: Internet Protocol Support
        * SpecificationType: org.bluetooth.service.internet_protocol_support
        * AssignedNumber: 0x1820
        */
        public static let internetProtocolSupport = CBUUID(string: "1820")

        /**
        * SpecificationName: Link Loss
        * SpecificationType: org.bluetooth.service.link_loss
        * AssignedNumber: 0x1803
        */
        public static let linkLoss = CBUUID(string: "1803")

        /**
        * SpecificationName: Location and Navigation
        * SpecificationType: org.bluetooth.service.location_and_navigation
        * AssignedNumber: 0x1819
        */
        public static let locationAndNavigation = CBUUID(string: "1819")

        /**
        * SpecificationName: Next DST Change Service
        * SpecificationType: org.bluetooth.service.next_dst_change
        * AssignedNumber: 0x1807
        */
        public static let nextDstChangeService = CBUUID(string: "1807")

        /**
        * SpecificationName: Object Transfer
        * SpecificationType: org.bluetooth.service.object_transfer
        * AssignedNumber: 0x1825
        */
        public static let objectTransfer = CBUUID(string: "1825")

        /**
        * SpecificationName: Phone Alert Status Service
        * SpecificationType: org.bluetooth.service.phone_alert_status
        * AssignedNumber: 0x180E
        */
        public static let phoneAlertStatusService = CBUUID(string: "180E")

        /**
        * SpecificationName: Pulse Oximeter
        * SpecificationType: org.bluetooth.service.pulse_oximeter
        * AssignedNumber: 0x1822
        */
        public static let pulseOximeter = CBUUID(string: "1822")

        /**
        * SpecificationName: Reference Time Update Service
        * SpecificationType: org.bluetooth.service.reference_time_update
        * AssignedNumber: 0x1806
        */
        public static let referenceTimeUpdateService = CBUUID(string: "1806")

        /**
        * SpecificationName: Running Speed and Cadence
        * SpecificationType: org.bluetooth.service.running_speed_and_cadence
        * AssignedNumber: 0x1814
        */
        public static let runningSpeedAndCadence = CBUUID(string: "1814")

        /**
        * SpecificationName: Scan Parameters
        * SpecificationType: org.bluetooth.service.scan_parameters
        * AssignedNumber: 0x1813
        */
        public static let scanParameters = CBUUID(string: "1813")

        /**
        * SpecificationName: Transport Discovery
        * SpecificationType: org.bluetooth.service.transport_discovery
        * AssignedNumber: 0x1824
        */
        public static let transportDiscovery = CBUUID(string: "1824")

        /**
        * SpecificationName: Tx Power
        * SpecificationType: org.bluetooth.service.tx_power
        * AssignedNumber: 0x1804
        */
        public static let txPower = CBUUID(string: "1804")

        /**
        * SpecificationName: User Data
        * SpecificationType: org.bluetooth.service.user_data
        * AssignedNumber: 0x181C
        */
        public static let userData = CBUUID(string: "181C")

        /**
        * SpecificationName: Weight Scale
        * SpecificationType: org.bluetooth.service.weight_scale
        * AssignedNumber: 0x181D
        */
        public static let weightScale = CBUUID(string: "181D")
        
    }
    
    public struct Characteristics
    {
        /**
         * SpecificationName: Aerobic Heart Rate Lower Limit
         * SpecificationType: org.bluetooth.characteristic.aerobic_heart_rate_lower_limit
         * AssignedNumber: 0x2A7E
         */
        public static let aerobicHeartRateLowerLimit = CBUUID(string: "2A7E")

        /**
         * SpecificationName: Aerobic Heart Rate Upper Limit
         * SpecificationType: org.bluetooth.characteristic.aerobic_heart_rate_upper_limit
         * AssignedNumber: 0x2A84
         */
        public static let aerobicHeartRateUpperLimit = CBUUID(string: "2A84")

        /**
         * SpecificationName: Aerobic Threshold
         * SpecificationType: org.bluetooth.characteristic.aerobic_threshold
         * AssignedNumber: 0x2A7F
         */
        public static let aerobicThreshold = CBUUID(string: "2A7F")

        /**
         * SpecificationName: Age
         * SpecificationType: org.bluetooth.characteristic.age
         * AssignedNumber: 0x2A80
         */
        public static let age = CBUUID(string: "2A80")

        /**
         * SpecificationName: Aggregate
         * SpecificationType: org.bluetooth.characteristic.aggregate
         * AssignedNumber: 0x2A5A
         */
        public static let aggregate = CBUUID(string: "2A5A")

        /**
         * SpecificationName: Alert Category ID
         * SpecificationType: org.bluetooth.characteristic.alert_category_id
         * AssignedNumber: 0x2A43
         */
        public static let alertCategoryID = CBUUID(string: "2A43")

        /**
         * SpecificationName: Alert Category ID Bit Mask
         * SpecificationType: org.bluetooth.characteristic.alert_category_id_bit_mask
         * AssignedNumber: 0x2A42
         */
        public static let alertCategoryIdBitMask = CBUUID(string: "2A42")

        /**
         * SpecificationName: Alert Level
         * SpecificationType: org.bluetooth.characteristic.alert_level
         * AssignedNumber: 0x2A06
         */
        public static let alertLevel = CBUUID(string: "2A06")

        /**
         * SpecificationName: Alert Notification Control Point
         * SpecificationType: org.bluetooth.characteristic.alert_notification_control_point
         * AssignedNumber: 0x2A44
         */
        public static let alertNotificationControlPoint = CBUUID(string: "2A44")

        /**
         * SpecificationName: Alert Status
         * SpecificationType: org.bluetooth.characteristic.alert_status
         * AssignedNumber: 0x2A3F
         */
        public static let alertStatus = CBUUID(string: "2A3F")

        /**
         * SpecificationName: Altitude
         * SpecificationType: org.bluetooth.characteristic.altitude
         * AssignedNumber: 0x2AB3
         */
        public static let altitude = CBUUID(string: "2AB3")

        /**
         * SpecificationName: Anaerobic Heart Rate Lower Limit
         * SpecificationType: org.bluetooth.characteristic.anaerobic_heart_rate_lower_limit
         * AssignedNumber: 0x2A81
         */
        public static let anaerobicHeartRateLowerLimit = CBUUID(string: "2A81")

        /**
         * SpecificationName: Anaerobic Heart Rate Upper Limit
         * SpecificationType: org.bluetooth.characteristic.anaerobic_heart_rate_upper_limit
         * AssignedNumber: 0x2A82
         */
        public static let anaerobicHeartRateUpperLimit = CBUUID(string: "2A82")

        /**
         * SpecificationName: Anaerobic Threshold
         * SpecificationType: org.bluetooth.characteristic.anaerobic_threshold
         * AssignedNumber: 0x2A83
         */
        public static let anaerobicThreshold = CBUUID(string: "2A83")

        /**
         * SpecificationName: Analog
         * SpecificationType: org.bluetooth.characteristic.analog
         * AssignedNumber: 0x2A58
         */
        public static let analog = CBUUID(string: "2A58")

        /**
         * SpecificationName: Apparent Wind Direction
         * SpecificationType: org.bluetooth.characteristic.apparent_wind_direction
         * AssignedNumber: 0x2A73
         */
        public static let apparentWindDirection = CBUUID(string: "2A73")

        /**
         * SpecificationName: Apparent Wind Speed
         * SpecificationType: org.bluetooth.characteristic.apparent_wind_speed
         * AssignedNumber: 0x2A72
         */
        public static let apparentWindSpeed = CBUUID(string: "2A72")

        /**
         * SpecificationName: Appearance
         * SpecificationType: org.bluetooth.characteristic.gap.appearance
         * AssignedNumber: 0x2A01
         */
        public static let appearance = CBUUID(string: "2A01")

        /**
         * SpecificationName: Barometric Pressure Trend
         * SpecificationType: org.bluetooth.characteristic.barometric_pressure_trend
         * AssignedNumber: 0x2AA3
         */
        public static let barometricPressureTrend = CBUUID(string: "2AA3")

        /**
         * SpecificationName: Battery Level
         * SpecificationType: org.bluetooth.characteristic.battery_level
         * AssignedNumber: 0x2A19
         */
        public static let batteryLevel = CBUUID(string: "2A19")

        /**
         * SpecificationName: Blood Pressure Feature
         * SpecificationType: org.bluetooth.characteristic.blood_pressure_feature
         * AssignedNumber: 0x2A49
         */
        public static let bloodPressureFeature = CBUUID(string: "2A49")

        /**
         * SpecificationName: Blood Pressure Measurement
         * SpecificationType: org.bluetooth.characteristic.blood_pressure_measurement
         * AssignedNumber: 0x2A35
         */
        public static let bloodPressureMeasurement = CBUUID(string: "2A35")

        /**
         * SpecificationName: Body Composition Feature
         * SpecificationType: org.bluetooth.characteristic.body_composition_feature
         * AssignedNumber: 0x2A9B
         */
        public static let bodyCompositionFeature = CBUUID(string: "2A9B")

        /**
         * SpecificationName: Body Composition Measurement
         * SpecificationType: org.bluetooth.characteristic.body_composition_measurement
         * AssignedNumber: 0x2A9C
         */
        public static let bodyCompositionMeasurement = CBUUID(string: "2A9C")

        /**
         * SpecificationName: Body Sensor Location
         * SpecificationType: org.bluetooth.characteristic.body_sensor_location
         * AssignedNumber: 0x2A38
         */
        public static let bodySensorLocation = CBUUID(string: "2A38")

        /**
         * SpecificationName: Bond Management Control Point
         * SpecificationType: org.bluetooth.characteristic.bond_management_control_point
         * AssignedNumber: 0x2AA4
         */
        public static let bondManagementControlPoint = CBUUID(string: "2AA4")

        /**
         * SpecificationName: Bond Management Feature
         * SpecificationType: org.bluetooth.characteristic.bond_management_feature
         * AssignedNumber: 0x2AA5
         */
        public static let bondManagementFeature = CBUUID(string: "2AA5")

        /**
         * SpecificationName: Boot Keyboard Input Report
         * SpecificationType: org.bluetooth.characteristic.boot_keyboard_input_report
         * AssignedNumber: 0x2A22
         */
        public static let bootKeyboardInputReport = CBUUID(string: "2A22")

        /**
         * SpecificationName: Boot Keyboard Output Report
         * SpecificationType: org.bluetooth.characteristic.boot_keyboard_output_report
         * AssignedNumber: 0x2A32
         */
        public static let bootKeyboardOutputReport = CBUUID(string: "2A32")

        /**
         * SpecificationName: Boot Mouse Input Report
         * SpecificationType: org.bluetooth.characteristic.boot_mouse_input_report
         * AssignedNumber: 0x2A33
         */
        public static let bootMouseInputReport = CBUUID(string: "2A33")

        /**
         * SpecificationName: Central Address Resolution
         * SpecificationType: org.bluetooth.characteristic.gap.central_address_resolution_support
         * AssignedNumber: 0x2AA6
         */
        public static let centralAddressResolution = CBUUID(string: "2AA6")

        /**
         * SpecificationName: CGM Feature
         * SpecificationType: org.bluetooth.characteristic.cgm_feature
         * AssignedNumber: 0x2AA8
         */
        public static let cgmFeature = CBUUID(string: "2AA8")

        /**
         * SpecificationName: CGM Measurement
         * SpecificationType: org.bluetooth.characteristic.cgm_measurement
         * AssignedNumber: 0x2AA7
         */
        public static let cgmMeasurement = CBUUID(string: "2AA7")

        /**
         * SpecificationName: CGM Session Run Time
         * SpecificationType: org.bluetooth.characteristic.cgm_session_run_time
         * AssignedNumber: 0x2AAB
         */
        public static let cgmSessionRunTime = CBUUID(string: "2AAB")

        /**
         * SpecificationName: CGM Session Start Time
         * SpecificationType: org.bluetooth.characteristic.cgm_session_start_time
         * AssignedNumber: 0x2AAA
         */
        public static let cgmSessionStartTime = CBUUID(string: "2AAA")

        /**
         * SpecificationName: CGM Specific Ops Control Point
         * SpecificationType: org.bluetooth.characteristic.cgm_specific_ops_control_point
         * AssignedNumber: 0x2AAC
         */
        public static let cgmSpecificOpsControlPoint = CBUUID(string: "2AAC")

        /**
         * SpecificationName: CGM Status
         * SpecificationType: org.bluetooth.characteristic.cgm_status
         * AssignedNumber: 0x2AA9
         */
        public static let cgmStatus = CBUUID(string: "2AA9")

        /**
         * SpecificationName: CSC Feature
         * SpecificationType: org.bluetooth.characteristic.csc_feature
         * AssignedNumber: 0x2A5C
         */
        public static let cscFeature = CBUUID(string: "2A5C")

        /**
         * SpecificationName: CSC Measurement
         * SpecificationType: org.bluetooth.characteristic.csc_measurement
         * AssignedNumber: 0x2A5B
         */
        public static let cscMeasurement = CBUUID(string: "2A5B")

        /**
         * SpecificationName: Current Time
         * SpecificationType: org.bluetooth.characteristic.current_time
         * AssignedNumber: 0x2A2B
         */
        public static let currentTime = CBUUID(string: "2A2B")

        /**
         * SpecificationName: Cycling Power Control Point
         * SpecificationType: org.bluetooth.characteristic.cycling_power_control_point
         * AssignedNumber: 0x2A66
         */
        public static let cyclingPowerControlPoint = CBUUID(string: "2A66")

        /**
         * SpecificationName: Cycling Power Feature
         * SpecificationType: org.bluetooth.characteristic.cycling_power_feature
         * AssignedNumber: 0x2A65
         */
        public static let cyclingPowerFeature = CBUUID(string: "2A65")

        /**
         * SpecificationName: Cycling Power Measurement
         * SpecificationType: org.bluetooth.characteristic.cycling_power_measurement
         * AssignedNumber: 0x2A63
         */
        public static let cyclingPowerMeasurement = CBUUID(string: "2A63")

        /**
         * SpecificationName: Cycling Power Vector
         * SpecificationType: org.bluetooth.characteristic.cycling_power_vector
         * AssignedNumber: 0x2A64
         */
        public static let cyclingPowerVector = CBUUID(string: "2A64")

        /**
         * SpecificationName: Database Change Increment
         * SpecificationType: org.bluetooth.characteristic.database_change_increment
         * AssignedNumber: 0x2A99
         */
        public static let databaseChangeIncrement = CBUUID(string: "2A99")

        /**
         * SpecificationName: Date of Birth
         * SpecificationType: org.bluetooth.characteristic.date_of_birth
         * AssignedNumber: 0x2A85
         */
        public static let dateOfBirth = CBUUID(string: "2A85")

        /**
         * SpecificationName: Date of Threshold Assessment
         * SpecificationType: org.bluetooth.characteristic.date_of_threshold_assessment
         * AssignedNumber: 0x2A86
         */
        public static let dateOfThresholdAssessment = CBUUID(string: "2A86")

        /**
         * SpecificationName: Date Time
         * SpecificationType: org.bluetooth.characteristic.date_time
         * AssignedNumber: 0x2A08
         */
        public static let dateTime = CBUUID(string: "2A08")

        /**
         * SpecificationName: Day Date Time
         * SpecificationType: org.bluetooth.characteristic.day_date_time
         * AssignedNumber: 0x2A0A
         */
        public static let dayDateTime = CBUUID(string: "2A0A")

        /**
         * SpecificationName: Day of Week
         * SpecificationType: org.bluetooth.characteristic.day_of_week
         * AssignedNumber: 0x2A09
         */
        public static let dayOfWeek = CBUUID(string: "2A09")

        /**
         * SpecificationName: Descriptor Value Changed
         * SpecificationType: org.bluetooth.characteristic.descriptor_value_changed
         * AssignedNumber: 0x2A7D
         */
        public static let descriptorValueChanged = CBUUID(string: "2A7D")

        /**
         * SpecificationName: Device Name
         * SpecificationType: org.bluetooth.characteristic.gap.device_name
         * AssignedNumber: 0x2A00
         */
        public static let deviceName = CBUUID(string: "2A00")

        /**
         * SpecificationName: Dew Point
         * SpecificationType: org.bluetooth.characteristic.dew_point
         * AssignedNumber: 0x2A7B
         */
        public static let dewPoint = CBUUID(string: "2A7B")

        /**
         * SpecificationName: Digital
         * SpecificationType: org.bluetooth.characteristic.digital
         * AssignedNumber: 0x2A56
         */
        public static let digital = CBUUID(string: "2A56")

        /**
         * SpecificationName: DST Offset
         * SpecificationType: org.bluetooth.characteristic.dst_offset
         * AssignedNumber: 0x2A0D
         */
        public static let dstOffset = CBUUID(string: "2A0D")

        /**
         * SpecificationName: Elevation
         * SpecificationType: org.bluetooth.characteristic.elevation
         * AssignedNumber: 0x2A6C
         */
        public static let elevation = CBUUID(string: "2A6C")

        /**
         * SpecificationName: Email Address
         * SpecificationType: org.bluetooth.characteristic.email_address
         * AssignedNumber: 0x2A87
         */
        public static let emailAddress = CBUUID(string: "2A87")

        /**
         * SpecificationName: Exact Time 256
         * SpecificationType: org.bluetooth.characteristic.exact_time_256
         * AssignedNumber: 0x2A0C
         */
        public static let exactTime256 = CBUUID(string: "2A0C")

        /**
         * SpecificationName: Fat Burn Heart Rate Lower Limit
         * SpecificationType: org.bluetooth.characteristic.fat_burn_heart_rate_lower_limit
         * AssignedNumber: 0x2A88
         */
        public static let fatBurnHeartRateLowerLimit = CBUUID(string: "2A88")

        /**
         * SpecificationName: Fat Burn Heart Rate Upper Limit
         * SpecificationType: org.bluetooth.characteristic.fat_burn_heart_rate_upper_limit
         * AssignedNumber: 0x2A89
         */
        public static let fatBurnHeartRateUpperLimit = CBUUID(string: "2A89")

        /**
         * SpecificationName: Firmware Revision String
         * SpecificationType: org.bluetooth.characteristic.firmware_revision_string
         * AssignedNumber: 0x2A26
         */
        public static let firmwareRevisionString = CBUUID(string: "2A26")

        /**
         * SpecificationName: First Name
         * SpecificationType: org.bluetooth.characteristic.first_name
         * AssignedNumber: 0x2A8A
         */
        public static let firstName = CBUUID(string: "2A8A")

        /**
         * SpecificationName: Five Zone Heart Rate Limits
         * SpecificationType: org.bluetooth.characteristic.five_zone_heart_rate_limits
         * AssignedNumber: 0x2A8B
         */
        public static let fiveZoneHeartRateLimits = CBUUID(string: "2A8B")

        /**
         * SpecificationName: Floor Number
         * SpecificationType: org.bluetooth.characteristic.floor_number
         * AssignedNumber: 0x2AB2
         */
        public static let floorNumber = CBUUID(string: "2AB2")

        /**
         * SpecificationName: Gender
         * SpecificationType: org.bluetooth.characteristic.gender
         * AssignedNumber: 0x2A8C
         */
        public static let gender = CBUUID(string: "2A8C")

        /**
         * SpecificationName: Glucose Feature
         * SpecificationType: org.bluetooth.characteristic.glucose_feature
         * AssignedNumber: 0x2A51
         */
        public static let glucoseFeature = CBUUID(string: "2A51")

        /**
         * SpecificationName: Glucose Measurement
         * SpecificationType: org.bluetooth.characteristic.glucose_measurement
         * AssignedNumber: 0x2A18
         */
        public static let glucoseMeasurement = CBUUID(string: "2A18")

        /**
         * SpecificationName: Glucose Measurement Context
         * SpecificationType: org.bluetooth.characteristic.glucose_measurement_context
         * AssignedNumber: 0x2A34
         */
        public static let glucoseMeasurementContext = CBUUID(string: "2A34")

        /**
         * SpecificationName: Gust Factor
         * SpecificationType: org.bluetooth.characteristic.gust_factor
         * AssignedNumber: 0x2A74
         */
        public static let gustFactor = CBUUID(string: "2A74")

        /**
         * SpecificationName: Hardware Revision String
         * SpecificationType: org.bluetooth.characteristic.hardware_revision_string
         * AssignedNumber: 0x2A27
         */
        public static let hardwareRevisionString = CBUUID(string: "2A27")

        /**
         * SpecificationName: Heart Rate Control Point
         * SpecificationType: org.bluetooth.characteristic.heart_rate_control_point
         * AssignedNumber: 0x2A39
         */
        public static let heartRateControlPoint = CBUUID(string: "2A39")

        /**
         * SpecificationName: Heart Rate Max
         * SpecificationType: org.bluetooth.characteristic.heart_rate_max
         * AssignedNumber: 0x2A8D
         */
        public static let heartRateMax = CBUUID(string: "2A8D")

        /**
         * SpecificationName: Heart Rate Measurement
         * SpecificationType: org.bluetooth.characteristic.heart_rate_measurement
         * AssignedNumber: 0x2A37
         */
        public static let heartRateMeasurement = CBUUID(string: "2A37")

        /**
         * SpecificationName: Heat Index
         * SpecificationType: org.bluetooth.characteristic.heat_index
         * AssignedNumber: 0x2A7A
         */
        public static let heatIndex = CBUUID(string: "2A7A")

        /**
         * SpecificationName: Height
         * SpecificationType: org.bluetooth.characteristic.height
         * AssignedNumber: 0x2A8E
         */
        public static let height = CBUUID(string: "2A8E")

        /**
         * SpecificationName: HID Control Point
         * SpecificationType: org.bluetooth.characteristic.hid_control_point
         * AssignedNumber: 0x2A4C
         */
        public static let hidControlPoint = CBUUID(string: "2A4C")

        /**
         * SpecificationName: HID Information
         * SpecificationType: org.bluetooth.characteristic.hid_information
         * AssignedNumber: 0x2A4A
         */
        public static let hidInformation = CBUUID(string: "2A4A")

        /**
         * SpecificationName: Hip Circumference
         * SpecificationType: org.bluetooth.characteristic.hip_circumference
         * AssignedNumber: 0x2A8F
         */
        public static let hipCircumference = CBUUID(string: "2A8F")

        /**
         * SpecificationName: HTTP Control Point
         * SpecificationType: org.bluetooth.characteristic.http_control_point
         * AssignedNumber: 0x2ABA
         */
        public static let httpControlPoint = CBUUID(string: "2ABA")

        /**
         * SpecificationName: HTTP Entity Body
         * SpecificationType: org.bluetooth.characteristic.http_entity_body
         * AssignedNumber: 0x2AB9
         */
        public static let httpEntityBody = CBUUID(string: "2AB9")

        /**
         * SpecificationName: HTTP Headers
         * SpecificationType: org.bluetooth.characteristic.http_headers
         * AssignedNumber: 0x2AB7
         */
        public static let httpHeaders = CBUUID(string: "2AB7")

        /**
         * SpecificationName: HTTP Status Code
         * SpecificationType: org.bluetooth.characteristic.http_status_code
         * AssignedNumber: 0x2AB8
         */
        public static let httpStatusCode = CBUUID(string: "2AB8")

        /**
         * SpecificationName: HTTPS Security
         * SpecificationType: org.bluetooth.characteristic.https_security
         * AssignedNumber: 0x2ABB
         */
        public static let httpsSecurity = CBUUID(string: "2ABB")

        /**
         * SpecificationName: Humidity
         * SpecificationType: org.bluetooth.characteristic.humidity
         * AssignedNumber: 0x2A6F
         */
        public static let humidity = CBUUID(string: "2A6F")

        /**
         * SpecificationName: IEEE 11073-20601 Regulatory Certification Data List
         * SpecificationType: org.bluetooth.characteristic.ieee_11073-20601_regulatory_certification_data_list
         * AssignedNumber: 0x2A2A
         */
        public static let ieee11073_20601RegulatoryCertificationDataList = CBUUID(string: "2A2A")

        /**
         * SpecificationName: Indoor Positioning Configuration
         * SpecificationType: org.bluetooth.characteristic.indoor_positioning_configuration
         * AssignedNumber: 0x2AAD
         */
        public static let indoorPositioningConfiguration = CBUUID(string: "2AAD")

        /**
         * SpecificationName: Intermediate Cuff Pressure
         * SpecificationType: org.bluetooth.characteristic.intermediate_cuff_pressure
         * AssignedNumber: 0x2A36
         */
        public static let intermediateCuffPressure = CBUUID(string: "2A36")

        /**
         * SpecificationName: Intermediate Temperature
         * SpecificationType: org.bluetooth.characteristic.intermediate_temperature
         * AssignedNumber: 0x2A1E
         */
        public static let intermediateTemperature = CBUUID(string: "2A1E")

        /**
         * SpecificationName: Irradiance
         * SpecificationType: org.bluetooth.characteristic.irradiance
         * AssignedNumber: 0x2A77
         */
        public static let irradiance = CBUUID(string: "2A77")

        /**
         * SpecificationName: Language
         * SpecificationType: org.bluetooth.characteristic.language
         * AssignedNumber: 0x2AA2
         */
        public static let language = CBUUID(string: "2AA2")

        /**
         * SpecificationName: Last Name
         * SpecificationType: org.bluetooth.characteristic.last_name
         * AssignedNumber: 0x2A90
         */
        public static let lastName = CBUUID(string: "2A90")

        /**
         * SpecificationName: Latitude
         * SpecificationType: org.bluetooth.characteristic.latitude
         * AssignedNumber: 0x2AAE
         */
        public static let latitude = CBUUID(string: "2AAE")

        /**
         * SpecificationName: LN Control Point
         * SpecificationType: org.bluetooth.characteristic.ln_control_point
         * AssignedNumber: 0x2A6B
         */
        public static let lnControlPoint = CBUUID(string: "2A6B")

        /**
         * SpecificationName: LN Feature
         * SpecificationType: org.bluetooth.characteristic.ln_feature
         * AssignedNumber: 0x2A6A
         */
        public static let lnFeature = CBUUID(string: "2A6A")

        /**
         * SpecificationName: Local East Coordinate
         * SpecificationType: org.bluetooth.characteristic.local_east_coordinate
         * AssignedNumber: 0x2AB1
         */
        public static let localEastCoordinate = CBUUID(string: "2AB1")

        /**
         * SpecificationName: Local North Coordinate
         * SpecificationType: org.bluetooth.characteristic.local_north_coordinate
         * AssignedNumber: 0x2AB0
         */
        public static let localNorthCoordinate = CBUUID(string: "2AB0")

        /**
         * SpecificationName: Local Time Information
         * SpecificationType: org.bluetooth.characteristic.local_time_information
         * AssignedNumber: 0x2A0F
         */
        public static let localTimeInformation = CBUUID(string: "2A0F")

        /**
         * SpecificationName: Location and Speed
         * SpecificationType: org.bluetooth.characteristic.location_and_speed
         * AssignedNumber: 0x2A67
         */
        public static let locationAndSpeed = CBUUID(string: "2A67")

        /**
         * SpecificationName: Location Name
         * SpecificationType: org.bluetooth.characteristic.location_name
         * AssignedNumber: 0x2AB5
         */
        public static let locationName = CBUUID(string: "2AB5")

        /**
         * SpecificationName: Longitude
         * SpecificationType: org.bluetooth.characteristic.longitude
         * AssignedNumber: 0x2AAF
         */
        public static let longitude = CBUUID(string: "2AAF")

        /**
         * SpecificationName: Magnetic Declination
         * SpecificationType: org.bluetooth.characteristic.magnetic_declination
         * AssignedNumber: 0x2A2C
         */
        public static let magneticDeclination = CBUUID(string: "2A2C")

        /**
         * SpecificationName: Magnetic Flux Density - 2D
         * SpecificationType: org.bluetooth.characteristic.magnetic_flux_density_2D
         * AssignedNumber: 0x2AA0
         */
        public static let magneticFluxDensity2D = CBUUID(string: "2AA0")

        /**
         * SpecificationName: Magnetic Flux Density - 3D
         * SpecificationType: org.bluetooth.characteristic.magnetic_flux_density_3D
         * AssignedNumber: 0x2AA1
         */
        public static let magneticFluxDensity3D = CBUUID(string: "2AA1")

        /**
         * SpecificationName: Manufacturer Name String
         * SpecificationType: org.bluetooth.characteristic.manufacturer_name_string
         * AssignedNumber: 0x2A29
         */
        public static let manufacturerNameString = CBUUID(string: "2A29")

        /**
         * SpecificationName: Maximum Recommended Heart Rate
         * SpecificationType: org.bluetooth.characteristic.maximum_recommended_heart_rate
         * AssignedNumber: 0x2A91
         */
        public static let maximumRecommendedHeartRate = CBUUID(string: "2A91")

        /**
         * SpecificationName: Measurement Interval
         * SpecificationType: org.bluetooth.characteristic.measurement_interval
         * AssignedNumber: 0x2A21
         */
        public static let measurementInterval = CBUUID(string: "2A21")

        /**
         * SpecificationName: Model Number String
         * SpecificationType: org.bluetooth.characteristic.model_number_string
         * AssignedNumber: 0x2A24
         */
        public static let modelNumberString = CBUUID(string: "2A24")

        /**
         * SpecificationName: Navigation
         * SpecificationType: org.bluetooth.characteristic.navigation
         * AssignedNumber: 0x2A68
         */
        public static let navigation = CBUUID(string: "2A68")

        /**
         * SpecificationName: New Alert
         * SpecificationType: org.bluetooth.characteristic.new_alert
         * AssignedNumber: 0x2A46
         */
        public static let newAlert = CBUUID(string: "2A46")

        /**
         * SpecificationName: Object Action Control Point
         * SpecificationType: org.bluetooth.characteristic.object_action_control_point
         * AssignedNumber: 0x2AC5
         */
        public static let objectActionControlPoint = CBUUID(string: "2AC5")

        /**
         * SpecificationName: Object Changed
         * SpecificationType: org.bluetooth.characteristic.object_changed
         * AssignedNumber: 0x2AC8
         */
        public static let objectChanged = CBUUID(string: "2AC8")

        /**
         * SpecificationName: Object First-Created
         * SpecificationType: org.bluetooth.characteristic.object_first_created
         * AssignedNumber: 0x2AC1
         */
        public static let objectFirstCreated = CBUUID(string: "2AC1")

        /**
         * SpecificationName: Object ID
         * SpecificationType: org.bluetooth.characteristic.object_id
         * AssignedNumber: 0x2AC3
         */
        public static let objectID = CBUUID(string: "2AC3")

        /**
         * SpecificationName: Object Last-Modified
         * SpecificationType: org.bluetooth.characteristic.object_last_modified
         * AssignedNumber: 0x2AC2
         */
        public static let objectLastModified = CBUUID(string: "2AC2")

        /**
         * SpecificationName: Object List Control Point
         * SpecificationType: org.bluetooth.characteristic.object_list_control_point
         * AssignedNumber: 0x2AC6
         */
        public static let objectListControlPoint = CBUUID(string: "2AC6")

        /**
         * SpecificationName: Object List Filter
         * SpecificationType: org.bluetooth.characteristic.object_list_filter
         * AssignedNumber: 0x2AC7
         */
        public static let objectListFilter = CBUUID(string: "2AC7")

        /**
         * SpecificationName: Object Name
         * SpecificationType: org.bluetooth.characteristic.object_name
         * AssignedNumber: 0x2ABE
         */
        public static let objectName = CBUUID(string: "2ABE")

        /**
         * SpecificationName: Object Properties
         * SpecificationType: org.bluetooth.characteristic.object_properties
         * AssignedNumber: 0x2AC4
         */
        public static let objectProperties = CBUUID(string: "2AC4")

        /**
         * SpecificationName: Object Size
         * SpecificationType: org.bluetooth.characteristic.object_size
         * AssignedNumber: 0x2AC0
         */
        public static let objectSize = CBUUID(string: "2AC0")

        /**
         * SpecificationName: Object Type
         * SpecificationType: org.bluetooth.characteristic.object_type
         * AssignedNumber: 0x2ABF
         */
        public static let objectType = CBUUID(string: "2ABF")

        /**
         * SpecificationName: OTS Feature
         * SpecificationType: org.bluetooth.characteristic.ots_feature
         * AssignedNumber: 0x2ABD
         */
        public static let otsFeature = CBUUID(string: "2ABD")

        /**
         * SpecificationName: Peripheral Preferred Connection Parameters
         * SpecificationType: org.bluetooth.characteristic.gap.peripheral_preferred_connection_parameters
         * AssignedNumber: 0x2A04
         */
        public static let peripheralPreferredConnectionParameters = CBUUID(string: "2A04")

        /**
         * SpecificationName: Peripheral Privacy Flag
         * SpecificationType: org.bluetooth.characteristic.gap.peripheral_privacy_flag
         * AssignedNumber: 0x2A02
         */
        public static let peripheralPrivacyFlag = CBUUID(string: "2A02")

        /**
         * SpecificationName: PLX Continuous Measurement
         * SpecificationType: org.bluetooth.characteristic.plx_continuous_measurement
         * AssignedNumber: 0x2A5F
         */
        public static let plxContinuousMeasurement = CBUUID(string: "2A5F")

        /**
         * SpecificationName: PLX Features
         * SpecificationType: org.bluetooth.characteristic.plx_features
         * AssignedNumber: 0x2A60
         */
        public static let plxFeatures = CBUUID(string: "2A60")

        /**
         * SpecificationName: PLX Spot-Check Measurement
         * SpecificationType: org.bluetooth.characteristic.plx_spot_check_measurement
         * AssignedNumber: 0x2A5E
         */
        public static let plxSpotCheckMeasurement = CBUUID(string: "2A5E")

        /**
         * SpecificationName: PnP ID
         * SpecificationType: org.bluetooth.characteristic.pnp_id
         * AssignedNumber: 0x2A50
         */
        public static let PNP_ID_UUID = CBUUID(string: "2A50")

        /**
         * SpecificationName: Pollen Concentration
         * SpecificationType: org.bluetooth.characteristic.pollen_concentration
         * AssignedNumber: 0x2A75
         */
        public static let pnpID = CBUUID(string: "2A75")

        /**
         * SpecificationName: Position Quality
         * SpecificationType: org.bluetooth.characteristic.position_quality
         * AssignedNumber: 0x2A69
         */
        public static let positionQuality = CBUUID(string: "2A69")

        /**
         * SpecificationName: Pressure
         * SpecificationType: org.bluetooth.characteristic.pressure
         * AssignedNumber: 0x2A6D
         */
        public static let pressure = CBUUID(string: "2A6D")

        /**
         * SpecificationName: Protocol Mode
         * SpecificationType: org.bluetooth.characteristic.protocol_mode
         * AssignedNumber: 0x2A4E
         */
        public static let protocolMode = CBUUID(string: "2A4E")

        /**
         * SpecificationName: Rainfall
         * SpecificationType: org.bluetooth.characteristic.rainfall
         * AssignedNumber: 0x2A78
         */
        public static let rainfall = CBUUID(string: "2A78")

        /**
         * SpecificationName: Reconnection Address
         * SpecificationType: org.bluetooth.characteristic.gap.reconnection_address
         * AssignedNumber: 0x2A03
         */
        public static let reconnectionAddress = CBUUID(string: "2A03")

        /**
         * SpecificationName: Record Access Control Point
         * SpecificationType: org.bluetooth.characteristic.record_access_control_point
         * AssignedNumber: 0x2A52
         */
        public static let recordAccessControlPoint = CBUUID(string: "2A52")

        /**
         * SpecificationName: Reference Time Information
         * SpecificationType: org.bluetooth.characteristic.reference_time_information
         * AssignedNumber: 0x2A14
         */
        public static let referenceTimeInformation = CBUUID(string: "2A14")

        /**
         * SpecificationName: Report
         * SpecificationType: org.bluetooth.characteristic.report
         * AssignedNumber: 0x2A4D
         */
        public static let report = CBUUID(string: "2A4D")

        /**
         * SpecificationName: Report Map
         * SpecificationType: org.bluetooth.characteristic.report_map
         * AssignedNumber: 0x2A4B
         */
        public static let reportMap = CBUUID(string: "2A4B")

        /**
         * SpecificationName: Resolvable Private Address Only
         * SpecificationType: org.bluetooth.characteristic.resolvable_private_address_only
         * AssignedNumber: 2AC9
         */
        public static let resolvablePrivateAddressOnly = CBUUID(string: "2AC9")

        /**
         * SpecificationName: Resting Heart Rate
         * SpecificationType: org.bluetooth.characteristic.resting_heart_rate
         * AssignedNumber: 0x2A92
         */
        public static let restingHeartRate = CBUUID(string: "2A92")

        /**
         * SpecificationName: Ringer Control Point
         * SpecificationType: org.bluetooth.characteristic.ringer_control_point
         * AssignedNumber: 0x2A40
         */
        public static let ringerControlPoint = CBUUID(string: "2A40")

        /**
         * SpecificationName: Ringer Setting
         * SpecificationType: org.bluetooth.characteristic.ringer_setting
         * AssignedNumber: 0x2A41
         */
        public static let ringerSetting = CBUUID(string: "2A41")

        /**
         * SpecificationName: RSC Feature
         * SpecificationType: org.bluetooth.characteristic.rsc_feature
         * AssignedNumber: 0x2A54
         */
        public static let rscFeature = CBUUID(string: "2A54")

        /**
         * SpecificationName: RSC Measurement
         * SpecificationType: org.bluetooth.characteristic.rsc_measurement
         * AssignedNumber: 0x2A53
         */
        public static let rscMeasurement = CBUUID(string: "2A53")

        /**
         * SpecificationName: SC Control Point
         * SpecificationType: org.bluetooth.characteristic.sc_control_point
         * AssignedNumber: 0x2A55
         */
        public static let scControlPoint = CBUUID(string: "2A55")

        /**
         * SpecificationName: Scan Interval Window
         * SpecificationType: org.bluetooth.characteristic.scan_interval_window
         * AssignedNumber: 0x2A4F
         */
        public static let scanIntervalWindow = CBUUID(string: "2A4F")

        /**
         * SpecificationName: Scan Refresh
         * SpecificationType: org.bluetooth.characteristic.scan_refresh
         * AssignedNumber: 0x2A31
         */
        public static let scanRefresh = CBUUID(string: "2A31")

        /**
         * SpecificationName: Sensor Location
         * SpecificationType: org.blueooth.characteristic.sensor_location
         * AssignedNumber: 0x2A5D
         */
        public static let SENSOR_LOCATION_UUID = CBUUID(string: "2A5D")

        /**
         * SpecificationName: Serial Number String
         * SpecificationType: org.bluetooth.characteristic.serial_number_string
         * AssignedNumber: 0x2A25
         */
        public static let serialNumberString = CBUUID(string: "2A25")

        /**
         * SpecificationName: Service Changed
         * SpecificationType: org.bluetooth.characteristic.gatt.service_changed
         * AssignedNumber: 0x2A05
         */
        public static let serviceChanged = CBUUID(string: "2A05")

        /**
         * SpecificationName: Software Revision String
         * SpecificationType: org.bluetooth.characteristic.software_revision_string
         * AssignedNumber: 0x2A28
         */
        public static let softwareRevisionString = CBUUID(string: "2A28")

        /**
         * SpecificationName: Sport Type for Aerobic and Anaerobic Thresholds
         * SpecificationType: org.bluetooth.characteristic.sport_type_for_aerobic_and_anaerobic_thresholds
         * AssignedNumber: 0x2A93
         */
        public static let sportTypeForAerobicAndAnaerobicThresholds = CBUUID(string: "2A93")

        /**
         * SpecificationName: Supported New Alert Category
         * SpecificationType: org.bluetooth.characteristic.supported_new_alert_category
         * AssignedNumber: 0x2A47
         */
        public static let supportedNewAlertCategory = CBUUID(string: "2A47")

        /**
         * SpecificationName: Supported Unread Alert Category
         * SpecificationType: org.bluetooth.characteristic.supported_unread_alert_category
         * AssignedNumber: 0x2A48
         */
        public static let supportedUnreadAlertCategory = CBUUID(string: "2A48")

        /**
         * SpecificationName: System ID
         * SpecificationType: org.bluetooth.characteristic.system_id
         * AssignedNumber: 0x2A23
         */
        public static let systemID = CBUUID(string: "2A23")

        /**
         * SpecificationName: TDS Control Point
         * SpecificationType: org.bluetooth.characteristic.tds_control_point
         * AssignedNumber: 0x2ABC
         */
        public static let tdsControlPoint = CBUUID(string: "2ABC")

        /**
         * SpecificationName: Temperature
         * SpecificationType: org.bluetooth.characteristic.temperature
         * AssignedNumber: 0x2A6E
         */
        public static let temperature = CBUUID(string: "2A6E")

        /**
         * SpecificationName: Temperature Measurement
         * SpecificationType: org.bluetooth.characteristic.temperature_measurement
         * AssignedNumber: 0x2A1C
         */
        public static let temperatureMeasurement = CBUUID(string: "2A1C")

        /**
         * SpecificationName: Temperature Type
         * SpecificationType: org.bluetooth.characteristic.temperature_type
         * AssignedNumber: 0x2A1D
         */
        public static let temperatureType = CBUUID(string: "2A1D")

        /**
         * SpecificationName: Three Zone Heart Rate Limits
         * SpecificationType: org.bluetooth.characteristic.three_zone_heart_rate_limits
         * AssignedNumber: 0x2A94
         */
        public static let threeZoneHeartRateLimits = CBUUID(string: "2A94")

        /**
         * SpecificationName: Time Accuracy
         * SpecificationType: org.bluetooth.characteristic.time_accuracy
         * AssignedNumber: 0x2A12
         */
        public static let timeAccuracy = CBUUID(string: "2A12")

        /**
         * SpecificationName: Time Source
         * SpecificationType: org.bluetooth.characteristic.time_source
         * AssignedNumber: 0x2A13
         */
        public static let timeSource = CBUUID(string: "2A13")

        /**
         * SpecificationName: Time Update Control Point
         * SpecificationType: org.bluetooth.characteristic.time_update_control_point
         * AssignedNumber: 0x2A16
         */
        public static let timeUpdateControlPoint = CBUUID(string: "2A16")

        /**
         * SpecificationName: Time Update State
         * SpecificationType: org.bluetooth.characteristic.time_update_state
         * AssignedNumber: 0x2A17
         */
        public static let timeUpdateState = CBUUID(string: "2A17")

        /**
         * SpecificationName: Time with DST
         * SpecificationType: org.bluetooth.characteristic.time_with_dst
         * AssignedNumber: 0x2A11
         */
        public static let timeWithDST = CBUUID(string: "2A11")

        /**
         * SpecificationName: Time Zone
         * SpecificationType: org.bluetooth.characteristic.time_zone
         * AssignedNumber: 0x2A0E
         */
        public static let timeZone = CBUUID(string: "2A0E")

        /**
         * SpecificationName: True Wind Direction
         * SpecificationType: org.bluetooth.characteristic.true_wind_direction
         * AssignedNumber: 0x2A71
         */
        public static let trueWindDirection = CBUUID(string: "2A71")

        /**
         * SpecificationName: True Wind Speed
         * SpecificationType: org.bluetooth.characteristic.true_wind_speed
         * AssignedNumber: 0x2A70
         */
        public static let trueWindSpeed = CBUUID(string: "2A70")

        /**
         * SpecificationName: Two Zone Heart Rate Limit
         * SpecificationType: org.bluetooth.characteristic.two_zone_heart_rate_limit
         * AssignedNumber: 0x2A95
         */
        public static let twoZoneHeartRateLimit = CBUUID(string: "2A95")

        /**
         * SpecificationName: Tx Power Level
         * SpecificationType: org.bluetooth.characteristic.tx_power_level
         * AssignedNumber: 0x2A07
         */
        public static let txPowerLevel = CBUUID(string: "2A07")

        /**
         * SpecificationName: Uncertainty
         * SpecificationType: org.bluetooth.characteristic.uncertainty
         * AssignedNumber: 0x2AB4
         */
        public static let uncertainty = CBUUID(string: "2AB4")

        /**
         * SpecificationName: Unread Alert Status
         * SpecificationType: org.bluetooth.characteristic.unread_alert_status
         * AssignedNumber: 0x2A45
         */
        public static let unreadAlertStatus = CBUUID(string: "2A45")

        /**
         * SpecificationName: URI
         * SpecificationType: org.bluetooth.characteristic.uri
         * AssignedNumber: 0x2AB6
         */
        public static let uri = CBUUID(string: "2AB6")

        /**
         * SpecificationName: User Control Point
         * SpecificationType: org.bluetooth.characteristic.user_control_point
         * AssignedNumber: 0x2A9F
         */
        public static let userControlPoint = CBUUID(string: "2A9F")

        /**
         * SpecificationName: User Index
         * SpecificationType: org.bluetooth.characteristic.user_index
         * AssignedNumber: 0x2A9A
         */
        public static let userIndex = CBUUID(string: "2A9A")

        /**
         * SpecificationName: UV Index
         * SpecificationType: org.bluetooth.characteristic.uv_index
         * AssignedNumber: 0x2A76
         */
        public static let uvIndex = CBUUID(string: "2A76")

        /**
         * SpecificationName: VO2 Max
         * SpecificationType: org.bluetooth.characteristic.vo2_max
         * AssignedNumber: 0x2A96
         */
        public static let vo2Max = CBUUID(string: "2A96")

        /**
         * SpecificationName: Waist Circumference
         * SpecificationType: org.bluetooth.characteristic.waist_circumference
         * AssignedNumber: 0x2A97
         */
        public static let waistCircumference = CBUUID(string: "2A97")

        /**
         * SpecificationName: Weight
         * SpecificationType: org.bluetooth.characteristic.weight
         * AssignedNumber: 0x2A98
         */
        public static let weight = CBUUID(string: "2A98")

        /**
         * SpecificationName: Weight Measurement
         * SpecificationType: org.bluetooth.characteristic.weight_measurement
         * AssignedNumber: 0x2A9D
         */
        public static let weightMeasurement = CBUUID(string: "2A9D")

        /**
         * SpecificationName: Weight Scale Feature
         * SpecificationType: org.bluetooth.characteristic.weight_scale_feature
         * AssignedNumber: 0x2A9E
         */
        public static let WeightScaleFeature = CBUUID(string: "2A9E")

        /**
         * SpecificationName: Wind Chill
         * SpecificationType: org.bluetooth.characteristic.wind_chill
         * AssignedNumber: 0x2A79
         */
        public static let windChill = CBUUID(string: "2A79")
    }

    public struct Descriptors
    {
        /**
         * SpecificationName: Characteristic Aggregate Format
         * SpecificationType: org.bluetooth.descriptor.gatt.characteristic_aggregate_format
         * AssignedNumber: 0x2905
         */
        public static let characteristicAggregateFormat = CBUUID(string: "2905")

        /**
         * SpecificationName: Characteristic Extended Properties
         * SpecificationType: org.bluetooth.descriptor.gatt.characteristic_extended_properties
         * AssignedNumber: 0x2900
         */
        public static let characteristicExtendedProperties = CBUUID(string: "2900")

        /**
         * SpecificationName: Characteristic Presentation Format
         * SpecificationType: org.bluetooth.descriptor.gatt.characteristic_presentation_format
         * AssignedNumber: 0x2904
         */
        public static let characteristicPresentationFormat = CBUUID(string: "2904")

        /**
         * SpecificationName: Characteristic User Description
         * SpecificationType: org.bluetooth.descriptor.gatt.characteristic_user_description
         * AssignedNumber: 0x2901
         */
        public static let characteristicUserDescription = CBUUID(string: "2901")

        /**
         * SpecificationName: Client Characteristic Configuration
         * SpecificationType: org.bluetooth.descriptor.gatt.client_characteristic_configuration
         * AssignedNumber: 0x2902
         */
        public static let clientCharacteristicConfiguration = CBUUID(string: "2902")

        /**
         * SpecificationName: Environmental Sensing Configuration
         * SpecificationType: org.bluetooth.descriptor.es_configuration
         * AssignedNumber: 0x290B
         */
        public static let environmentalSensingConfiguration = CBUUID(string: "290B")

        /**
         * SpecificationName: Environmental Sensing Measurement
         * SpecificationType: org.bluetooth.descriptor.es_measurement
         * AssignedNumber: 0x290C
         */
        public static let environmentalSensingMeasurement = CBUUID(string: "290C")

        /**
         * SpecificationName: Environmental Sensing Trigger Setting
         * SpecificationType: org.bluetooth.descriptor.es_trigger_setting
         * AssignedNumber: 0x290D
         */
        public static let environmentalSensingTriggerSetting = CBUUID(string: "290D")

        /**
         * SpecificationName: External Report Reference
         * SpecificationType: org.bluetooth.descriptor.external_report_reference
         * AssignedNumber: 0x2907
         */
        public static let externalReportReference = CBUUID(string: "2907")

        /**
         * SpecificationName: Number of Digitals
         * SpecificationType: org.bluetooth.descriptor.number_of_digitals
         * AssignedNumber: 0x2909
         */
        public static let numberOfDigitals = CBUUID(string: "2909")

        /**
         * SpecificationName: Report Reference
         * SpecificationType: org.bluetooth.descriptor.report_reference
         * AssignedNumber: 0x2908
         */
        public static let reportReference = CBUUID(string: "2908")

        /**
         * SpecificationName: Server Characteristic Configuration
         * SpecificationType: org.bluetooth.descriptor.gatt.server_characteristic_configuration
         * AssignedNumber: 0x2903
         */
        public static let serverCharacteristicConfiguration = CBUUID(string: "2903")

        /**
         * SpecificationName: Time Trigger Setting
         * SpecificationType: org.bluetooth.descriptor.time_trigger_setting
         * AssignedNumber: 0x290E
         */
        public static let timeTriggerSetting = CBUUID(string: "290E")

        /**
         * SpecificationName: Valid Range
         * SpecificationType: org.bluetooth.descriptor.valid_range
         * AssignedNumber: 0x2906
         */
        public static let validRange = CBUUID(string: "2906")

        /**
         * SpecificationName: Value Trigger Setting
         * SpecificationType: org.bluetooth.descriptor.value_trigger_setting
         * AssignedNumber: 0x290A
         */
        public static let valueTriggerSetting = CBUUID(string: "290A")
    }
}
