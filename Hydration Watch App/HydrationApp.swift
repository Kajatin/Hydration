//
//  HydrationApp.swift
//  Hydration Watch App
//
//  Created by Roland Kajatin on 12/06/2022.
//

import SwiftUI

@main
struct Hydration_Watch_AppApp: App {
    let viewModel = ViewModel()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView().environmentObject(viewModel)
            }
        }
    }
}
