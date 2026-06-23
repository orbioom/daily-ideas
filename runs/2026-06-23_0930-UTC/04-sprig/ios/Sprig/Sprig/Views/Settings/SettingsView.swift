import SwiftUI
import SwiftData

/// Settings: babies management, units, haptics, delete confirmation, Pro, about.
struct SettingsView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var context
    @Query(sort: \Baby.createdAt) private var babies: [Baby]

    @AppStorage(PrefKey.volumeUnit) private var volumeUnitRaw = VolumeUnit.oz.rawValue
    @AppStorage(PrefKey.weightUnit) private var weightUnitRaw = WeightUnit.kg.rawValue
    @AppStorage(PrefKey.lengthUnit) private var lengthUnitRaw = LengthUnit.cm.rawValue
    @AppStorage(PrefKey.hapticsEnabled) private var haptics = true
    @AppStorage(PrefKey.confirmDelete) private var confirmDelete = true
    @AppStorage(PrefKey.isPro) private var isPro = false
    @AppStorage(PrefKey.activeBabyID) private var activeBabyIDString = ""

    @State private var addBaby = false
    @State private var editBaby: Baby?
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.ambientGradient(scheme).ignoresSafeArea()
                Form {
                    babiesSection
                    unitsSection
                    behaviorSection
                    proSection
                    aboutSection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $addBaby) { BabyEditorView(baby: nil) }
            .sheet(item: $editBaby) { baby in BabyEditorView(baby: baby) }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    // MARK: Babies

    private var babiesSection: some View {
        Section("Babies") {
            ForEach(babies) { baby in
                Button { editBaby = baby } label: {
                    HStack(spacing: 12) {
                        Circle().fill(Color(hex: baby.colorHex)).frame(width: 28, height: 28)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(baby.name).foregroundStyle(Theme.primaryText(scheme))
                            Text(Fmt.age(birth: baby.birthDate) + " old")
                                .font(.caption).foregroundStyle(Theme.secondaryText(scheme))
                        }
                        Spacer()
                        if baby.id.uuidString == effectiveActiveID {
                            Text("Active")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Theme.accent)
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption).foregroundStyle(Theme.secondaryText(scheme))
                    }
                }
            }
            Button {
                if babies.count >= 1 && !isPro {
                    showPaywall = true
                } else {
                    addBaby = true
                }
            } label: {
                Label(canAddFree ? "Add baby" : "Add baby (Pro)", systemImage: "plus.circle.fill")
            }
        }
    }

    private var canAddFree: Bool { babies.isEmpty || isPro }

    private var effectiveActiveID: String {
        if !activeBabyIDString.isEmpty { return activeBabyIDString }
        return babies.first?.id.uuidString ?? ""
    }

    // MARK: Units

    private var unitsSection: some View {
        Section("Units") {
            Picker("Bottle volume", selection: $volumeUnitRaw) {
                Text("fl oz").tag(VolumeUnit.oz.rawValue)
                Text("mL").tag(VolumeUnit.ml.rawValue)
            }
            Picker("Weight", selection: $weightUnitRaw) {
                Text("kg").tag(WeightUnit.kg.rawValue)
                Text("lb").tag(WeightUnit.lb.rawValue)
            }
            Picker("Length", selection: $lengthUnitRaw) {
                Text("cm").tag(LengthUnit.cm.rawValue)
                Text("in").tag(LengthUnit.inch.rawValue)
            }
        }
    }

    // MARK: Behavior

    private var behaviorSection: some View {
        Section {
            Toggle(isOn: $haptics) {
                Label("Haptic feedback", systemImage: "hand.tap.fill")
            }
            .onChange(of: haptics) { _, on in if on { Haptics.success(true) } }
            Toggle(isOn: $confirmDelete) {
                Label("Confirm before deleting", systemImage: "checkmark.shield.fill")
            }
        } header: {
            Text("Behavior")
        } footer: {
            Text("Haptics give a gentle tap when you log or save. Turn off confirmation to delete with a single swipe.")
        }
    }

    // MARK: Pro

    private var proSection: some View {
        Section {
            if isPro {
                Label("Sprig Pro is active — thank you!", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(Theme.accent)
            } else {
                Button { showPaywall = true } label: {
                    Label("Unlock Sprig Pro", systemImage: "sparkles")
                }
            }
        } header: {
            Text("Pro")
        } footer: {
            Text("Core logging is always free. Pro adds unlimited baby profiles and data export — a one-time purchase, no subscription.")
        }
    }

    // MARK: About

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: "1.0")
            LabeledContent("Made for", value: "Calm parenting")
            Text("Sprig is a private, on-device baby tracker. Your data never leaves your phone.")
                .font(.caption)
                .foregroundStyle(Theme.secondaryText(scheme))
        }
    }
}
