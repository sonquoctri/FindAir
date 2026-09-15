import SwiftUI

public struct SettingsView: View {
    @AppStorage("scanDuration") private var scanDuration = 20
    @AppStorage("signalSmoothing") private var smoothing = 0.45
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("soundEnabled") private var soundEnabled = false
    @AppStorage("themeMode") private var themeMode = "System"

    public var body: some View {
        NavigationStack {
            List {
                Section("Scanning") {
                    Stepper("Scan duration: \(scanDuration)s", value: $scanDuration, in: 10...60, step: 5)
                    Slider(value: $smoothing, in: 0.1...0.9, step: 0.05)
                    Text("Signal smoothing: \(String(format: "%.2f", smoothing))")
                }

                Section("Appearance") {
                    Picker("Theme", selection: $themeMode) {
                        Text("System").tag("System")
                        Text("Light").tag("Light")
                        Text("Dark").tag("Dark")
                    }
                    .pickerStyle(.segmented)
                }

                Section("Feedback") {
                    Toggle("Haptics", isOn: $hapticsEnabled)
                    Toggle("Sound", isOn: $soundEnabled)
                }

                Section("About") {
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    Link("Terms of Use", destination: URL(string: "https://example.com/terms")!)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    SettingsView()
}
