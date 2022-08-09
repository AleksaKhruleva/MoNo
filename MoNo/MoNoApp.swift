//
//  MoNoApp.swift
//  MoNo
//
//  Created by Aleksa Khruleva on 08.08.2022.
//

import SwiftUI
import EventKit
import EventKitUI

@main
struct MoNoApp: App {
    @StateObject var dataController = DataController()
    
    init() {
        let eventStore = EKEventStore()
        
        eventStore.requestAccess(to: .event) { granted, error in
            if granted {
                print("Calendar access granted")
            } else if let error = error {
                print("Calendar access error: \(error.localizedDescription)")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
        }
    }
}
