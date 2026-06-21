import SwiftUI
import SwiftData

struct DailyLogView: View {
    @Query private var allEntries: [BulletEntry]
    @Query private var settingsArr: [RectoSettings]
    @Environment(\.modelContext) private var ctx
    @State private var vm = DailyLogViewModel()
    @FocusState private var isTextFieldFocused: Bool

    private var settings: RectoSettings? { settingsArr.first }
    private var fontStyle: String { settings?.fontStyle ?? "sans" }
    private var showDateHeader: Bool { settings?.showDateHeader ?? true }
    private var hapticEnabled: Bool { settings?.hapticEnabled ?? true }

    private var dailyEntries: [BulletEntry] {
        vm.entriesForDate(vm.selectedDate, all: allEntries)
    }

    private static let fullDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f
    }()

    private static let yearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy"
        return f
    }()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                RectoTheme.paperBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Date navigation header
                    dateNavigationHeader

                    Divider()
                        .overlay(RectoTheme.ruleLineColor)

                    if dailyEntries.isEmpty && !vm.isAddingEntry {
                        EmptyStateView(
                            icon: "book.pages",
                            title: "Nothing logged yet",
                            subtitle: "Tap the + button below to start\nrapid logging your day.",
                            actionTitle: "Add First Entry",
                            action: {
                                vm.isAddingEntry = true
                                isTextFieldFocused = true
                            }
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(dailyEntries) { entry in
                                    BulletRowView(
                                        entry: entry,
                                        fontStyle: fontStyle,
                                        onToggleComplete: {
                                            if hapticEnabled {
                                                let gen = UIImpactFeedbackGenerator(style: .light)
                                                gen.impactOccurred()
                                            }
                                            vm.toggleComplete(entry, context: ctx)
                                        },
                                        onToggleStar: {
                                            vm.toggleStar(entry, context: ctx)
                                        }
                                    )
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            vm.delete(entry, context: ctx)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }

                                        if entry.bulletTypeEnum == .task && entry.statusEnum != .irrelevant {
                                            Button {
                                                vm.markIrrelevant(entry, context: ctx)
                                            } label: {
                                                Label("Dismiss", systemImage: "xmark.circle")
                                            }
                                            .tint(.gray)
                                        }
                                    }
                                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                        if entry.bulletTypeEnum == .task
                                            && entry.statusEnum == .open
                                            && !Calendar.current.isDateInToday(vm.selectedDate) {
                                            Button {
                                                vm.migrate(entry, context: ctx)
                                                if hapticEnabled {
                                                    let gen = UINotificationFeedbackGenerator()
                                                    gen.notificationOccurred(.success)
                                                }
                                            } label: {
                                                Label("Migrate", systemImage: "arrow.right.circle")
                                            }
                                            .tint(RectoTheme.taskColor)
                                        }
                                    }

                                    Divider()
                                        .padding(.leading, 52)
                                        .overlay(RectoTheme.ruleLineColor.opacity(0.6))
                                }

                                // Spacer for the add bar
                                Color.clear.frame(height: 80)
                            }
                        }
                    }
                }

                // Add entry bar (floating at bottom)
                addEntryBar
                    .background(RectoTheme.paperBackground.opacity(0.97))
                    .overlay(alignment: .top) {
                        Divider().overlay(RectoTheme.ruleLineColor)
                    }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Date Navigation Header
    private var dateNavigationHeader: some View {
        HStack(spacing: 0) {
            Button {
                vm.navigateDay(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(RectoTheme.inkPrimary)
                    .padding(12)
                    .contentShape(Rectangle())
            }

            Spacer()

            VStack(spacing: 2) {
                if showDateHeader {
                    if vm.isToday {
                        Text("Today")
                            .font(.system(size: 20, weight: .bold, design: fontStyle == "serif" ? .serif : .default))
                            .foregroundStyle(RectoTheme.inkPrimary)
                    } else {
                        Text(Self.fullDateFormatter.string(from: vm.selectedDate))
                            .font(.system(size: 17, weight: .semibold, design: fontStyle == "serif" ? .serif : .default))
                            .foregroundStyle(RectoTheme.inkPrimary)
                    }
                    Text(Self.yearFormatter.string(from: vm.selectedDate))
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(RectoTheme.inkSecondary)
                }
            }
            .onTapGesture {
                vm.jumpToToday()
            }

            Spacer()

            Button {
                vm.navigateDay(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(RectoTheme.inkPrimary)
                    .padding(12)
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 4)
        .frame(height: 56)
        .background(RectoTheme.paperBackground)
    }

    // MARK: - Add Entry Bar
    private var addEntryBar: some View {
        VStack(spacing: 0) {
            if vm.isAddingEntry {
                // Bullet type picker
                Picker("Type", selection: $vm.newBulletType) {
                    ForEach(BulletType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 10)

                HStack(spacing: 12) {
                    // Symbol preview
                    Text(bulletSymbol(for: vm.newBulletType))
                        .font(.system(size: 22, weight: .semibold, design: .serif))
                        .foregroundStyle(RectoTheme.bulletColor(for: vm.newBulletType))
                        .frame(width: 28)

                    TextField("Add entry…", text: $vm.newEntryText, axis: .vertical)
                        .font(.system(size: 16, weight: .regular, design: fontStyle == "serif" ? .serif : .default))
                        .focused($isTextFieldFocused)
                        .lineLimit(1...4)
                        .submitLabel(.done)
                        .onSubmit {
                            vm.addEntry(context: ctx, all: allEntries)
                        }

                    Button {
                        vm.addEntry(context: ctx, all: allEntries)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(
                                vm.newEntryText.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Color(red: 0.75, green: 0.73, blue: 0.70)
                                : RectoTheme.inkPrimary
                            )
                    }
                    .disabled(vm.newEntryText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            } else {
                HStack {
                    Spacer()
                    Button {
                        vm.isAddingEntry = true
                        isTextFieldFocused = true
                    } label: {
                        Label("Add Entry", systemImage: "plus")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(RectoTheme.inkPrimary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.7))
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                    }
                    Spacer()
                }
                .padding(.vertical, 12)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: vm.isAddingEntry)
    }
}

// Helper — compute bullet symbol without creating a model instance
private func bulletSymbol(for type: BulletType) -> String {
    switch type {
    case .task: return "•"
    case .event: return "○"
    case .note: return "–"
    }
}
