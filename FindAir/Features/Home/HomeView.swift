import SwiftUI
import UIKit

public struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var searchText = ""
    @State private var category: DeviceCategory = .all
    @State private var showSettings = false
    @State private var showBluetoothAlert = false
    @State private var selectedDevice: BluetoothDevice?
    @State private var showSubscription = false

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 22) {
                        topHeader

                        deviceListSection

                        if viewModel.state == .unauthorized {
                            Spacer()
                            Text("Open Settings to allow Bluetooth access.")
                                .font(.body.weight(.regular))
                                .foregroundStyle(.white)
                            Button {
                                openAppSettings()
                            } label: {
                                Label("Open Settings", systemImage: "gearshape.fill")
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(.black)
                            }
                            .buttonStyle(.borderedProminent)
//                            .background(Color.green)
                            .controlSize(.large)
                        }

//                        statusCard
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 24)
                }
            }
            .onAppear {
                viewModel.bluetoothManager.requestAuthorizationIfNeeded()
                showBluetoothAlert = viewModel.state == .poweredOff
            }
            .onChange(of: viewModel.state) { state in
                if state == .poweredOff {
                    showBluetoothAlert = true
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .fullScreenCover(item: $selectedDevice) { device in
                NavigationStack {
                    DeviceDetailView(device: device, onStop: {})
                }
            }
            .fullScreenCover(isPresented: $showSubscription) {
                NavigationStack {
                    SubscriptionView()
                }
            }
            .alert("Bluetooth is turned off", isPresented: $showBluetoothAlert) {
                
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please turn on Bluetooth in Settings to find nearby devices.")
            }
        }
    }

    private var topHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("Device Finder")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.white)

                    if viewModel.isScanning {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                            .accessibilityLabel("Scanning")
                    }
                }
                Text("Find nearby Bluetooth devices")
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }

            Spacer()

//            Button {
//                showSettings = true
//            } label: {
//                Image(systemName: "gearshape.fill")
//                    .font(.title3)
//                    .foregroundStyle(.primary)
//                    .padding(10)
//                    .background(Color(.secondarySystemBackground))
//                    .clipShape(Circle())
//            }
        }
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Circle()
                    .fill(viewModel.state == .scanning ? Color.green : Color.gray)
                    .frame(width: 10, height: 10)
                Text(viewModel.state.title)
                    .font(.headline)
            }

            Text(viewModel.status)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(red: 40/255, green: 40/255, blue: 40/255))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var deviceListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Nearby Devices")
                    .font(.title3.weight(.semibold))

                Spacer()

                Menu {
                    ForEach(DeviceCategory.allCases, id: \ .self) { option in
                        Button(option.title) {
                            category = option
                        }
                    }
                } label: {
                    Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                }
                .buttonStyle(.bordered)
            }

            SearchBar(text: $searchText)

            let filtered = filteredResults

            if filtered.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "wave.3.left.circle")
                        .font(.system(size: 34))
                        .foregroundStyle(.white)
                    Text("No nearby Bluetooth devices found.")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Move closer to your device and try scanning again.")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(Color(red: 40/255, green: 40/255, blue: 40/255))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                VStack(spacing: 10) {
                    ForEach(filtered) { device in
                        Button {
//                            selectedDevice = device
                            if SubscriptionStore.shared.hasPremiumAccess {
                                // Mở tính năng premium
                                selectedDevice = device
                            } else {
                                // Hiển thị SubscriptionView
                                showSubscription = true
                            }
                        } label: {
                            DeviceRow(device: device)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var filteredResults: [BluetoothDevice] {
        return viewModel.devices.filter { device in
            let searchOK = searchText.isEmpty || device.displayName.localizedCaseInsensitiveContains(searchText)
            let categoryOK: Bool
            switch category {
            case .all:
                categoryOK = true
            case .audio:
                categoryOK = device.category == .audio
            case .wearables:
                categoryOK = device.category == .wearables
            case .phonesTablets:
                categoryOK = device.category == .phonesTablets
            case .other:
                categoryOK = device.category == .other
            }
            return searchOK && categoryOK
        }
    }

    private func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        UIApplication.shared.open(settingsURL)
    }
}

private struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search devices...", text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(.black)
        }
        .padding(12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

//#Preview {
//    HomeView()
//}
