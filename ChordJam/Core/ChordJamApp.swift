//
//  ChordJamApp.swift
//  ChordJam
//
//  Created by Anthony on 14/06/24.
//

import SwiftUI

@main
struct ChordJamApp: App {
    @State private var currentView = "Introduction"
    @State private var unlockedLevel = 5
    @StateObject private var gameCenterManager = GameCenterManager.shared
    
    var body: some Scene {
        WindowGroup {
            NavigationView{
                ZStack {
                    if currentView == "Introduction" {
                        IntroductionView(
                            onFinish: {
                                withAnimation {
                                    currentView = "MainMenu"
                                }
                            },
                            onStartOnboarding: {
                                withAnimation {
                                    currentView = "Onboarding"
                                }
                            }
                        )
                    } else if currentView == "MainMenu" {
                        MainMenuView(unlockedLevel: $unlockedLevel)
                    } else if currentView == "Onboarding" {
                        OnboardingView(unlockedLevel: $unlockedLevel)
                    }
                }
                    .environmentObject(gameCenterManager)
            }
        }
    }
}
