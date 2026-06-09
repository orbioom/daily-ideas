import SwiftUI

struct OnboardingView: View {
    @AppStorage("limber.onboarded") private var onboarded = false
    @AppStorage("limber.goalMinutes") private var goalMinutes = 10
    @State private var page = 0

    private let pages: [(icon: String, title: String, body: String)] = [
        ("figure.flexibility", "Move a little, often",
         "Limber turns stretching into a calm daily habit — guided, timed, and never overwhelming."),
        ("list.bullet.rectangle.portrait", "Routines that fit your day",
         "Start with built-in flows like Desk Reset and Morning Wake-Up, or build your own from 25 stretches."),
        ("timer", "Just press play",
         "A full-screen guided session counts every hold for you, with both-sides cues and gentle haptics.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { i in
                    pageView(pages[i]).tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            if page == pages.count - 1 {
                goalPicker
            }

            controls
        }
        .padding(24)
        .accessibilityElement(children: .contain)
    }

    private func pageView(_ p: (icon: String, title: String, body: String)) -> some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: p.icon)
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(Brand.magic)
                .accessibilityHidden(true)
            Text(p.title)
                .font(.title.weight(.bold))
                .foregroundStyle(Brand.text)
                .multilineTextAlignment(.center)
            Text(p.body)
                .font(.body)
                .foregroundStyle(Brand.text2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
            Spacer()
        }
    }

    private var goalPicker: some View {
        VStack(spacing: 10) {
            Eyebrow(text: "Daily goal")
            HStack(spacing: 10) {
                ForEach([5, 10, 15, 20], id: \.self) { m in
                    Button {
                        goalMinutes = m
                        Haptics.selection()
                    } label: {
                        Text("\(m)m")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(goalMinutes == m ? Brand.magic.opacity(0.22) : Color.clear,
                                        in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(goalMinutes == m ? Brand.magic : Brand.hairline, lineWidth: 1))
                            .foregroundStyle(Brand.text)
                    }
                    .accessibilityLabel("\(m) minutes a day")
                    .accessibilityAddTraits(goalMinutes == m ? .isSelected : [])
                }
            }
        }
        .glassCard()
        .padding(.bottom, 8)
    }

    private var controls: some View {
        VStack(spacing: 14) {
            Button(page == pages.count - 1 ? "Start stretching" : "Continue") {
                if page == pages.count - 1 {
                    Haptics.success()
                    onboarded = true
                } else {
                    withAnimation(Brand.ease()) { page += 1 }
                }
            }
            .buttonStyle(InkButtonStyle())

            HStack(spacing: 7) {
                ForEach(pages.indices, id: \.self) { i in
                    Circle()
                        .fill(i == page ? Brand.text : Brand.text3.opacity(0.4))
                        .frame(width: 7, height: 7)
                }
            }
            .accessibilityHidden(true)
        }
    }
}
