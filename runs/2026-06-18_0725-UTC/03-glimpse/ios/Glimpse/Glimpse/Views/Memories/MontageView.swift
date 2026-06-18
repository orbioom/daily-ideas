import SwiftUI
import SwiftData

/// Pro feature: pick a month, render its moments into a mosaic image, then
/// share or save it. Uses ImageRenderer over a fixed-size grid.
struct MontageView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    let moments: [Moment]

    @State private var monthDate = Calendar.current.startOfDay(for: Date())
    @State private var rendered: ShareableImage?
    @State private var isRendering = false
    @State private var saveResult: ToastState?

    private let calendar = Calendar.current

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    private var monthMoments: [Moment] {
        moments
            .filter { calendar.isDate($0.displayDate, equalTo: monthDate, toGranularity: .month) }
            .sorted { $0.displayDate < $1.displayDate }
    }

    private var isCurrentMonth: Bool {
        calendar.isDate(monthDate, equalTo: Date(), toGranularity: .month)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    monthPicker
                    preview
                    if monthMoments.isEmpty {
                        Text("No moments in this month yet. Pick another to build a montage.")
                            .font(Theme.bodyFont)
                            .foregroundStyle(Theme.inkSoft)
                            .multilineTextAlignment(.center)
                            .padding(.top, 20)
                    } else {
                        PrimaryButton(title: isRendering ? "Rendering…" : "Create montage image", symbol: "wand.and.stars") {
                            render()
                        }
                        .disabled(isRendering)
                    }
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Month montage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $rendered) { item in
                ShareSheet(image: item.image)
            }
            .toast($saveResult)
        }
    }

    private var monthPicker: some View {
        HStack {
            Button {
                if let prev = calendar.date(byAdding: .month, value: -1, to: monthDate) {
                    monthDate = prev
                }
            } label: {
                Image(systemName: "chevron.left").font(.system(size: 16, weight: .bold))
                    .frame(width: 40, height: 40).background(Theme.surfaceAlt, in: Circle())
            }
            .accessibilityLabel("Previous month")
            Spacer()
            Text(Self.monthFormatter.string(from: monthDate))
                .font(Theme.sectionFont)
            Spacer()
            Button {
                if let next = calendar.date(byAdding: .month, value: 1, to: monthDate) {
                    monthDate = next
                }
            } label: {
                Image(systemName: "chevron.right").font(.system(size: 16, weight: .bold))
                    .frame(width: 40, height: 40).background(Theme.surfaceAlt, in: Circle())
            }
            .disabled(isCurrentMonth)
            .opacity(isCurrentMonth ? 0.35 : 1)
            .accessibilityLabel("Next month")
        }
        .foregroundStyle(Theme.ink)
    }

    private var preview: some View {
        MontageGrid(monthLabel: Self.monthFormatter.string(from: monthDate), moments: monthMoments)
            .frame(maxWidth: .infinity)
            .cardSurface()
            .accessibilityLabel("Montage preview with \(monthMoments.count) moments")
    }

    @MainActor
    private func render() {
        isRendering = true
        let grid = MontageGrid(
            monthLabel: Self.monthFormatter.string(from: monthDate),
            moments: monthMoments,
            renderSize: 1080
        )
        let renderer = ImageRenderer(content: grid)
        renderer.scale = 2
        if let image = renderer.uiImage {
            rendered = ShareableImage(image: image)
            Haptics.success(settings.hapticsEnabled)
        } else {
            saveResult = ToastState(symbol: "exclamationmark.triangle.fill", message: "Couldn't render montage")
        }
        isRendering = false
    }
}

/// The visual mosaic. Renders thumbnails for the month in a tidy grid with a
/// header. Sized so ImageRenderer produces a crisp shareable image.
struct MontageGrid: View {
    let monthLabel: String
    let moments: [Moment]
    var renderSize: CGFloat = 360

    private var columns: Int {
        switch moments.count {
        case 0...4: return 2
        case 5...9: return 3
        case 10...16: return 4
        default: return 5
        }
    }

    var body: some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: 4), count: columns)
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle().fill(Theme.accent).frame(width: renderSize * 0.04, height: renderSize * 0.04)
                Text("Glimpse · \(monthLabel)")
                    .font(.system(size: renderSize * 0.05, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Spacer()
            }
            if moments.isEmpty {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.surfaceAlt)
                    .frame(height: renderSize * 0.4)
                    .overlay(
                        Text("No moments yet")
                            .font(.system(size: renderSize * 0.04, design: .rounded))
                            .foregroundStyle(Theme.inkSoft)
                    )
            } else {
                LazyVGrid(columns: cols, spacing: 4) {
                    ForEach(moments) { moment in
                        MontageTile(moment: moment, side: renderSize / CGFloat(columns))
                    }
                }
            }
        }
        .padding(renderSize * 0.05)
        .frame(width: renderSize)
        .background(Theme.surface)
    }
}

/// A single montage tile. Loads its thumbnail synchronously so ImageRenderer
/// captures it (ImageRenderer doesn't await async tasks).
struct MontageTile: View {
    let moment: Moment
    let side: CGFloat

    private var image: UIImage? {
        ImageStore.shared.loadThumbnail(moment.imageFilename, pointSize: side)
    }

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [moment.mood.color, moment.mood.color.opacity(0.6)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            }
        }
        .frame(width: side, height: side)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}
