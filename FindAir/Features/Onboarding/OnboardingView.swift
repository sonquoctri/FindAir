import SwiftUI
import CoreLocation
import UIKit

public struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @ObservedObject private var bluetoothManager = BluetoothManager.shared
    @StateObject private var locationManager = LocationPermissionManager()
    @State private var page = 0
    @State private var showSettingsAlert = false

    private let pages = OnboardingPage.allCases

    public init() {}

    public var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.13, blue: 0.29),
                    Color(red: 0.02, green: 0.09, blue: 0.14)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            GeometryReader { geometry in
                VStack(spacing: 0) {
                    TabView(selection: $page) {
                        ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                            OnboardingPageView(page: page)
                                .tag(index)
                        }

                        BluetoothPermissionView()
                            .tag(pages.count)

                        LocationPermissionView()
                            .tag(locationPage)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    onboardingFooter
                        .frame(height: page == locationPage
                               ? min(max(geometry.size.height * 0.23, 190), 220)
                               : min(max(geometry.size.height * 0.18, 136), 166))
                }
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: bluetoothManager.state) { state in
            if isBluetoothReady && page == pages.count {
                withAnimation(.easeInOut) {
                    page = locationPage
                }
            }
        }
        .onChange(of: locationManager.authorizationStatus) { status in
            if status == .authorizedAlways || status == .authorizedWhenInUse {
                hasCompletedOnboarding = true
            }
        }
        .alert("Bluetooth access is required", isPresented: $showSettingsAlert) {
            Button("Open Settings") {
                openAppSettings()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Allow Bluetooth access in Settings to find nearby devices.")
        }
    }

    private var onboardingFooter: some View {
        VStack(spacing: 0) {
            Button {
                if page == locationPage {
                    if locationManager.authorizationStatus == .notDetermined {
                        locationManager.requestPermission()
                    } else if locationManager.isAuthorized {
                        hasCompletedOnboarding = true
                    }
                } else if page == pages.count {
                    requestBluetoothAccess()
                } else {
                    withAnimation(.easeInOut) {
                        page += 1
                    }
                }
            } label: {
                Text(page == pages.count ? "Enable" : page == locationPage ? "Enable" : "Continue")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: 384)
                    .frame(height: 64)
                    .background(Color(red: 0.91, green: 0.95, blue: 0.99))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 32)

            if page == locationPage {
                Button("Later") {
                    hasCompletedOnboarding = true
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.7))
                .padding(.top, 10)
            }

            if page < pages.count {
                HStack(spacing: 12) {
                    ForEach(pages.indices, id: \.self) { index in
                        Circle()
                            .fill(index == page ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 10, height: 10)
                    }
                }
                .padding(.top, 18)
            }
        }
    }

    private var isBluetoothReady: Bool {
        bluetoothManager.state == .ready || bluetoothManager.state == .scanning
    }

    private var locationPage: Int {
        pages.count + 1
    }

    private func requestBluetoothAccess() {
        if bluetoothManager.state == .unauthorized {
            showSettingsAlert = true
        } else if isBluetoothReady {
            withAnimation(.easeInOut) {
                page = locationPage
            }
        } else {
            bluetoothManager.requestAuthorizationIfNeeded()
        }
    }

    private func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        UIApplication.shared.open(settingsURL)
    }
}

private struct LocationPermissionView: View {
    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 32)

            Image(systemName: "location.fill")
                .font(.system(size: 92, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 180, height: 180)
                .background(
                    RoundedRectangle(cornerRadius: 40, style: .continuous)
                        .fill(Color.blue.opacity(0.75))
                )
                .shadow(color: .blue.opacity(0.4), radius: 24)

            VStack(spacing: 16) {
                Text("Enable Location")
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Location access helps FindAir guide you toward nearby devices.")
                    .font(.title3)
                    .foregroundStyle(Color.white.opacity(0.58))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 26)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private final class LocationPermissionManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus

    private let manager = CLLocationManager()

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse
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

private struct BluetoothPermissionView: View {
    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 32)

            Image("BlueTooth")
                .resizable()
                .foregroundStyle(.white)
                .frame(width: 180, height: 180)
//                .background(
//                    RoundedRectangle(cornerRadius: 42, style: .continuous)
//                        .fill(
//                            LinearGradient(
//                                colors: [Color.blue.opacity(0.95), Color.blue.opacity(0.65)],
//                                startPoint: .topLeading,
//                                endPoint: .bottomTrailing
//                            )
//                        )
//                )
                .shadow(color: .blue.opacity(0.45), radius: 24)

            VStack(spacing: 16) {
                Text("Enable Bluetooth")
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Device tracker works best with access to Bluetooth and nearby devices.")
                    .font(.title3)
                    .foregroundStyle(Color.white.opacity(0.58))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 26)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 0) {
            FeatureGrid(items: page.gridItems)
                .padding(.horizontal, 24)
                .padding(.top, 12)

            Spacer(minLength: 12)

            VStack(spacing: 12) {
//                Text(page.eyebrow)
//                    .font(.title3.weight(.semibold))
//                    .foregroundStyle(Color.white.opacity(0.58))

                Text(page.title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.system(size: 20, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.56))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct FeatureGrid: View {
    let items: [OnboardingFeature]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(items) { item in
                VStack(spacing: 5) {
                    Spacer(minLength: 5)
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: item.systemImage)
                            .font(.system(size: 30, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(height: 60)
                            .frame(maxWidth: .infinity)
//                            .aspectRatio(1, contentMode: .fit)
//                            .background(Color.white.opacity(0.1))
//                            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))

                        if let badge = item.badge {
                            Text(badge)
                                .font(.title.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .overlay {
                                    Capsule().stroke(Color.white, lineWidth: 2)
                                }
                                .padding(10)
                        }
                    }

                    Text(item.title)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.68))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    
                    Spacer(minLength: 5)
                }
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }
}

private struct OnboardingFeature: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    let badge: String?
}

private enum OnboardingPage: Int, CaseIterable, Identifiable {
    case devices
    case features
    case steps

    var id: Int { rawValue }

    var eyebrow: String {
        switch self {
        case .devices: return "Find My Devices Now"
        case .features: return "Powerful Features To"
        case .steps: return "Simple, Quick, Found"
        }
    }

    var title: String {
        switch self {
        case .devices: return "Track & Locate"
        case .features: return "Find It Fast"
        case .steps: return "Easy To Use"
        }
    }

    var subtitle: String {
        switch self {
        case .devices: return "Works with every Apple device and more. If it connects via Bluetooth, we can find it."
        case .features: return "Everything you need to find your devices now and keep them found."
        case .steps: return "Track down any lost Bluetooth device in seconds."
        }
    }

    var gridItems: [OnboardingFeature] {
        switch self {
        case .devices:
            return [
                .init(title: "AirPods", systemImage: "airpodspro", badge: nil),
                .init(title: "AirTag", systemImage: "smallcircle.filled.circle", badge: nil),
                .init(title: "Apple Watch", systemImage: "applewatch", badge: nil),
                .init(title: "Headphones", systemImage: "headphones", badge: nil),
                .init(title: "iPhone", systemImage: "iphone", badge: nil),
                .init(title: "iPad", systemImage: "ipad", badge: nil),
                .init(title: "Speakers", systemImage: "hifispeaker.fill", badge: nil),
                .init(title: "MacBook", systemImage: "laptopcomputer", badge: nil)
            ]
        case .features:
            return [
                .init(title: "Live Tracking", systemImage: "location.fill", badge: nil),
                .init(title: "Low Energy Detection", systemImage: "antenna.radiowaves.left.and.right", badge: nil),
                .init(title: "Signal Meter", systemImage: "chart.bar.fill", badge: nil),
                .init(title: "Device Sorting", systemImage: "line.3.horizontal.decrease.circle.fill", badge: nil),
                .init(title: "Direction Finder", systemImage: "arrow.turn.up.right", badge: nil),
                .init(title: "Device Map", systemImage: "map.fill", badge: nil),
                .init(title: "Proximity Alerts", systemImage: "bell.fill", badge: nil),
                .init(title: "Battery Status", systemImage: "battery.100percent.bolt", badge: nil)
            ]
        case .steps:
            return [
                .init(title: "Search", systemImage: "magnifyingglass", badge: nil),
                .init(title: "Observe signal strength", systemImage: "chart.bar.fill", badge: nil),
                .init(title: "Move around", systemImage: "figure.walk", badge: nil),
                .init(title: "Find your device", systemImage: "location.fill", badge: nil)
            ]
        }
    }
}

#Preview {
    OnboardingView()
}
