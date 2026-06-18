import SwiftUI
import SwiftData

/// Sheet to switch the active dog, or jump to adding a new one.
struct DogPickerSheet: View {
    let dogs: [Dog]
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @State private var showAdd = false

    private var activeDog: Dog? { DogManager.activeDog(from: dogs) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(dogs) { dog in
                            Button {
                                DogManager.setActive(dog, in: dogs, context: context)
                                Haptics.selection(enabled: settings.hapticsEnabled)
                                dismiss()
                            } label: {
                                Card {
                                    HStack(spacing: 14) {
                                        DogAvatar(dog: dog, size: 48)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(dog.name)
                                                .font(Theme.rounded(17, .bold))
                                                .foregroundStyle(Theme.ink)
                                            if !dog.breed.isEmpty {
                                                Text(dog.breed)
                                                    .font(Theme.rounded(13))
                                                    .foregroundStyle(Theme.inkSoft)
                                            }
                                        }
                                        Spacer()
                                        if dog.id == activeDog?.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 22))
                                                .foregroundStyle(Theme.accent)
                                        }
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Choose dog")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
