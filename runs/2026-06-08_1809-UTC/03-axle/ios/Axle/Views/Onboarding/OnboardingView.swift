import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @State private var showForm = false

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: "car.fill")
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(Color(hex: 0x4E6BA8))
                .accessibilityHidden(true)
            Text("Axle")
                .font(.largeTitle.weight(.bold)).foregroundStyle(Brand.text)
            Text("Every fill-up, service, and reminder for your car — tracked beautifully, kept entirely on your device.")
                .font(.body).foregroundStyle(Brand.text2)
                .multilineTextAlignment(.center).padding(.horizontal, 36)

            VStack(spacing: 12) {
                FeatureRow(icon: "fuelpump", text: "True fuel economy, partial-fill aware")
                FeatureRow(icon: "bell.badge", text: "Reminders by distance or date")
                FeatureRow(icon: "chart.bar", text: "Running cost, on your terms")
            }
            .padding(.top, 6)

            Spacer()

            Button("Add my car") { showForm = true }
                .buttonStyle(InkButtonStyle())
            Button("Explore with sample data") {
                SeedData.seedSampleVehicle(context)
                Haptics.success()
            }
            .font(.subheadline.weight(.medium)).foregroundStyle(Brand.text2)
        }
        .padding(28)
        .sheet(isPresented: $showForm) {
            VehicleEditorView(mode: .create)
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(Color(hex: 0x4E6BA8)).frame(width: 26)
            Text(text).font(.subheadline).foregroundStyle(Brand.text2)
            Spacer()
        }
        .padding(.horizontal, 30)
    }
}
