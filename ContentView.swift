import SwiftUI

struct ContentView: View {
    @StateObject private var vm = SpaceMouseViewModel()

    var body: some View {
        TabView {
            SettingsTab(vm: vm)
                .tabItem { Label("Settings", systemImage: "gear") }
            StateTab(vm: vm)
                .tabItem { Label("State", systemImage: "info.circle") }
        }
        .padding()
        .frame(minWidth: 320, minHeight: 200)
        // Open on the Settings tab when not connected
        .onAppear {
            if !vm.isConnected {
                // TabView selection binding would be needed to force the tab;
                // for now the user sees Settings first (it's the first tab).
            }
        }
    }
}

// MARK: - Settings Tab

struct SettingsTab: View {
    @ObservedObject var vm: SpaceMouseViewModel

    var body: some View {
        Form {
            Picker("Serial Port", selection: $vm.selectedPortIndex) {
                ForEach(vm.portNames.indices, id: \.self) { i in
                    Text(vm.portNames[i]).tag(i)
                }
            }

            HStack {
                Text("Rotation Scale")
                Spacer()
                TextField("", value: $vm.rotScale,
                          format: .number.precision(.fractionLength(0...4)))
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }

            HStack {
                Text("Translation Scale")
                Spacer()
                TextField("", value: $vm.transScale,
                          format: .number.precision(.fractionLength(0...4)))
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }

            HStack {
                Spacer()
                Button("Apply") { vm.applySettings() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - State Tab

struct StateTab: View {
    @ObservedObject var vm: SpaceMouseViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            GroupBox("Modes") {
                VStack(alignment: .leading, spacing: 6) {
                    ModeRow(label: "Dominant",    on: vm.dominantOn)
                    ModeRow(label: "Rotation",    on: vm.rotationOn)
                    ModeRow(label: "Translation", on: vm.translationOn)
                }
                .padding(.vertical, 4)
            }

            GroupBox("Sensitivities") {
                VStack(alignment: .leading, spacing: 6) {
                    SensRow(label: "Rotation",    value: vm.rotQuality)
                    SensRow(label: "Translation", value: vm.transQuality)
                    SensRow(label: "Null Radius", value: vm.nullRadius)
                }
                .padding(.vertical, 4)
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Reusable rows

private struct ModeRow: View {
    let label: String
    let on: Bool

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(on ? Color.primary : Color.secondary)
            Spacer()
            Text(on ? "✓" : "✗")
                .foregroundStyle(on ? Color.primary : Color.secondary)
        }
    }
}

private struct SensRow: View {
    let label: String
    let value: Int

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(Color.primary)
            Spacer()
            Text("\(value) / 15")
                .monospacedDigit()
                .foregroundStyle(Color.secondary)
        }
    }
}
