import SwiftUI

struct AddParticipantSheet: View {
    @ObservedObject var vm: MeetingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var filtered: [(city: String, tz: String)] {
        query.isEmpty ? TimeZoneCatalog.cities
            : TimeZoneCatalog.cities.filter { $0.city.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                OrbMistBackground()
                List {
                    ForEach(filtered, id: \.tz) { item in
                        Button {
                            vm.add(city: item.city, tz: item.tz)
                            dismiss()
                        } label: {
                            HStack {
                                Text(item.city).foregroundStyle(Color.orbInk)
                                Spacer()
                                Text(item.tz).font(.caption2.monospaced())
                                    .foregroundStyle(Color.orbText3)
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.4))
                    }
                }
                .scrollContentBackground(.hidden)
                .searchable(text: $query, prompt: "Find a city")
            }
            .navigationTitle("Add a place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
