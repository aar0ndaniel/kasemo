import SwiftUI

enum MuralColor {
    static let cream = Color(red: 1, green: 0.975, blue: 0.933)
    static let ink = Color(red: 0.212, green: 0.165, blue: 0.133)
    static let secondary = Color(red: 0.45, green: 0.355, blue: 0.29)
    static let iris = Color(red: 0.353, green: 0.310, blue: 0.812)
    static let primary = iris
    static let orange = iris
    static let peach = Color(red: 1, green: 0.89, blue: 0.81)
    static let lilac = Color(red: 0.932, green: 0.902, blue: 0.98)
    static let sage = Color(red: 0.917, green: 0.937, blue: 0.84)
    static let butter = Color(red: 1, green: 0.944, blue: 0.78)
    static let panels = [peach, lilac, sage, butter]
}

struct Brand: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(RadialGradient(colors: [MuralColor.butter, MuralColor.iris], center: .topLeading, startRadius: 0, endRadius: 18)).frame(width: 17, height: 17)
            Text("kpo o").font(.system(size: 30, weight: .bold, design: .rounded)).tracking(-1.6)
        }.foregroundStyle(MuralColor.ink).accessibilityLabel("Kpo o")
    }
}

struct SoftGlass: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    var tint: Color = .white.opacity(0.45)
    func body(content: Content) -> some View {
        if reduceTransparency { content.background(.white, in: Capsule()) }
        else { content.glassEffect(.regular.tint(tint).interactive(), in: .capsule) }
    }
}

struct OrbShape: Shape {
    var phase: Double
    var energy: Double
    func path(in rect: CGRect) -> Path {
        let points = (0..<12).map { index -> CGPoint in
            let a = Double(index) / 12 * .pi * 2
            let wave = sin(a * 3 + phase) * 0.021 + cos(a * 2 - phase * 0.7) * (0.012 + energy * 0.025)
            let radius = min(rect.width, rect.height) * (0.47 + wave)
            return CGPoint(x: rect.midX + cos(a) * radius, y: rect.midY + sin(a) * radius)
        }
        var p = Path()
        for i in 0..<12 {
            let current = points[i], next = points[(i + 1) % 12]
            let midpoint = CGPoint(x: (current.x + next.x) / 2, y: (current.y + next.y) / 2)
            if i == 0 {
                let previous = points[11]
                p.move(to: CGPoint(x: (previous.x + current.x) / 2, y: (previous.y + current.y) / 2))
            }
            p.addQuadCurve(to: midpoint, control: current)
        }
        p.closeSubpath(); return p
    }
}

struct MuralOrb: View {
    var energy: Double = 0
    var listening = false
    var active = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion || !active || scenePhase != .active)) { timeline in
            let t = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
            let phase = t * 0.72
            let e = reduceMotion ? 0 : min(1, max(0, energy))
            GeometryReader { geometry in
                let side = min(geometry.size.width, geometry.size.height)
                ZStack {
                    Ellipse().fill(MuralColor.iris.opacity(0.14)).frame(width: side * 0.57, height: side * 0.075)
                        .blur(radius: 10).offset(y: side * 0.47)
                    Circle().stroke(MuralColor.iris.opacity(listening ? 0.22 : 0), lineWidth: 1).padding(-6)
                    Circle().stroke(MuralColor.iris.opacity(listening ? 0.12 : 0), lineWidth: 1).padding(-16)
                    ZStack {
                        MeshGradient(width: 3, height: 3, points: [
                            [0,0], [0.5,0], [1,0],
                            [0,0.5], [Float(0.5 + sin(phase) * 0.08), Float(0.5 + cos(phase) * 0.06)], [1,0.5],
                            [0,1], [0.5,1], [1,1]
                        ], colors: [Color(red: 1, green: 0.97, blue: 0.82), MuralColor.butter, MuralColor.peach,
                                    Color(red: 0.72, green: 0.68, blue: 0.95), MuralColor.iris, Color(red: 0.80, green: 0.68, blue: 0.93),
                                    Color(red: 0.45, green: 0.38, blue: 0.88), Color(red: 0.58, green: 0.50, blue: 0.92), Color(red: 0.86, green: 0.75, blue: 0.95)])
                        Ellipse().fill(.white.opacity(0.65)).frame(width: side * 0.48, height: side * 0.15).blur(radius: 13)
                            .rotationEffect(.degrees(-28)).offset(x: -side * 0.17, y: -side * 0.28)
                        Ellipse().stroke(MuralColor.butter.opacity(0.48), lineWidth: 16).frame(width: side * 1.2, height: side * 0.5)
                            .blur(radius: 12).rotationEffect(.degrees(-15)).offset(y: side * 0.54)
                    }
                    .mask(OrbShape(phase: phase, energy: e))
                    .shadow(color: MuralColor.iris.opacity(0.18), radius: 16, y: 10)
                    .rotationEffect(.degrees(sin(phase * 0.5) * 3))
                    .scaleEffect(1 + e * 0.045)
                    .offset(y: reduceMotion ? 0 : sin(t * 0.9) * 4 - 5)
                    Circle().fill(RadialGradient(colors: [.white, MuralColor.lilac, MuralColor.iris.opacity(0.5)], center: .topLeading, startRadius: 0, endRadius: 12))
                        .frame(width: 12, height: 12).offset(x: side * 0.55, y: -side * 0.24)
                    Circle().fill(MuralColor.lilac).frame(width: 7, height: 7).offset(x: -side * 0.54, y: side * 0.26)
                }.frame(width: side, height: side).frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }.accessibilityHidden(true)
    }
}

struct RecallBars: View {
    let count: Int
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in Capsule().fill(index < count ? MuralColor.iris : MuralColor.peach).frame(width: 18, height: 6) }
        }.accessibilityLabel("\(count) of 3 recall bars")
    }
}

struct PageHeading: View {
    var eyebrow: String
    var title: String
    var subtitle: String = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(eyebrow.uppercased()).font(.system(.caption, design: .rounded, weight: .medium)).tracking(1.5).foregroundStyle(MuralColor.secondary)
            Text(title).font(.system(.largeTitle, design: .rounded, weight: .semibold)).tracking(-1).foregroundStyle(MuralColor.ink)
            if !subtitle.isEmpty { Text(subtitle).font(.subheadline).foregroundStyle(MuralColor.secondary) }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct StreakIcon: View {
    var size: CGFloat = 16
    var body: some View {
        StreakVectorShape()
            .frame(width: size * 0.65, height: size)
    }
}

/// Precise vector rendition of streak.svg (purple and blue flame)
struct StreakVectorShape: View {
    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let sx = w / 64.0
            let sy = h / 102.0
            let ox = 36.0
            let oy = 46.0
            ZStack {
                Path { p in
                    p.move(to: CGPoint(x: (71.0 - ox) * sx, y: (55.7 - oy) * sy))
                    p.addCurve(to: CGPoint(x: (79.3 - ox) * sx, y: (47.7 - oy) * sy),
                               control1: CGPoint(x: (71.3 - ox) * sx, y: (51.8 - oy) * sy),
                               control2: CGPoint(x: (74.4 - ox) * sx, y: (49.0 - oy) * sy))
                    p.addCurve(to: CGPoint(x: (90.0 - ox) * sx, y: (50.0 - oy) * sy),
                               control1: CGPoint(x: (84.2 - ox) * sx, y: (46.4 - oy) * sy),
                               control2: CGPoint(x: (88.2 - ox) * sx, y: (47.7 - oy) * sy))
                    p.addCurve(to: CGPoint(x: (90.8 - ox) * sx, y: (61.2 - oy) * sy),
                               control1: CGPoint(x: (91.1 - ox) * sx, y: (52.0 - oy) * sy),
                               control2: CGPoint(x: (91.3 - ox) * sx, y: (56.1 - oy) * sy))
                    p.addCurve(to: CGPoint(x: (80.5 - ox) * sx, y: (59.9 - oy) * sy),
                               control1: CGPoint(x: (87.1 - ox) * sx, y: (59.5 - oy) * sy),
                               control2: CGPoint(x: (83.7 - ox) * sx, y: (59.0 - oy) * sy))
                    p.addCurve(to: CGPoint(x: (72.3 - ox) * sx, y: (64.3 - oy) * sy),
                               control1: CGPoint(x: (77.1 - ox) * sx, y: (60.8 - oy) * sy),
                               control2: CGPoint(x: (74.4 - ox) * sx, y: (62.5 - oy) * sy))
                    p.addCurve(to: CGPoint(x: (71.0 - ox) * sx, y: (55.7 - oy) * sy),
                               control1: CGPoint(x: (71.5 - ox) * sx, y: (61.5 - oy) * sy),
                               control2: CGPoint(x: (70.8 - ox) * sx, y: (58.7 - oy) * sy))
                    p.closeSubpath()
                }
                .fill(Color(red: 0.263, green: 0.180, blue: 0.686))

                Path { p in
                    p.move(to: CGPoint(x: (62.2 - ox) * sx, y: (71.1 - oy) * sy))
                    p.addCurve(to: CGPoint(x: (60.5 - ox) * sx, y: (83.7 - oy) * sy),
                               control1: CGPoint(x: (59.9 - ox) * sx, y: (73.9 - oy) * sy),
                               control2: CGPoint(x: (59.6 - ox) * sx, y: (78.3 - oy) * sy))
                    p.addCurve(to: CGPoint(x: (62.1 - ox) * sx, y: (97.7 - oy) * sy),
                               control1: CGPoint(x: (61.3 - ox) * sx, y: (88.6 - oy) * sy),
                               control2: CGPoint(x: (63.7 - ox) * sx, y: (94.3 - oy) * sy))
                    p.addCurve(to: CGPoint(x: (54.0 - ox) * sx, y: (99.6 - oy) * sy),
                               control1: CGPoint(x: (60.5 - ox) * sx, y: (101.1 - oy) * sy),
                               control2: CGPoint(x: (57.3 - ox) * sx, y: (101.4 - oy) * sy))
                    p.addCurve(to: CGPoint(x: (44.0 - ox) * sx, y: (90.1 - oy) * sy),
                               control1: CGPoint(x: (50.8 - ox) * sx, y: (97.8 - oy) * sy),
                               control2: CGPoint(x: (47.5 - ox) * sx, y: (93.1 - oy) * sy))
                    p.addCurve(to: CGPoint(x: (38.8 - ox) * sx, y: (112.2 - oy) * sy),
                               control1: CGPoint(x: (42.1 - ox) * sx, y: (96.0 - oy) * sy),
                               control2: CGPoint(x: (40.3 - ox) * sx, y: (104.0 - oy) * sy))
                    p.addCurve(to: CGPoint(x: (43.1 - ox) * sx, y: (133.4 - oy) * sy),
                               control1: CGPoint(x: (37.5 - ox) * sx, y: (119.5 - oy) * sy),
                               control2: CGPoint(x: (39.3 - ox) * sx, y: (127.6 - oy) * sy))
                    p.addCurve(to: CGPoint(x: (61.6 - ox) * sx, y: (145.6 - oy) * sy),
                               control1: CGPoint(x: (47.0 - ox) * sx, y: (139.4 - oy) * sy),
                               control2: CGPoint(x: (53.2 - ox) * sx, y: (143.2 - oy) * sy))
                    p.addCurve(to: CGPoint(x: (85.8 - ox) * sx, y: (144.6 - oy) * sy),
                               control1: CGPoint(x: (69.3 - ox) * sx, y: (147.7 - oy) * sy),
                               control2: CGPoint(x: (78.8 - ox) * sx, y: (147.5 - oy) * sy))
                    p.addCurve(to: CGPoint(x: (98.1 - ox) * sx, y: (128.3 - oy) * sy),
                               control1: CGPoint(x: (93.7 - ox) * sx, y: (141.3 - oy) * sy),
                               control2: CGPoint(x: (97.2 - ox) * sx, y: (135.8 - oy) * sy))
                    p.addCurve(to: CGPoint(x: (98.0 - ox) * sx, y: (103.7 - oy) * sy),
                               control1: CGPoint(x: (99.1 - ox) * sx, y: (119.9 - oy) * sy),
                               control2: CGPoint(x: (97.4 - ox) * sx, y: (110.9 - oy) * sy))
                    p.addCurve(to: CGPoint(x: (95.4 - ox) * sx, y: (96.2 - oy) * sy),
                               control1: CGPoint(x: (98.4 - ox) * sx, y: (100.5 - oy) * sy),
                               control2: CGPoint(x: (97.4 - ox) * sx, y: (98.0 - oy) * sy))
                    p.addCurve(to: CGPoint(x: (96.3 - ox) * sx, y: (90.2 - oy) * sy),
                               control1: CGPoint(x: (94.4 - ox) * sx, y: (94.7 - oy) * sy),
                               control2: CGPoint(x: (95.4 - ox) * sx, y: (91.8 - oy) * sy))
                    p.addCurve(to: CGPoint(x: (84.3 - ox) * sx, y: (95.9 - oy) * sy),
                               control1: CGPoint(x: (91.0 - ox) * sx, y: (89.8 - oy) * sy),
                               control2: CGPoint(x: (87.2 - ox) * sx, y: (91.6 - oy) * sy))
                    p.addCurve(to: CGPoint(x: (77.8 - ox) * sx, y: (97.5 - oy) * sy),
                               control1: CGPoint(x: (82.2 - ox) * sx, y: (99.1 - oy) * sy),
                               control2: CGPoint(x: (79.4 - ox) * sx, y: (99.8 - oy) * sy))
                    p.addCurve(to: CGPoint(x: (76.8 - ox) * sx, y: (81.8 - oy) * sy),
                               control1: CGPoint(x: (75.8 - ox) * sx, y: (94.4 - oy) * sy),
                               control2: CGPoint(x: (78.1 - ox) * sx, y: (87.8 - oy) * sy))
                    p.addCurve(to: CGPoint(x: (62.2 - ox) * sx, y: (71.1 - oy) * sy),
                               control1: CGPoint(x: (75.5 - ox) * sx, y: (76.9 - oy) * sy),
                               control2: CGPoint(x: (68.4 - ox) * sx, y: (72.0 - oy) * sy))
                    p.closeSubpath()
                }
                .fill(Color(red: 0.263, green: 0.180, blue: 0.686))

                Path { p in
                    p.move(to: CGPoint(x: (65.0 - ox) * sx, y: (104.0 - oy) * sy))
                    p.addCurve(to: CGPoint(x: (62.1 - ox) * sx, y: (115.6 - oy) * sy),
                               control1: CGPoint(x: (66.1 - ox) * sx, y: (108.1 - oy) * sy),
                               control2: CGPoint(x: (65.0 - ox) * sx, y: (112.6 - oy) * sy))
                    p.addCurve(to: CGPoint(x: (49.2 - ox) * sx, y: (117.0 - oy) * sy),
                               control1: CGPoint(x: (58.6 - ox) * sx, y: (118.9 - oy) * sy),
                               control2: CGPoint(x: (53.7 - ox) * sx, y: (118.5 - oy) * sy))
                    p.addCurve(to: CGPoint(x: (54.8 - ox) * sx, y: (136.0 - oy) * sy),
                               control1: CGPoint(x: (49.4 - ox) * sx, y: (123.6 - oy) * sy),
                               control2: CGPoint(x: (50.6 - ox) * sx, y: (130.5 - oy) * sy))
                    p.addCurve(to: CGPoint(x: (73.2 - ox) * sx, y: (142.0 - oy) * sy),
                               control1: CGPoint(x: (59.1 - ox) * sx, y: (141.6 - oy) * sy),
                               control2: CGPoint(x: (66.3 - ox) * sx, y: (143.0 - oy) * sy))
                    p.addCurve(to: CGPoint(x: (87.0 - ox) * sx, y: (129.9 - oy) * sy),
                               control1: CGPoint(x: (81.8 - ox) * sx, y: (140.7 - oy) * sy),
                               control2: CGPoint(x: (85.4 - ox) * sx, y: (136.1 - oy) * sy))
                    p.addCurve(to: CGPoint(x: (88.5 - ox) * sx, y: (113.9 - oy) * sy),
                               control1: CGPoint(x: (88.4 - ox) * sx, y: (124.4 - oy) * sy),
                               control2: CGPoint(x: (88.5 - ox) * sx, y: (118.9 - oy) * sy))
                    p.addCurve(to: CGPoint(x: (77.4 - ox) * sx, y: (120.8 - oy) * sy),
                               control1: CGPoint(x: (84.9 - ox) * sx, y: (115.8 - oy) * sy),
                               control2: CGPoint(x: (81.3 - ox) * sx, y: (117.9 - oy) * sy))
                    p.addCurve(to: CGPoint(x: (76.2 - ox) * sx, y: (110.8 - oy) * sy),
                               control1: CGPoint(x: (78.0 - ox) * sx, y: (117.2 - oy) * sy),
                               control2: CGPoint(x: (78.4 - ox) * sx, y: (113.5 - oy) * sy))
                    p.addCurve(to: CGPoint(x: (65.0 - ox) * sx, y: (104.0 - oy) * sy),
                               control1: CGPoint(x: (73.2 - ox) * sx, y: (107.8 - oy) * sy),
                               control2: CGPoint(x: (69.1 - ox) * sx, y: (105.0 - oy) * sy))
                    p.closeSubpath()
                }
                .fill(LinearGradient(colors: [Color(red: 0.616, green: 0.557, blue: 0.961),
                                              Color(red: 0.482, green: 0.408, blue: 0.929),
                                              MuralColor.iris],
                                     startPoint: .top, endPoint: .bottom))
            }
        }
        .aspectRatio(64.0 / 102.0, contentMode: .fit)
    }
}
