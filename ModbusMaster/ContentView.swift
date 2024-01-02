//
//  ContentView.swift
//  ModbusMaster
//
//  Created by Frederic Torreele on 02/07/2023.
//

import SwiftUI

struct ContentView: View {
    @State private var slaveIpAddress: String = "192.168.0.180"
    @State private var upRequested: Bool = false
    @State private var downRequested: Bool = false
    
    @ObservedObject var currentSlave: Slave
    let tick = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationStack{
            VStack {
                Text("Tt Modbus Master")
                    .font(.largeTitle)
                    .bold()
                    .padding()
                Text("Enter a slave IP address")
                    .font(.subheadline)
                HStack{
                    TextField("Slave IP", text: $slaveIpAddress)
                        .onSubmit {
                            currentSlave.ipAddress = slaveIpAddress
                            }
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .textFieldStyle(.roundedBorder)
                        .foregroundColor(currentSlave.isConnected ? .green : .orange)
                    if(currentSlave.connectionAttemptBusy)
                    {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding(.horizontal)
                    }
                    Button() {
                        if(currentSlave.isConnected)
                        {
                            currentSlave.disconnect()
                        }
                        else
                        {
                            if(currentSlave.connectionAttemptBusy)
                            {
                                currentSlave.disconnect()
                            }
                            else
                            {
                                currentSlave.connect()
                            }
                        }
                    } label: {
                        if (currentSlave.isConnected) {
                            Text("Disconnect")
                        }
                        else {
                            if(currentSlave.connectionAttemptBusy){
                                Text("Cancel")
                            }
                            else {
                                Text("Connect")
                            }
                        }
                        
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.bottom)
                .alert("Connect", isPresented: $currentSlave.connectionAttemptFailed) {
                    Button("OK", role: .cancel) {
                        currentSlave.connectionAttemptFailed = false
                    }
                } message: {
                    Text("Could not connect to slave with IP address \(currentSlave.ipAddress)")
                }
                
                
                List{
                    Section{
                        LabeledContent("Firmware build", value: "\(String(format: "%08u", currentSlave.firmwareBuild))")
                    }
                    Section{
                        HStack{
                            Button(){
                                
                            } label: {
                                Text("Up")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            Button(){
                                
                            } label: {
                                Text("Down")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    } header: {
                        Text("Motion")
                    }
                    Section{
                        LabeledContent("Servo Power", value: String(format: "%.2f", currentSlave.servoVoltage) + " Volts")
                        LabeledContent("Actuator Power", value: String(format: "%.2f", currentSlave.actuatorVoltage) + "Volts")
                    } header: {
                        Text("Voltages")
                    }
                    Section{
                        LabeledContent("All", value: "0x\(String(format: "%08x", currentSlave.diagFlags))")
                        LabeledContent("Servo Voltage", value: "0x\(String(format: "%02x", currentSlave.diagFlags))")
                        LabeledContent("Actuator Voltage", value: "0x\(String(format: "%02x", currentSlave.diagFlags>>4))")
                        LabeledContent("Servo Status", value: "0x\(String(format: "%02x", currentSlave.diagFlags>>2))")
                    } header: {
                        Text("Diagnose Flags")
                    }
                    
                    
                }.onReceive(tick) { fired in
                    print("[INFO] tik, tak ...")
                    currentSlave.updateRegisters()
                    
                }
            }
            .padding()
        }
        .onAppear()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(currentSlave: Slave.defaultSlave)
    }
}
