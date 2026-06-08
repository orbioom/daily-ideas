import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context

    @State private var step = 0
    @State private var names = ""
    @State private var date = Calendar.current.date(byAdding: .month, value: 8, to: .now) ?? .now
    @State private var venue = ""
    @State private var budgetText = ""
    @State private var currency = Locale.current.currency?.identifier ?? "USD"
    @State private var addChecklist = true
    @State private var addSample = false

    private let currencies = ["USD", "EUR", "GBP", "CAD", "AUD", "INR", "JPY", "BRL", "MXN", "ZAR", "NGN"]
    private var canFinish: Bool { !names.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $step) {
                welcome.tag(0)
                details.tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack(spacing: 10) {
                Button(step == 0 ? "Begin planning" : "Create our plan") {
                    if step == 0 { withAnimation(Brand.ease()) { step = 1 } }
                    else { finish() }
                }
                .buttonStyle(InkButtonStyle())
                .disabled(step == 1 && !canFinish)
                if step == 1 {
                    Button("Back") { withAnimation(Brand.ease()) { step = 0 } }
                        .font(.subheadline.weight(.medium)).foregroundStyle(Brand.text2)
                }
            }
            .padding(.horizontal, 28).padding(.bottom, 24)
        }
    }

    private var welcome: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(Color(hex: 0xB07A8C)).accessibilityHidden(true)
            Text("Aisle").font(.largeTitle.weight(.bold)).foregroundStyle(Brand.text)
            Text("Guests, budget, seating, and the whole checklist — your wedding, beautifully organized and private to you two.")
                .font(.body).foregroundStyle(Brand.text2)
                .multilineTextAlignment(.center).padding(.horizontal, 36)
            Spacer()
        }
        .padding()
    }

    private var details: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("The basics").font(.title.weight(.bold)).foregroundStyle(Brand.text)

                field("Couple names", text: $names, placeholder: "e.g. Alex & Sam", keyboard: .default)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Wedding date").font(.caption).foregroundStyle(Brand.text3)
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .labelsHidden().datePickerStyle(.compact)
                }
                field("Venue (optional)", text: $venue, placeholder: "Where", keyboard: .default)
                field("Total budget", text: $budgetText, placeholder: "0", keyboard: .decimalPad)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Currency").font(.caption).foregroundStyle(Brand.text3)
                    Picker("Currency", selection: $currency) {
                        ForEach(currencies, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu).frame(maxWidth: .infinity, alignment: .leading)
                }

                Toggle("Add a standard planning checklist", isOn: $addChecklist)
                    .tint(Color(hex: 0xB07A8C))
                Toggle("Add sample guests & budget", isOn: $addSample)
                    .tint(Color(hex: 0xB07A8C))
            }
            .padding()
        }
    }

    private func field(_ label: String, text: Binding<String>, placeholder: String, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.caption).foregroundStyle(Brand.text3)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .padding(12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func finish() {
        let trimmed = names.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let budget = Double(budgetText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let wedding = Wedding(coupleNames: trimmed, weddingDate: date, venue: venue,
                              totalBudget: budget, currencyCode: currency)
        context.insert(wedding)
        try? context.save()
        if addChecklist { SeedData.seedChecklist(context, weddingDate: date) }
        if addSample { SeedData.seedSample(context) }
        Haptics.success()
    }
}
