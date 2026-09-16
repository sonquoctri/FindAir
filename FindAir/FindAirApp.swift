//
//  FindAirApp.swift
//  FindAir
//
//  Created by SON QUOC TRI on 15/9/26.
//

import SwiftUI

@main
struct FindAirApp: App {
    
    init() {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .clear
            
            appearance.titleTextAttributes = [
                .foregroundColor: UIColor.white
            ]
            
            appearance.largeTitleTextAttributes = [
                .foregroundColor: UIColor.white
            ]
            
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
            UINavigationBar.appearance().compactAppearance = appearance
            
            UINavigationBar.appearance().tintColor = .white
        
            // Back button + các button trên NavigationBar
            UINavigationBar.appearance().tintColor = .white
        }
    
    var body: some Scene {
        WindowGroup {
            RootView().tint(.white)
        }
    }
    

private struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        if hasCompletedOnboarding {
            HomeView()
        } else {
            OnboardingView()
        }
    }
}
    
}
