import SwiftUI

struct PacksView: View {
    @State private var selectedPack: WordPack? = nil
    @State private var showingProSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Free packs section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "gift.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(ScrawlTheme.successGreen)
                            Text("Free Packs")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(ScrawlTheme.primaryText)
                        }

                        ForEach(WordPackLibrary.allPacks.filter { !$0.isPro }) { pack in
                            PackCard(pack: pack, isPro: false) {
                                selectedPack = pack
                            }
                        }
                    }

                    // Pro packs section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(ScrawlTheme.warningOrange)
                            Text("Pro Packs")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(ScrawlTheme.primaryText)

                            Spacer()

                            Text("$2.99 one-time")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(ScrawlTheme.warningOrange)
                                .cornerRadius(8)
                        }

                        ForEach(WordPackLibrary.allPacks.filter { $0.isPro }) { pack in
                            PackCard(pack: pack, isPro: true) {
                                showingProSheet = true
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(ScrawlTheme.background.ignoresSafeArea())
            .navigationTitle("Word Packs")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedPack) { pack in
                PackDetailView(pack: pack)
            }
            .sheet(isPresented: $showingProSheet) {
                ProUpgradeView()
            }
        }
    }
}

struct PackCard: View {
    let pack: WordPack
    let isPro: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Emoji circle
                ZStack {
                    Circle()
                        .fill(isPro ? ScrawlTheme.warningOrange.opacity(0.15) : ScrawlTheme.skyBlue.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Text(pack.emoji)
                        .font(.system(size: 26))
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(pack.name)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(ScrawlTheme.primaryText)

                        if isPro {
                            Text("PRO")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(ScrawlTheme.warningOrange)
                                .cornerRadius(5)
                        }
                    }

                    Text(pack.description)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(ScrawlTheme.secondaryText)
                        .lineLimit(1)

                    Text("\(pack.wordCount) words")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(isPro ? ScrawlTheme.warningOrange : ScrawlTheme.skyBlue)
                }

                Spacer()

                Image(systemName: isPro ? "lock.fill" : "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isPro ? ScrawlTheme.warningOrange : ScrawlTheme.secondaryText)
            }
            .padding(16)
            .scrawlCard()
        }
        .accessibilityLabel("\(pack.name) pack, \(pack.wordCount) words\(isPro ? ", Pro required" : "")")
    }
}

struct PackDetailView: View {
    let pack: WordPack
    @Environment(\.dismiss) private var dismiss

    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Pack header
                    VStack(spacing: 8) {
                        Text(pack.emoji)
                            .font(.system(size: 56))
                        Text(pack.name)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(ScrawlTheme.primaryText)
                        Text(pack.description)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundStyle(ScrawlTheme.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 24)

                    // Words grid
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(pack.words, id: \.self) { word in
                            Text(word)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(ScrawlTheme.primaryText)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(ScrawlTheme.cardBackground)
                                .cornerRadius(10)
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
            .background(ScrawlTheme.background.ignoresSafeArea())
            .navigationTitle("\(pack.wordCount) Words")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(ScrawlTheme.skyBlue)
                }
            }
        }
    }
}

struct ProUpgradeView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(ScrawlTheme.warningOrange.opacity(0.15))
                            .frame(width: 120, height: 120)
                        Text("⭐")
                            .font(.system(size: 60))
                    }
                    .padding(.top, 20)

                    VStack(spacing: 10) {
                        Text("Scrawl Pro")
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .foregroundStyle(ScrawlTheme.primaryText)

                        Text("One-time purchase. No subscription.")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(ScrawlTheme.secondaryText)
                    }

                    // Features list
                    VStack(spacing: 12) {
                        ProFeatureRow(icon: "rectangle.stack.fill", color: ScrawlTheme.skyBlue, text: "All 5 word packs (200+ words)")
                        ProFeatureRow(icon: "plus.square.fill", color: ScrawlTheme.coral, text: "Unlimited custom word lists")
                        ProFeatureRow(icon: "person.3.fill", color: ScrawlTheme.successGreen, text: "Up to 8 teams")
                        ProFeatureRow(icon: "infinity", color: ScrawlTheme.warningOrange, text: "All future packs included")
                        ProFeatureRow(icon: "xmark.shield.fill", color: .purple, text: "No ads, no watermarks ever")
                    }
                    .padding(.horizontal, 24)

                    // Price button
                    VStack(spacing: 12) {
                        Button {
                            // In-app purchase would go here
                            dismiss()
                        } label: {
                            VStack(spacing: 4) {
                                Text("Unlock Scrawl Pro")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                Text("$2.99 — one-time")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .opacity(0.85)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(ScrawlTheme.warningOrange)
                            .cornerRadius(20)
                            .shadow(color: ScrawlTheme.warningOrange.opacity(0.4), radius: 12, x: 0, y: 6)
                        }

                        Button {
                            // Restore purchase
                        } label: {
                            Text("Restore Purchase")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(ScrawlTheme.secondaryText)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .background(ScrawlTheme.background.ignoresSafeArea())
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(ScrawlTheme.secondaryText)
                }
            }
        }
    }
}

struct ProFeatureRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(color)
            }

            Text(text)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(ScrawlTheme.primaryText)

            Spacer()
        }
    }
}
