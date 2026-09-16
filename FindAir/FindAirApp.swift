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
            appearance.backgroundColor = .black
            
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

            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithOpaqueBackground()
            tabBarAppearance.backgroundColor = .black
            tabBarAppearance.shadowColor = .clear
            UITabBar.appearance().standardAppearance = tabBarAppearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            }
            UITabBar.appearance().tintColor = .white
        
            // Back button + các button trên NavigationBar
            UINavigationBar.appearance().tintColor = .white
        }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
                .tint(.white)
        }
    }
    

private struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        if hasCompletedOnboarding {
            ZStack {
                Color.black
                    .ignoresSafeArea()

                TabView {
                    HomeView()
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }

                    HistoryView()
                        .tabItem {
                            Label("History", systemImage: "clock.arrow.circlepath")
                        }

                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gearshape.fill")
                        }
                }
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarBackground(Color.black, for: .tabBar)
                .toolbarColorScheme(.dark, for: .tabBar)
            }
        } else {
            OnboardingView()
        }
    }
}
    
}
