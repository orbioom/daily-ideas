import SwiftUI
import SwiftData
import LocalAuthentication

struct VaultSettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var settingsQ: [VaultSettings]
    @State private var showChangePIN = false
    @State private var showClearAlert = false
    @State private var biometricsAvailable = false
    @State private var storageUsed = 0.0

    private var settings: VaultSettings? { settingsQ.first }

    var body: some View {
        NavigationStack {
            List {
                Section("Security") {
                    if biometricsAvailable {
                        Toggle("Face ID / Touch ID", isOn: Binding(
                            get: { settings?.useBiometrics ?? true },
                            set: { settings?.useBiometrics = $0; try? context.save() }
                        ))
                        .accessibilityLabel("Enable Face ID or Touch ID")
                    }

                    Picker("Auto-Lock", selection: Binding(
                        get: { settings?.autoLockMinutes ?? 1 },
                        set: { settings?.autoLockMinutes = $0; try? context.save() }
                    )) {
                        Text("Immediately").tag(0)
                        Text("After 1 min").tag(1)
                        Text("After 5 min").tag(5)
                        Text("After 15 min").tag(15)
                        Text("Never").tag(-1)
                    }
                    .accessibilityLabel("Auto-lock timing")

                    Button(action: { showChangePIN = true }) {
                        Label("Change PIN", systemImage: "lock.rotation")
                    }
                    .accessibilityLabel("Change PIN")
                }

                Section("Display") {
                    Toggle("Show Photo Count on Albums", isOn: Binding(
                        get: { settings?.showPhotoCount ?? true },
                        set: { settings?.showPhotoCount = $0; try? context.save() }
                    ))
                    .accessibilityLabel("Show photo count")

                    Picker("Grid Columns", selection: Binding(
                        get: { settings?.gridColumns ?? 3 },
                        set: { settings?.gridColumns = $0; try? context.save() }
                    )) {
                        Text("2 Columns").tag(2)
                        Text("3 Columns").tag(3)
                        Text("4 Columns").tag(4)
                    }
                    .accessibilityLabel("Photo grid columns")
                }

                Section("Storage") {
                    HStack {
                        Text("Photos Storage Used")
                        Spacer()
                        Text(String(format: "%.1f MB", storageUsed))
                            .foregroundColor(VaultTheme.secondaryLabel)
                    }
                    .accessibilityLabel("Storage used: \(String(format: "%.1f", storageUsed)) megabytes")
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0").foregroundColor(VaultTheme.secondaryLabel)
                    }
                }

                Section {
                    Button(role: .destructive) { showClearAlert = true } label: {
                        Label("Delete All Photos", systemImage: "trash")
                    }
                    .accessibilityLabel("Delete all photos from Vault")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                let ctx = LAContext()
                var err: NSError?
                biometricsAvailable = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err)
                storageUsed = VaultPhotoStore.shared.storageUsedMB()
            }
            .alert("Delete All Photos?", isPresented: $showClearAlert) {
                Button("Delete Everything", role: .destructive) { clearAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("All albums and photos will be permanently deleted from this device.")
            }
            .sheet(isPresented: $showChangePIN) { ChangePINView() }
        }
    }

    private func clearAll() {
        try? context.delete(model: VaultAlbum.self)
        try? context.delete(model: VaultPhoto.self)
        try? context.save()
        storageUsed = 0
    }
}

struct ChangePINView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var settingsQ: [VaultSettings]
    @State private var currentPin = ""
    @State private var newPin = ""
    @State private var confirmPin = ""
    @State private var step = 0
    @State private var error = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 32) {
                    Text(stepTitle).font(.title2.bold()).foregroundColor(.white)
                    if !error.isEmpty { Text(error).foregroundColor(.red).font(.caption) }
                    HStack(spacing: 16) {
                        ForEach(0..<4) { i in
                            Circle()
                                .fill(i < activePin.count ? VaultTheme.gold : Color.white.opacity(0.3))
                                .frame(width: 16, height: 16)
                        }
                    }
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                        ForEach(["1","2","3","4","5","6","7","8","9","","0","⌫"], id: \.self) { key in
                            if key.isEmpty { Color.clear.frame(height: 60) }
                            else {
                                Button(action: { handleKey(key) }) {
                                    Text(key).font(.title.weight(.medium)).foregroundColor(.white)
                                        .frame(maxWidth: .infinity).frame(height: 60)
                                        .background(Circle().fill(Color.white.opacity(0.1)))
                                }
                            }
                        }
                    }.padding(.horizontal, 48)
                }
            }
            .navigationTitle("Change PIN")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(.white)
                }
            }
        }
    }

    private var stepTitle: String {
        switch step {
        case 0: return "Enter Current PIN"
        case 1: return "Enter New PIN"
        default: return "Confirm New PIN"
        }
    }

    private var activePin: String {
        switch step { case 0: return currentPin; case 1: return newPin; default: return confirmPin }
    }

    private func handleKey(_ key: String) {
        error = ""
        var current: String
        switch step { case 0: current = currentPin; case 1: current = newPin; default: current = confirmPin }
        if key == "⌫" { if !current.isEmpty { current.removeLast() } }
        else if current.count < 4 { current.append(key) }
        switch step { case 0: currentPin = current; case 1: newPin = current; default: confirmPin = current }

        if current.count == 4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { advance() }
        }
    }

    private func advance() {
        switch step {
        case 0:
            guard let s = settingsQ.first, currentPin.vaultPINHash() == s.pinHash else {
                error = "Incorrect PIN"; currentPin = ""; return
            }
            step = 1
        case 1:
            step = 2
        default:
            if newPin == confirmPin {
                settingsQ.first?.pinHash = newPin.vaultPINHash()
                try? context.save()
                dismiss()
            } else {
                error = "PINs don't match"; newPin = ""; confirmPin = ""; step = 1
            }
        }
    }
}
