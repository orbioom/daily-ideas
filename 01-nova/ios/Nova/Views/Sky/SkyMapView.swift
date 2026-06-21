import SwiftUI

struct SkyMapView: View {
    @State private var viewModel = SkyViewModel()
    @State private var selectedObject: SkyObject?
    @State private var showDetail = false
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [NovaSettings]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var settings: NovaSettings? { settingsList.first }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                NovaTheme.skyBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    headerBar
                    skyCanvas(in: geo.size)
                    infoBar
                }
            }
        }
        .onAppear {
            if let s = settings {
                viewModel.city = CityData.cities[safe: s.selectedCityIndex] ?? CityData.cities[0]
                viewModel.limitingMagnitude = s.limitingMagnitude
                viewModel.showConstellationLines = s.showConstellationLines
                viewModel.showConstellationNames = s.showConstellationNames
                viewModel.showPlanets = s.showPlanets
                viewModel.showMoon = s.showMoon
                viewModel.northUp = s.northUp
            }
            viewModel.startLive()
        }
        .onDisappear { viewModel.stopLive() }
        .sheet(isPresented: $showDetail) {
            if let obj = selectedObject {
                ObjectDetailSheet(object: obj)
            }
        }
    }

    var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.city.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(NovaTheme.textPrimary)
                Text(timeString)
                    .font(.system(size: 12))
                    .foregroundStyle(NovaTheme.textSecondary)
            }
            Spacer()
            Text(viewModel.isNighttime ? "🌙 Night" : "☀️ Day")
                .font(.system(size: 13))
                .foregroundStyle(NovaTheme.textSecondary)
            Text(viewModel.moonPhaseName)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(NovaTheme.accentGold)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(NovaTheme.cardBackground)
    }

    func skyCanvas(in parentSize: CGSize) -> some View {
        let size = CGSize(width: parentSize.width, height: parentSize.width)
        return ZStack {
            Canvas { ctx, sz in
                drawSky(ctx: ctx, size: sz)
            }
            .frame(width: size.width, height: size.height)
            .clipShape(Circle())
            .overlay(Circle().stroke(NovaTheme.horizon, lineWidth: 2))

            // Cardinal labels
            cardinalLabels(in: size)

            // Tappable star overlays
            ForEach(viewModel.skyObjects.filter { $0.isAboveHorizon && $0.magnitude < 2.5 }.prefix(20)) { obj in
                if let pt = viewModel.skyPoint(altDeg: obj.altDeg, azDeg: obj.azDeg, in: size) {
                    Button {
                        selectedObject = obj
                        showDetail = true
                    } label: {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 44, height: 44)
                    }
                    .position(pt)
                    .accessibilityLabel(obj.name)
                }
            }
        }
    }

    func drawSky(ctx: GraphicsContext, size: CGSize) {
        // Sky gradient background
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) / 2
        ctx.fill(Circle().path(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)),
                 with: .color(NovaTheme.skyBackground))

        let maxR = radius * 0.94

        // Altitude circles (every 30°)
        for altDeg in stride(from: 30.0, through: 90.0, by: 30.0) {
            let r = (90.0 - altDeg) / 90.0 * maxR
            let rect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
            var path = Path()
            path.addEllipse(in: rect)
            ctx.stroke(path, with: .color(NovaTheme.textSecondary.opacity(0.12)), lineWidth: 0.5)
        }

        // Constellation lines
        if viewModel.showConstellationLines {
            let stars = StarCatalog.stars
            for constellation in StarCatalog.constellations {
                for (i1, i2) in constellation.lines {
                    guard i1 < stars.count, i2 < stars.count else { continue }
                    let s1 = stars[i1]; let s2 = stars[i2]
                    let (alt1, az1) = AstroMath.altAz(raDeg: s1.raDeg, decDeg: s1.decDeg, lstDeg: currentLST, latDeg: viewModel.city.latitude)
                    let (alt2, az2) = AstroMath.altAz(raDeg: s2.raDeg, decDeg: s2.decDeg, lstDeg: currentLST, latDeg: viewModel.city.latitude)
                    guard alt1 > 0, alt2 > 0 else { continue }
                    if let p1 = viewModel.skyPoint(altDeg: alt1, azDeg: az1, in: size),
                       let p2 = viewModel.skyPoint(altDeg: alt2, azDeg: az2, in: size) {
                        var path = Path()
                        path.move(to: p1)
                        path.addLine(to: p2)
                        ctx.stroke(path, with: .color(NovaTheme.constellationLine), lineWidth: 0.9)
                    }
                }
            }
        }

        // Stars
        for obj in viewModel.skyObjects {
            guard obj.isAboveHorizon else { continue }
            guard let pt = viewModel.skyPoint(altDeg: obj.altDeg, azDeg: obj.azDeg, in: size) else { continue }

            switch obj.kind {
            case .star:
                if obj.magnitude > viewModel.limitingMagnitude { continue }
                let r = viewModel.starDotRadius(magnitude: obj.magnitude)
                let starColor = NovaTheme.starColor(bv: obj.bv)
                let rect = CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2)
                ctx.fill(Path(ellipseIn: rect), with: .color(starColor))
                // Glow for bright stars
                if obj.magnitude < 1.5 {
                    let gr = r * 2.5
                    let glowRect = CGRect(x: pt.x - gr, y: pt.y - gr, width: gr * 2, height: gr * 2)
                    ctx.fill(Path(ellipseIn: glowRect), with: .color(starColor.opacity(0.15)))
                }
                // Labels for bright stars
                if obj.magnitude < 1.8 {
                    ctx.draw(Text(obj.name)
                        .font(.system(size: 10))
                        .foregroundColor(NovaTheme.textSecondary.opacity(0.7)),
                             at: CGPoint(x: pt.x + r + 5, y: pt.y - 5))
                }

            case .moon:
                let r: CGFloat = 10
                let rect = CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2)
                ctx.fill(Path(ellipseIn: rect), with: .color(Color(white: 0.9, opacity: 0.9)))
                ctx.draw(Text("☽")
                    .font(.system(size: 8))
                    .foregroundColor(NovaTheme.textPrimary.opacity(0.7)),
                         at: CGPoint(x: pt.x + 14, y: pt.y - 4))

            case .sun:
                let r: CGFloat = 12
                let rect = CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2)
                ctx.fill(Path(ellipseIn: rect), with: .color(Color(red: 1.0, green: 0.85, blue: 0.3)))

            case .planet(let name):
                let r: CGFloat = 5
                let rect = CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2)
                ctx.fill(Path(ellipseIn: rect), with: .color(NovaTheme.planetColor))
                ctx.draw(Text(name.symbol)
                    .font(.system(size: 9))
                    .foregroundColor(NovaTheme.accentGold.opacity(0.8)),
                         at: CGPoint(x: pt.x + 8, y: pt.y - 4))
            }
        }

        // Zenith marker
        let zenithRect = CGRect(x: center.x - 3, y: center.y - 3, width: 6, height: 6)
        ctx.fill(Path(ellipseIn: zenithRect), with: .color(NovaTheme.accent.opacity(0.4)))
    }

    func cardinalLabels(in size: CGSize) -> some View {
        let cx = size.width / 2
        let cy = size.height / 2
        let r = min(cx, cy) * 0.94 + 12
        return ZStack {
            Text("N").position(x: cx, y: cy - r)
            Text("S").position(x: cx, y: cy + r)
            Text("E").position(x: cx + r, y: cy)
            Text("W").position(x: cx - r, y: cy)
        }
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(NovaTheme.textSecondary.opacity(0.7))
    }

    var currentLST: Double {
        let jd = AstroMath.julianDate(from: viewModel.currentDate)
        let gmst = AstroMath.gmstDeg(jd: jd)
        return AstroMath.lstDeg(gmst: gmst, lonDeg: viewModel.city.longitude)
    }

    var timeString: String {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: viewModel.currentDate)
    }

    var infoBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                InfoChip(icon: "moon.fill", text: viewModel.moonPhaseName, color: NovaTheme.accentGold)
                ForEach(viewModel.visiblePlanets) { p in
                    InfoChip(icon: "circle.fill", text: p.name, color: NovaTheme.planetColor)
                }
                if viewModel.brightestStars.count > 0 {
                    InfoChip(icon: "star.fill", text: "Brightest: \(viewModel.brightestStars.first?.name ?? "")", color: NovaTheme.starWhite)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(NovaTheme.cardBackground)
    }
}

struct InfoChip: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 11)).foregroundStyle(color)
            Text(text).font(.system(size: 12, weight: .medium)).foregroundStyle(NovaTheme.textPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.15))
        .cornerRadius(16)
    }
}

struct ObjectDetailSheet: View {
    let object: SkyObject
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                NovaTheme.skyBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        objectIcon
                        VStack(spacing: 8) {
                            Text(object.name)
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(NovaTheme.textPrimary)
                            Text(kindLabel)
                                .font(.system(size: 15))
                                .foregroundStyle(NovaTheme.accent)
                        }

                        if let star = starInfo {
                            detailCard("Constellation", value: star.constellation)
                            detailCard("Spectral Type", value: star.spectralType)
                            detailCard("Magnitude", value: String(format: "%.2f", star.magnitude))
                            detailCard("Altitude Now", value: String(format: "%.1f°", object.altDeg))
                            detailCard("Azimuth Now", value: String(format: "%.1f°", object.azDeg))

                            VStack(alignment: .leading, spacing: 8) {
                                Text("About")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(NovaTheme.textSecondary)
                                Text(star.description)
                                    .font(.system(size: 15))
                                    .foregroundStyle(NovaTheme.textPrimary)
                            }
                            .padding()
                            .background(NovaTheme.cardBackground)
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }.foregroundStyle(NovaTheme.accent)
                }
            }
        }
    }

    var starInfo: Star? {
        if case .star(let id) = object.kind {
            return StarCatalog.stars.first { $0.id == id }
        }
        return nil
    }

    var kindLabel: String {
        switch object.kind {
        case .star: return "Star · \(starInfo?.constellation ?? "")"
        case .moon: return "Earth's Moon"
        case .sun: return "Our Sun"
        case .planet(let n): return "Planet"
        }
    }

    var objectIcon: some View {
        ZStack {
            Circle()
                .fill(NovaTheme.cardBackground)
                .frame(width: 100, height: 100)
            switch object.kind {
            case .star:
                Image(systemName: "star.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(NovaTheme.starGold)
            case .moon:
                Text("🌙").font(.system(size: 48))
            case .sun:
                Text("☀️").font(.system(size: 48))
            case .planet:
                Image(systemName: "circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(NovaTheme.planetColor)
            }
        }
    }

    func detailCard(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(NovaTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(NovaTheme.textPrimary)
        }
        .padding()
        .background(NovaTheme.cardBackground)
        .cornerRadius(12)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
