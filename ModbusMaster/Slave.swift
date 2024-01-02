//
//  MbMaster.swift
//  ModbusMaster
//
//  Created by Frederic Torreele on 02/07/2023.
//

import Foundation
import SwiftUI

class Slave: ObservableObject { // observableObject: watch for changes and update
    var ipAddress: String
    let port: Int = 502
    @Published var diagFlags: UInt16 = 0x0000
    @Published var firmwareBuild: UInt32 = 0
    @Published var servoVoltage: Double = 0.0
    @Published var actuatorVoltage: Double = 0.0
    var modbusObject: SwiftLibModbus? = nil
    var isConnected: Bool = false
    @Published var connectionAttemptBusy: Bool = false
    @Published var id: Int = -1
    var fullScaleADCCnt: Double = 1023
    var fullScaleADCVolt: Double = 26.4
    var ADCInputRes: Double = 44000 // ADC equivalent input resistance
    var V1Div_Rt: Double = 33000 // V1 voltage divider top resistor value in Ohms
    var V1Div_Rb: Double = 22000 // V1 voltage divider bottom resistor value in Ohms
    var V2Div_Rt: Double = 22000 // V2 voltage divider top resistor value in Ohms
    var V2Div_Rb: Double = 68000 // V2 voltage divider bottom resistor value in Ohms
    var connectionAttemptFailed: Bool = false
    
    static let defaultSlave = Slave(ipAddress: "192.168.0.180") // static: zoals een klassevariabele
    
    init(ipAddress: String) {
        self.ipAddress = ipAddress
    }
    
    func connect()
    {
        modbusObject = SwiftLibModbus(ipAddress: ipAddress as NSString, port: Int32(port), device: 1)
        self.connectionAttemptBusy = true
        modbusObject?.connect(success: {
            print("[INFO] Connected to \(self.ipAddress)")
            self.isConnected = true
            self.connectionAttemptBusy = false
            self.connectionAttemptFailed = false
        }, failure: { NSError in
            print("[ERROR] Failed to connect to \(self.ipAddress). \(NSError.localizedDescription)")
            self.isConnected = false
            self.connectionAttemptBusy = false
            self.connectionAttemptFailed = true
        })
    }
    
    func disconnect()
    {
        modbusObject?.disconnect()
        self.isConnected = false
    }
    
    func sendUpRequest()
    {
        
    }
    
    func sendDownRequest()
    {
        
    }
    
    func updateRegisters()
    {
        if(self.isConnected)
        {
            modbusObject?.readRegistersFrom(startAddress: 0, count: 30, success: { (modbusData: [AnyObject]) -> Void in
                print("[INFO] Got data \(modbusData)")
                self.firmwareBuild = (modbusData[0] as! UInt32) << 16 + (modbusData[1] as! UInt32)
                self.diagFlags = modbusData[9] as! UInt16
                self.servoVoltage = self
                    .convertToServoVoltage(data: modbusData[10])
                self.actuatorVoltage = self
                    .convertToActuatorVoltage(data: modbusData[21])
            }, failure: { (modbusError: NSError) -> Void in
                print("[ERROR] Could not update modbus registers \(modbusError.localizedDescription)")
                self.isConnected = false
            })
        }
    }
    
    func convertToServoVoltage(data: AnyObject) -> Double
    {
        return calculateVoltageFromADCValue(ADCValue: Double(data as! UInt16), VDiv_Rt: V1Div_Rt, VDiv_Rb: V1Div_Rb)
    }
    
    func convertToActuatorVoltage(data: AnyObject) -> Double
    {
        return calculateVoltageFromADCValue(ADCValue: Double(data as! UInt16), VDiv_Rt: V2Div_Rt, VDiv_Rb: V2Div_Rb)
    }
    
    func calculateVoltageFromADCValue(ADCValue: Double, VDiv_Rt: Double, VDiv_Rb: Double) -> Double
    {
        let voltAtADCInput: Double = (ADCValue / fullScaleADCCnt) * fullScaleADCVolt;
        let voltBeforeVDiv: Double = voltAtADCInput * ((VDiv_Rt + ((VDiv_Rb * ADCInputRes) / (VDiv_Rb + ADCInputRes))) / ((VDiv_Rb * ADCInputRes) / (VDiv_Rb + ADCInputRes)));
        return voltBeforeVDiv;
    }
}
