import SwiftUI
import CoreLocation
import SafariServices
import UIKit

public struct SettingsView: View {
    @AppStorage("scanDuration") private var scanDuration = 20
    @AppStorage("signalSmoothing") private var smoothing = 0.45
    @AppStorage("soundEnabled") private var soundEnabled = false
    @AppStorage("vibrateEnabled") private var vibrateEnabled = false
    @AppStorage("locationEnabled") private var locationEnabled = false
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("themeMode") private var themeMode = "System"
    @StateObject private var locationPermission = SettingsLocationPermission()
    @State private var pendingLocationRequest = false
    @State private var showLocationAlert = false
    @State private var showSubscription = false
    @State private var webURL: URL?

    public var body: some View {
        NavigationStack {
            List {
                Section("Subscription") {
                    Button {
                        showSubscription = true
                    } label: {
                        Label("Unlock Premium Features", systemImage: "sparkles")
                    }
                    .frame(height: 40)
                }

                Section("Finder") {
                    Toggle("Sound", isOn: $soundEnabled).tint(.blue)
                    Toggle("Vibrate", isOn: $vibrateEnabled).tint(.blue)
                    Toggle("Location", isOn: $locationEnabled).tint(.blue)
                        .onChange(of: locationEnabled) { isEnabled in
                            guard isEnabled else {
                                pendingLocationRequest = false
                                return
                            }

                            handleLocationToggleOn()
                        }
                }



                Section("About") {
                    Button("Privacy Policy") {
                        webURL = URL(string: "https://sites.google.com/view/sonquoctri/privacy-policy")
                    }
                    Button("Terms of Use") {
                        webURL = URL(string: "https://sites.google.com/view/sonquoctri/terms-of-use")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $showSubscription) {
                NavigationStack {
                    SubscriptionView()
                }
            }
            .sheet(isPresented: webSheetPresented) {
                if let webURL {
                    SettingsSafariView(url: webURL)
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.medium, .large])
        .onChange(of: locationPermission.authorizationStatus) { status in
            guard pendingLocationRequest else {
                return
            }

            if status == .authorizedWhenInUse || status == .authorizedAlways {
                pendingLocationRequest = false
                locationEnabled = true
            } else if status == .denied || status == .restricted {
                pendingLocationRequest = false
                locationEnabled = false
                showLocationAlert = true
            }
        }
        .alert("Location permission is required", isPresented: $showLocationAlert) {
            Button("Open Settings") {
                openAppSettings()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Allow Location access in Settings before enabling this feature.")
        }
    }

    private func handleLocationToggleOn() {
        switch locationPermission.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationEnabled = true
        case .notDetermined:
            pendingLocationRequest = true
            locationEnabled = false
            locationPermission.requestPermission()
        case .denied, .restricted:
            locationEnabled = false
            showLocationAlert = true
        @unknown default:
            locationEnabled = false
        }
    }

    private func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        UIApplication.shared.open(settingsURL)
    }

    private var webSheetPresented: Binding<Bool> {
        Binding(
            get: { webURL != nil },
            set: { isPresented in
                if !isPresented {
                    webURL = nil
                }
            }
        )
    }
}

private struct SettingsSafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ viewController: SFSafariViewController, context: Context) {}
}

private final class SettingsLocationPermission: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    private let manager = CLLocationManager()

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
    }
}

#Preview {
    SettingsView()
}
