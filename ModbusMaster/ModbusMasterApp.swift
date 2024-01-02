//
//  ModbusMasterApp.swift
//  ModbusMaster
//
//  Created by Frederic Torreele on 02/07/2023.
//

import SwiftUI

@main
struct ModbusMasterApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(currentSlave: Slave.defaultSlave)
        }
    }
}
