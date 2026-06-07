import SwiftUI
import SwiftData

struct PieceEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Glaze.name) private var glazes: [Glaze]
    let existing: Piece?

    @State private var title = ""
    @State private var clayBody = ""
    @State private var formingMethod = "Wheel"
    @State private var stage = "Greenware"
    @State private var glazeName = ""
    @State private var heightCm = 0.0
    @State private var widthCm = 0.0
    @State private var notes = ""

    private let methods = ["Wheel", "Handbuilt", "Slipcast", "Other"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if existing != nil { stageCard }
                    basicsCard
                    dimsCard
                    notesCard
                }
                .padding()
            }
            .navigationTitle(existing == nil ? "New Piece" : "Edit Piece")
            .navigationBarTitleDisplayMode(.inline)
            .background(Brand.pageBackground)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private var stageCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Stage")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Piece.stages, id: \.self) { s in
                        Button { stage = s; Haptics.selection() } label: {
                            Text(s).font(.caption.weight(.medium))
                                .foregroundStyle(stage == s ? Brand.text : Brand.text2)
                                .padding(.horizontal, 12).padding(.vertical, 7)
                                .background((stage == s ? Brand.live.opacity(0.2) : Brand.hairline.opacity(0.5)), in: Capsule())
                        }
                    }
                }
            }
            if let next = nextStage {
                Button {
                    withAnimation { stage = next }; Haptics.success()
                } label: { Label("Advance to \(next)", systemImage: "arrow.right.circle.fill").frame(maxWidth: .infinity) }
                .buttonStyle(InkButtonStyle())
            }
        }
        .glassCard()
    }

    private var nextStage: String? {
        guard let i = Piece.stages.firstIndex(of: stage), i < Piece.stages.count - 1 else { return nil }
        return Piece.stages[i + 1]
    }

    private var basicsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Title", text: $title).font(.headline).foregroundStyle(Brand.text)
            Divider().overlay(Brand.hairline)
            TextField("Clay body", text: $clayBody).font(.subheadline).foregroundStyle(Brand.text2)
            Divider().overlay(Brand.hairline)
            HStack {
                Text("Forming").foregroundStyle(Brand.text2); Spacer()
                Picker("Forming", selection: $formingMethod) { ForEach(methods, id: \.self) { Text($0).tag($0) } }.tint(Brand.text)
            }
            Divider().overlay(Brand.hairline)
            HStack {
                Text("Glaze").foregroundStyle(Brand.text2); Spacer()
                Picker("Glaze", selection: $glazeName) {
                    Text("None").tag("")
                    ForEach(glazes.map { $0.name }, id: \.self) { Text($0).tag($0) }
                    if !glazeName.isEmpty && !glazes.map({ $0.name }).contains(glazeName) {
                        Text(glazeName).tag(glazeName)
                    }
                }.tint(Brand.text)
            }
        }
        .font(.subheadline).glassCard()
    }

    private var dimsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Dimensions (cm)")
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Height").font(.caption).foregroundStyle(Brand.text3)
                    TextField("0", value: $heightCm, format: .number).keyboardType(.decimalPad)
                        .font(Brand.mono(15)).foregroundStyle(Brand.text)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Width").font(.caption).foregroundStyle(Brand.text3)
                    TextField("0", value: $widthCm, format: .number).keyboardType(.decimalPad)
                        .font(Brand.mono(15)).foregroundStyle(Brand.text)
                }
            }
        }
        .glassCard()
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(text: "Notes")
            TextField("Throwing weight, decoration, issues…", text: $notes, axis: .vertical)
                .lineLimit(2...6).font(.subheadline).foregroundStyle(Brand.text)
        }.glassCard()
    }

    private func load() {
        guard let p = existing else { return }
        title = p.title; clayBody = p.clayBody; formingMethod = p.formingMethod
        stage = p.stage; glazeName = p.glazeName; heightCm = p.heightCm; widthCm = p.widthCm; notes = p.notes
    }

    private func save() {
        let t = title.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        let p: Piece
        if let existing { p = existing } else { p = Piece(title: t); context.insert(p) }
        p.title = t; p.clayBody = clayBody; p.formingMethod = formingMethod; p.stage = stage
        p.glazeName = glazeName; p.heightCm = max(0, heightCm); p.widthCm = max(0, widthCm); p.notes = notes
        p.updatedAt = Date()
        try? context.save(); Haptics.success(); dismiss()
    }
}
