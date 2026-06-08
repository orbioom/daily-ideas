import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context

    @State private var step = 0
    @State private var dueDate = Calendar.current.date(byAdding: .day, value: 140, to: .now) ?? .now
    @State private var knowsLMP = false
    @State private var lmpDate = Calendar.current.date(byAdding: .day, value: -140, to: .now) ?? .now
    @State private var babyName = ""
    @State private var weightText = ""
    @State private var heightText = ""
    @State private var isMultiple = false

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $step) {
                welcome.tag(0)
                dateStep.tag(1)
                detailsStep.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            footer
        }
    }

    private var welcome: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(Color(hex: 0x9A6FB0))
                .accessibilityHidden(true)
            Text("Welcome to Bloom")
                .font(.largeTitle.weight(.bold)).foregroundStyle(Brand.text)
            Text("A calm, private week-by-week companion for your pregnancy — entirely on your device.")
                .font(.body).foregroundStyle(Brand.text2)
                .multilineTextAlignment(.center).padding(.horizontal, 32)
            Spacer()
        }
        .padding()
    }

    private var dateStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("When is baby due?")
                    .font(.title.weight(.bold)).foregroundStyle(Brand.text)
                Text("If you're not sure, switch on the last-period option and we'll estimate it.")
                    .font(.subheadline).foregroundStyle(Brand.text2)

                Toggle("I know my last period date", isOn: $knowsLMP.animation())
                    .tint(Color(hex: 0x9A6FB0))

                if knowsLMP {
                    DatePicker("Last period started",
                               selection: $lmpDate,
                               in: ...Date(),
                               displayedComponents: .date)
                        .datePickerStyle(.compact)
                    LabeledContent("Estimated due date", value: Format.shortDate.string(from: estimatedDue))
                        .font(.subheadline)
                } else {
                    DatePicker("Due date", selection: $dueDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .tint(Color(hex: 0x9A6FB0))
                }
            }
            .padding()
        }
    }

    private var detailsStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("A few optional details")
                    .font(.title.weight(.bold)).foregroundStyle(Brand.text)
                Text("These power your personalized weight-gain range. You can skip and add later.")
                    .font(.subheadline).foregroundStyle(Brand.text2)

                field("Baby's nickname", text: $babyName, keyboard: .default, placeholder: "e.g. Little one")
                field("Pre-pregnancy weight (kg)", text: $weightText, keyboard: .decimalPad, placeholder: "kg")
                field("Height (cm)", text: $heightText, keyboard: .decimalPad, placeholder: "cm")

                Toggle("Expecting multiples (twins+)", isOn: $isMultiple)
                    .tint(Color(hex: 0x9A6FB0))
            }
            .padding()
        }
    }

    private func field(_ label: String, text: Binding<String>, keyboard: UIKeyboardType, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.caption).foregroundStyle(Brand.text3)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .padding(12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var estimatedDue: Date {
        Calendar.current.date(byAdding: .day, value: 280, to: lmpDate) ?? dueDate
    }

    private var footer: some View {
        VStack(spacing: 10) {
            Button(step < 2 ? "Continue" : "Start tracking") {
                if step < 2 {
                    withAnimation(Brand.ease()) { step += 1 }
                } else {
                    finish()
                }
            }
            .buttonStyle(InkButtonStyle())
            if step > 0 {
                Button("Back") { withAnimation(Brand.ease()) { step -= 1 } }
                    .font(.subheadline.weight(.medium)).foregroundStyle(Brand.text2)
            }
        }
        .padding(.horizontal, 28).padding(.bottom, 24)
    }

    private func finish() {
        let resolvedDue = knowsLMP ? estimatedDue : dueDate
        let weight = Double(weightText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let height = Double(heightText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let pregnancy = Pregnancy(babyName: babyName.trimmingCharacters(in: .whitespaces),
                                  dueDate: resolvedDue,
                                  prePregnancyWeightKg: max(0, weight),
                                  heightCm: max(0, height),
                                  isMultiple: isMultiple)
        context.insert(pregnancy)
        try? context.save()
        SeedData.seedLogs(context, pregnancy: pregnancy)
        Haptics.success()
    }
}
