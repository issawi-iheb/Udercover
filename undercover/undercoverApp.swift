//
//  undercoverApp.swift
//  undercover
//
//  Created by Iheb on 12/08/2026.
//

import SwiftUI

@main
struct undercoverApp: App {

    @StateObject private var appState = AppState()

    var body: some Scene {

        WindowGroup {
            Group {
                if appState.isReady {
                    HomeView()
                } else {
                    LoadingView(title: "PREPARING GAME", subtitle: "Getting everything ready...")
                }
            }
            .environmentObject(appState)
            .task {
                await appState.bootstrap()
            }
        }
    }
}
