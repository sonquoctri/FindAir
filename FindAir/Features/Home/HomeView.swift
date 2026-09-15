import SwiftUI

public struct HomeView: View {
    @State private var searchText = ""
    @State private var selectedDevice: BluetoothDevice?
    @State private var category: DeviceCategory = .all
    @State private var favorites: Set<UUID> = []
    @State private var scanningEnabled = false
    @State private var showSettings = false
    @State private var isPermissionNeeded = false

    @State private var viewModel = HomeViewModel()

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    heroCard
                    statusCard

                    if selectedDevice != nil {
                        EmptyView()
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Nearby Devices")
                                .font(.title3.weight(.semibold))
                            Spacer()
                            Menu {
                                ForEach(DeviceCategory.allCases, id: \.self) { option in
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

                        let filteredDevices = filteredResults
                        if filteredDevices.isEmpty {
                            emptyState
                        } else {
                            ForEach(filteredDevices) { device in
                                NavigationLink(destination: DeviceDetailView(device: device, onStop: {
                                    selectedDevice = nil
                                })) {
                                    DeviceRow(device: device)
                                }
                                .buttonStyle(.plain)
                                .padding(.bottom, 4)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("Device Finder")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
        .onAppear {
            viewModel.bluetoothManager.requestAuthorizationIfNeeded()
            if !viewModel.bluetoothManager.isScanning {
                scanningEnabled = false
            }
        }
        .onReceive(viewModel.bluetoothManager.$discoveredDevices) { _ in
            updateFavorites()
        }
    }

    @ViewBuilder
    private var heroCard: some View {
        VStack(spacing: 18) {
            Text("Find nearby devices")
                .font(.title2.weight(.semibold))
            RadarView(signalStrength: strongestSignal, signalLevel: strongestLevel)
                .frame(height: 220)
            Button(action: {
                viewModel.toggleScan()
                scanningEnabled = viewModel.isScanning
            }) {
                Label(viewModel.isScanning ? "Stop Scanning" : "Start Scanning", systemImage: viewModel.isScanning ? "pause.circle.fill" : "play.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 18)
        }
        .padding(.vertical, 22)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color(.secondarySystemBackground), Color(.systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(.horizontal)
    }

    @ViewBuilder
    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(viewModel.state == .scanning ? .green : .gray)
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
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal)
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "wave.3.left.circle")
                .font(.system(size: 34))
                .foregroundStyle(.secondary)
            Text("No nearby Bluetooth devices found.")
                .font(.headline)
            Text("Move closer to your device and try scanning again.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var strongestSignal: Double {
        viewModel.devices.max(by: { $0.signalStrength < $1.signalStrength })?.signalStrength ?? 0.3
    }

    private var strongestLevel: SignalLevel {
        viewModel.devices.max(by: { $0.signalStrength < $1.signalStrength })?.signalLevel ?? .far
    }

    private var filteredResults: [BluetoothDevice] {
        let devices = viewModel.devices.filter { device in
            let matchesSearch = searchText.isEmpty || device.displayName.localizedCaseInsensitiveContains(searchText)
            let matchesCategory: Bool
            switch category {
            case .all:
                matchesCategory = true
            case .audio:
                matchesCategory = device.category == .audio
            case .wearables:
                matchesCategory = device.category == .wearables
            case .phonesTablets:
                matchesCategory = device.category == .phonesTablets
            case .other:
                matchesCategory = device.category == .other
            }
            return matchesSearch && matchesCategory
        }
        return devices.sorted { lhs, rhs in
            lhs.signalStrength > rhs.signalStrength
        }
    }

    private func updateFavorites() {
        let favorites = favorites
        viewModel.bluetoothManager.updateFavorites(favorites)
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
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    HomeView()
}
