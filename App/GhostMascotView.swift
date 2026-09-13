//
//  GhostMascotView.swift
//  Mural
//
//  A native, vector-rendered SwiftUI representation of the purple ghost companion
//  derived from app icon ghost.svg with sub-pixel sharpness and fluid animation.
//

import SwiftUI

public enum GhostPose: String, CaseIterable, Sendable {
    case neutral
    case happy
    case angry
    case sad
    case surprised
    case sleepy
    case glasses
    case wink
    case wave
    case tiltLeft
    case tiltRight
    case flying
    case jump
    case reading
    case studying
    case writing
    case coffee
    case flame
}

public enum GhostPalette {
    public static let body = Color(red: 0.843, green: 0.725, blue: 0.933)       // #D7B9EE
    public static let bodyDark = Color(red: 0.788, green: 0.643, blue: 0.878)   // #C9A4E0
    public static let bodyMid = Color(red: 0.773, green: 0.616, blue: 0.875)    // #C59DDF
    public static let accent = Color(red: 0.725, green: 0.541, blue: 0.847)     // #B98AD8
    public static let feature = Color(red: 0.302, green: 0.090, blue: 0.357)    // #4D175B
    public static let white = Color.white
    public static let shadowGrey = Color(red: 0.847, green: 0.847, blue: 0.847) // #D8D8D8
    public static let wing = Color(red: 0.937, green: 0.898, blue: 0.973)       // #EFE5F8
    
    // Props
    public static let book = Color(red: 0.749, green: 0.506, blue: 0.302)       // #BF814D
    public static let bookDark = Color(red: 0.624, green: 0.396, blue: 0.231)   // #9F653B
    public static let pencil = Color(red: 0.973, green: 0.769, blue: 0.294)     // #F8C44B
    public static let pencilBand = Color(red: 0.918, green: 0.655, blue: 0.784) // #EAA7C8
    public static let pencilTip = Color(red: 0.761, green: 0.545, blue: 0.337)  // #C28B56
    public static let machine = Color(red: 0.914, green: 0.894, blue: 0.937)    // #E9E4EF
    public static let machineTop = Color(red: 0.604, green: 0.561, blue: 0.847) // #9A8FD8
    public static let machineDark = Color(red: 0.353, green: 0.290, blue: 0.635)// #5A4AA2
    public static let cup = Color(red: 0.353, green: 0.290, blue: 0.635)        // #5A4AA2
    
    // Flame (Iris gradient matched to app streak)
    public static let flameOuter = Color(red: 0.353, green: 0.310, blue: 0.812) // Iris #5A4FCF
    public static let flameInner = Color(red: 0.616, green: 0.557, blue: 0.961) // Soft Iris #9D8EF5
    public static let teardrop = Color(red: 0.525, green: 0.718, blue: 1.000)   // #86B7FF
}

public struct GhostMascotView: View {
    public var pose: GhostPose
    public var size: CGFloat = 80
    public var animated: Bool = true
    public var energy: CGFloat = 0.0
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    public init(pose: GhostPose = .neutral, size: CGFloat = 80, animated: Bool = true, energy: CGFloat = 0.0) {
        self.pose = pose
        self.size = size
        self.animated = animated
        self.energy = energy
    }
    
    private var canvasWidth: CGFloat {
        switch pose {
        case .flying: return 220
        case .coffee: return 240
        default: return 190
        }
    }
    
    private var canvasHeight: CGFloat {
        switch pose {
        case .jump, .flying: return 250
        default: return 240
        }
    }
    
    public var body: some View {
        let shouldAnimate = animated && !reduceMotion
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !shouldAnimate)) { timeline in
            let time = shouldAnimate ? timeline.date.timeIntervalSinceReferenceDate : 0
            let bob = shouldAnimate ? sin(time * 1.8) * 3.5 : 0
            let pulse = 1.0 + min(energy * 0.12, 0.25)
            
            ZStack {
                GhostCanvas(pose: pose)
                    .frame(width: size, height: size * (canvasHeight / canvasWidth))
                    .offset(y: bob)
                    .scaleEffect(pulse)
            }
            .frame(width: size, height: size * (canvasHeight / canvasWidth))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Mascot: \(pose.rawValue)")
        }
    }
}

struct GhostCanvas: View {
    var pose: GhostPose
    
    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            
            switch pose {
            case .flying:
                let sx = w / 220.0
                let sy = h / 250.0
                ZStack {
                    GhostWingsShape(sx: sx, sy: sy)
                        .fill(GhostPalette.wing)
                    Ellipse()
                        .fill(GhostPalette.shadowGrey)
                        .frame(width: 74 * sx, height: 16 * sy)
                        .position(x: 110 * sx, y: 226 * sy)
                    GhostBaseView(sx: sx, sy: sy)
                        .offset(x: 15 * sx, y: -8 * sy)
                    GhostFaceView(pose: .happy, sx: sx, sy: sy)
                        .offset(x: 15 * sx, y: -8 * sy)
                }
            case .jump:
                let sx = w / 190.0
                let sy = h / 250.0
                ZStack {
                    Ellipse()
                        .fill(GhostPalette.shadowGrey)
                        .frame(width: 68 * sx, height: 16 * sy)
                        .position(x: 95 * sx, y: 231 * sy)
                    GhostBaseView(sx: sx, sy: sy)
                        .offset(y: -16 * sy)
                    GhostFaceView(pose: .happy, sx: sx, sy: sy)
                        .offset(y: -16 * sy)
                }
            case .tiltLeft:
                let sx = w / 190.0
                let sy = h / 240.0
                ZStack {
                    GhostBaseView(sx: sx, sy: sy)
                    GhostFaceView(pose: .neutral, sx: sx, sy: sy)
                }
                .rotationEffect(.degrees(-10), anchor: UnitPoint(x: 95.0 / 190.0, y: 120.0 / 240.0))
            case .tiltRight:
                let sx = w / 190.0
                let sy = h / 240.0
                ZStack {
                    GhostBaseView(sx: sx, sy: sy)
                    GhostFaceView(pose: .neutral, sx: sx, sy: sy)
                }
                .rotationEffect(.degrees(10), anchor: UnitPoint(x: 95.0 / 190.0, y: 120.0 / 240.0))
            case .coffee:
                let sx = w / 240.0
                let sy = h / 240.0
                ZStack {
                    GhostBaseView(sx: sx, sy: sy)
                    GhostFaceView(pose: .coffee, sx: sx, sy: sy)
                    GhostCoffeeMachineProp(sx: sx, sy: sy)
                }
            default:
                let sx = w / 190.0
                let sy = h / 240.0
                ZStack {
                    GhostBaseView(sx: sx, sy: sy)
                    GhostFaceView(pose: pose, sx: sx, sy: sy)
                    GhostPropsView(pose: pose, sx: sx, sy: sy)
                }
            }
        }
    }
}

struct GhostBaseView: View {
    let sx: CGFloat
    let sy: CGFloat
    let ox: CGFloat = 0
    let oy: CGFloat = 0
    
    var body: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: (71 - ox) * sx, y: (28 - oy) * sy))
                p.addCurve(to: CGPoint(x: (148 - ox) * sx, y: (34 - oy) * sy), control1: CGPoint(x: (96 - ox) * sx, y: (21 - oy) * sy), control2: CGPoint(x: (128 - ox) * sx, y: (23 - oy) * sy))
                p.addCurve(to: CGPoint(x: (171 - ox) * sx, y: (76 - oy) * sy), control1: CGPoint(x: (163 - ox) * sx, y: (42 - oy) * sy), control2: CGPoint(x: (171 - ox) * sx, y: (56 - oy) * sy))
                p.addLine(to: CGPoint(x: (171 - ox) * sx, y: (163 - oy) * sy))
                p.addCurve(to: CGPoint(x: (164 - ox) * sx, y: (211 - oy) * sy), control1: CGPoint(x: (171 - ox) * sx, y: (182 - oy) * sy), control2: CGPoint(x: (168 - ox) * sx, y: (199 - oy) * sy))
                p.addCurve(to: CGPoint(x: (141 - ox) * sx, y: (227 - oy) * sy), control1: CGPoint(x: (160 - ox) * sx, y: (221 - oy) * sy), control2: CGPoint(x: (151 - ox) * sx, y: (227 - oy) * sy))
                p.addCurve(to: CGPoint(x: (119 - ox) * sx, y: (214 - oy) * sy), control1: CGPoint(x: (132 - ox) * sx, y: (227 - oy) * sy), control2: CGPoint(x: (125 - ox) * sx, y: (223 - oy) * sy))
                p.addCurve(to: CGPoint(x: (92 - ox) * sx, y: (231 - oy) * sy), control1: CGPoint(x: (113 - ox) * sx, y: (225 - oy) * sy), control2: CGPoint(x: (103 - ox) * sx, y: (231 - oy) * sy))
                p.addCurve(to: CGPoint(x: (65 - ox) * sx, y: (214 - oy) * sy), control1: CGPoint(x: (81 - ox) * sx, y: (231 - oy) * sy), control2: CGPoint(x: (71 - ox) * sx, y: (225 - oy) * sy))
                p.addCurve(to: CGPoint(x: (37 - ox) * sx, y: (231 - oy) * sy), control1: CGPoint(x: (59 - ox) * sx, y: (224 - oy) * sy), control2: CGPoint(x: (49 - ox) * sx, y: (231 - oy) * sy))
                p.addCurve(to: CGPoint(x: (15 - ox) * sx, y: (214 - oy) * sy), control1: CGPoint(x: (27 - ox) * sx, y: (231 - oy) * sy), control2: CGPoint(x: (18 - ox) * sx, y: (225 - oy) * sy))
                p.addCurve(to: CGPoint(x: (9 - ox) * sx, y: (164 - oy) * sy), control1: CGPoint(x: (11 - ox) * sx, y: (201 - oy) * sy), control2: CGPoint(x: (9 - ox) * sx, y: (184 - oy) * sy))
                p.addLine(to: CGPoint(x: (9 - ox) * sx, y: (79 - oy) * sy))
                p.addCurve(to: CGPoint(x: (33 - ox) * sx, y: (34 - oy) * sy), control1: CGPoint(x: (9 - ox) * sx, y: (58 - oy) * sy), control2: CGPoint(x: (17 - ox) * sx, y: (43 - oy) * sy))
                p.addCurve(to: CGPoint(x: (71 - ox) * sx, y: (28 - oy) * sy), control1: CGPoint(x: (44 - ox) * sx, y: (28 - oy) * sy), control2: CGPoint(x: (57 - ox) * sx, y: (25 - oy) * sy))
                p.closeSubpath()
            }
            .fill(GhostPalette.body)
            
            Path { p in
                p.move(to: CGPoint(x: (171 - ox) * sx, y: (164 - oy) * sy))
                p.addCurve(to: CGPoint(x: (164 - ox) * sx, y: (211 - oy) * sy), control1: CGPoint(x: (171 - ox) * sx, y: (183 - oy) * sy), control2: CGPoint(x: (168 - ox) * sx, y: (199 - oy) * sy))
                p.addCurve(to: CGPoint(x: (141 - ox) * sx, y: (227 - oy) * sy), control1: CGPoint(x: (160 - ox) * sx, y: (221 - oy) * sy), control2: CGPoint(x: (151 - ox) * sx, y: (227 - oy) * sy))
                p.addCurve(to: CGPoint(x: (119 - ox) * sx, y: (214 - oy) * sy), control1: CGPoint(x: (132 - ox) * sx, y: (227 - oy) * sy), control2: CGPoint(x: (125 - ox) * sx, y: (223 - oy) * sy))
                p.addCurve(to: CGPoint(x: (92 - ox) * sx, y: (231 - oy) * sy), control1: CGPoint(x: (113 - ox) * sx, y: (225 - oy) * sy), control2: CGPoint(x: (103 - ox) * sx, y: (231 - oy) * sy))
                p.addCurve(to: CGPoint(x: (65 - ox) * sx, y: (214 - oy) * sy), control1: CGPoint(x: (81 - ox) * sx, y: (231 - oy) * sy), control2: CGPoint(x: (71 - ox) * sx, y: (225 - oy) * sy))
                p.addCurve(to: CGPoint(x: (37 - ox) * sx, y: (231 - oy) * sy), control1: CGPoint(x: (59 - ox) * sx, y: (224 - oy) * sy), control2: CGPoint(x: (49 - ox) * sx, y: (231 - oy) * sy))
                p.addCurve(to: CGPoint(x: (15 - ox) * sx, y: (214 - oy) * sy), control1: CGPoint(x: (27 - ox) * sx, y: (231 - oy) * sy), control2: CGPoint(x: (18 - ox) * sx, y: (225 - oy) * sy))
                p.addCurve(to: CGPoint(x: (9 - ox) * sx, y: (164 - oy) * sy), control1: CGPoint(x: (11 - ox) * sx, y: (201 - oy) * sy), control2: CGPoint(x: (9 - ox) * sx, y: (184 - oy) * sy))
                p.addCurve(to: CGPoint(x: (51 - ox) * sx, y: (178 - oy) * sy), control1: CGPoint(x: (21 - ox) * sx, y: (173 - oy) * sy), control2: CGPoint(x: (34 - ox) * sx, y: (178 - oy) * sy))
                p.addCurve(to: CGPoint(x: (105 - ox) * sx, y: (171 - oy) * sy), control1: CGPoint(x: (73 - ox) * sx, y: (178 - oy) * sy), control2: CGPoint(x: (90 - ox) * sx, y: (169 - oy) * sy))
                p.addCurve(to: CGPoint(x: (156 - ox) * sx, y: (176 - oy) * sy), control1: CGPoint(x: (123 - ox) * sx, y: (173 - oy) * sy), control2: CGPoint(x: (138 - ox) * sx, y: (181 - oy) * sy))
                p.addCurve(to: CGPoint(x: (171 - ox) * sx, y: (164 - oy) * sy), control1: CGPoint(x: (162 - ox) * sx, y: (174 - oy) * sy), control2: CGPoint(x: (167 - ox) * sx, y: (170 - oy) * sy))
                p.closeSubpath()
            }
            .fill(GhostPalette.accent.opacity(0.35))
            
            Path { p in
                p.move(to: CGPoint(x: (171 - ox) * sx, y: (164 - oy) * sy))
                p.addCurve(to: CGPoint(x: (154 - ox) * sx, y: (183 - oy) * sy), control1: CGPoint(x: (167 - ox) * sx, y: (176 - oy) * sy), control2: CGPoint(x: (162 - ox) * sx, y: (180 - oy) * sy))
                p.addCurve(to: CGPoint(x: (118 - ox) * sx, y: (178 - oy) * sy), control1: CGPoint(x: (140 - ox) * sx, y: (188 - oy) * sy), control2: CGPoint(x: (130 - ox) * sx, y: (183 - oy) * sy))
                p.addCurve(to: CGPoint(x: (90 - ox) * sx, y: (175 - oy) * sy), control1: CGPoint(x: (108 - ox) * sx, y: (174 - oy) * sy), control2: CGPoint(x: (98 - ox) * sx, y: (173 - oy) * sy))
                p.addCurve(to: CGPoint(x: (60 - ox) * sx, y: (184 - oy) * sy), control1: CGPoint(x: (80 - ox) * sx, y: (177 - oy) * sy), control2: CGPoint(x: (71 - ox) * sx, y: (182 - oy) * sy))
                p.addCurve(to: CGPoint(x: (9 - ox) * sx, y: (164 - oy) * sy), control1: CGPoint(x: (44 - ox) * sx, y: (187 - oy) * sy), control2: CGPoint(x: (27 - ox) * sx, y: (184 - oy) * sy))
                p.addCurve(to: CGPoint(x: (15 - ox) * sx, y: (214 - oy) * sy), control1: CGPoint(x: (9 - ox) * sx, y: (184 - oy) * sy), control2: CGPoint(x: (11 - ox) * sx, y: (201 - oy) * sy))
                p.addCurve(to: CGPoint(x: (37 - ox) * sx, y: (231 - oy) * sy), control1: CGPoint(x: (18 - ox) * sx, y: (225 - oy) * sy), control2: CGPoint(x: (27 - ox) * sx, y: (231 - oy) * sy))
                p.addCurve(to: CGPoint(x: (65 - ox) * sx, y: (214 - oy) * sy), control1: CGPoint(x: (49 - ox) * sx, y: (231 - oy) * sy), control2: CGPoint(x: (59 - ox) * sx, y: (224 - oy) * sy))
                p.addCurve(to: CGPoint(x: (92 - ox) * sx, y: (231 - oy) * sy), control1: CGPoint(x: (71 - ox) * sx, y: (225 - oy) * sy), control2: CGPoint(x: (81 - ox) * sx, y: (231 - oy) * sy))
                p.addCurve(to: CGPoint(x: (119 - ox) * sx, y: (214 - oy) * sy), control1: CGPoint(x: (103 - ox) * sx, y: (231 - oy) * sy), control2: CGPoint(x: (113 - ox) * sx, y: (225 - oy) * sy))
                p.addCurve(to: CGPoint(x: (141 - ox) * sx, y: (227 - oy) * sy), control1: CGPoint(x: (125 - ox) * sx, y: (223 - oy) * sy), control2: CGPoint(x: (132 - ox) * sx, y: (227 - oy) * sy))
                p.addCurve(to: CGPoint(x: (164 - ox) * sx, y: (211 - oy) * sy), control1: CGPoint(x: (151 - ox) * sx, y: (227 - oy) * sy), control2: CGPoint(x: (160 - ox) * sx, y: (221 - oy) * sy))
                p.addCurve(to: CGPoint(x: (171 - ox) * sx, y: (164 - oy) * sy), control1: CGPoint(x: (168 - ox) * sx, y: (199 - oy) * sy), control2: CGPoint(x: (171 - ox) * sx, y: (182 - oy) * sy))
                p.closeSubpath()
            }
            .fill(GhostPalette.bodyMid.opacity(0.20))
            
            Path { p in
                p.move(to: CGPoint(x: (170 - ox) * sx, y: (116 - oy) * sy))
                p.addCurve(to: CGPoint(x: (185 - ox) * sx, y: (132 - oy) * sy), control1: CGPoint(x: (179 - ox) * sx, y: (117 - oy) * sy), control2: CGPoint(x: (185 - ox) * sx, y: (124 - oy) * sy))
                p.addCurve(to: CGPoint(x: (173 - ox) * sx, y: (147 - oy) * sy), control1: CGPoint(x: (185 - ox) * sx, y: (140 - oy) * sy), control2: CGPoint(x: (180 - ox) * sx, y: (146 - oy) * sy))
                p.addCurve(to: CGPoint(x: (163 - ox) * sx, y: (135 - oy) * sy), control1: CGPoint(x: (167 - ox) * sx, y: (147 - oy) * sy), control2: CGPoint(x: (163 - ox) * sx, y: (142 - oy) * sy))
                p.addCurve(to: CGPoint(x: (170 - ox) * sx, y: (116 - oy) * sy), control1: CGPoint(x: (163 - ox) * sx, y: (128 - oy) * sy), control2: CGPoint(x: (165 - ox) * sx, y: (121 - oy) * sy))
                p.closeSubpath()
            }
            .fill(GhostPalette.bodyDark)
        }
    }
}

struct GhostFaceView: View {
    let pose: GhostPose
    let sx: CGFloat
    let sy: CGFloat
    let ox: CGFloat = 0
    let oy: CGFloat = 0
    
    var body: some View {
        ZStack {
            switch pose {
            case .neutral, .tiltLeft, .tiltRight, .reading, .writing:
                defaultEyesAndMouth
            case .happy, .jump, .flying, .wave, .studying:
                happyEyesAndMouth
            case .angry:
                angryFace
            case .sad:
                sadFace
            case .surprised:
                surprisedFace
            case .sleepy:
                sleepyFace
            case .coffee:
                closedFace
            case .glasses:
                glassesFace
            case .wink:
                winkFace
            case .flame:
                flameEyesFace
            }
        }
    }
    
    private var defaultEyesAndMouth: some View {
        ZStack {
            Circle().fill(GhostPalette.feature)
                .frame(width: 18 * sx, height: 18 * sy)
                .position(x: 78 * sx, y: 99 * sy)
            Circle().fill(GhostPalette.feature)
                .frame(width: 18 * sx, height: 18 * sy)
                .position(x: 117 * sx, y: 99 * sy)
            Circle().fill(GhostPalette.white).frame(width: 5.2 * sx, height: 5.2 * sy).position(x: 75 * sx, y: 95 * sy)
            Circle().fill(GhostPalette.white).frame(width: 3.6 * sx, height: 3.6 * sy).position(x: 81 * sx, y: 101 * sy)
            Circle().fill(GhostPalette.white).frame(width: 5.2 * sx, height: 5.2 * sy).position(x: 114 * sx, y: 95 * sy)
            Circle().fill(GhostPalette.white).frame(width: 3.6 * sx, height: 3.6 * sy).position(x: 120 * sx, y: 101 * sy)
            Path { p in
                p.move(to: CGPoint(x: (81 - ox) * sx, y: (129 - oy) * sy))
                p.addCurve(to: CGPoint(x: (114 - ox) * sx, y: (129 - oy) * sy), control1: CGPoint(x: (87 - ox) * sx, y: (123 - oy) * sy), control2: CGPoint(x: (107 - ox) * sx, y: (123 - oy) * sy))
                p.addCurve(to: CGPoint(x: (81 - ox) * sx, y: (129 - oy) * sy), control1: CGPoint(x: (108 - ox) * sx, y: (136 - oy) * sy), control2: CGPoint(x: (87 - ox) * sx, y: (136 - oy) * sy))
                p.closeSubpath()
            }
            .fill(GhostPalette.white)
        }
    }
    
    private var happyEyesAndMouth: some View {
        ZStack {
            Circle().fill(GhostPalette.feature)
                .frame(width: 18 * sx, height: 18 * sy)
                .position(x: 78 * sx, y: 99 * sy)
            Circle().fill(GhostPalette.feature)
                .frame(width: 18 * sx, height: 18 * sy)
                .position(x: 117 * sx, y: 99 * sy)
            Circle().fill(GhostPalette.white).frame(width: 5.2 * sx, height: 5.2 * sy).position(x: 75 * sx, y: 95 * sy)
            Circle().fill(GhostPalette.white).frame(width: 3.6 * sx, height: 3.6 * sy).position(x: 81 * sx, y: 101 * sy)
            Circle().fill(GhostPalette.white).frame(width: 5.2 * sx, height: 5.2 * sy).position(x: 114 * sx, y: 95 * sy)
            Circle().fill(GhostPalette.white).frame(width: 3.6 * sx, height: 3.6 * sy).position(x: 120 * sx, y: 101 * sy)
            Path { p in
                p.move(to: CGPoint(x: (80 - ox) * sx, y: (128 - oy) * sy))
                p.addCurve(to: CGPoint(x: (116 - ox) * sx, y: (128 - oy) * sy), control1: CGPoint(x: (88 - ox) * sx, y: (121 - oy) * sy), control2: CGPoint(x: (108 - ox) * sx, y: (121 - oy) * sy))
                p.addCurve(to: CGPoint(x: (80 - ox) * sx, y: (128 - oy) * sy), control1: CGPoint(x: (109 - ox) * sx, y: (139 - oy) * sy), control2: CGPoint(x: (87 - ox) * sx, y: (139 - oy) * sy))
                p.closeSubpath()
            }
            .fill(GhostPalette.white)
        }
    }
    
    private var angryFace: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: (67 - ox) * sx, y: (89 - oy) * sy))
                p.addLine(to: CGPoint(x: (84 - ox) * sx, y: (94 - oy) * sy))
            }.stroke(GhostPalette.feature, style: StrokeStyle(lineWidth: 4 * sx, lineCap: .round))
            Path { p in
                p.move(to: CGPoint(x: (127 - ox) * sx, y: (94 - oy) * sy))
                p.addLine(to: CGPoint(x: (144 - ox) * sx, y: (89 - oy) * sy))
            }.stroke(GhostPalette.feature, style: StrokeStyle(lineWidth: 4 * sx, lineCap: .round))
            Circle().fill(GhostPalette.feature).frame(width: 16 * sx, height: 16 * sy).position(x: 79 * sx, y: 100 * sy)
            Circle().fill(GhostPalette.feature).frame(width: 16 * sx, height: 16 * sy).position(x: 116 * sx, y: 100 * sy)
            Circle().fill(GhostPalette.white).frame(width: 4.4 * sx, height: 4.4 * sy).position(x: 77 * sx, y: 97 * sy)
            Circle().fill(GhostPalette.white).frame(width: 4.4 * sx, height: 4.4 * sy).position(x: 114 * sx, y: 97 * sy)
            Path { p in
                p.move(to: CGPoint(x: (86 - ox) * sx, y: (134 - oy) * sy))
                p.addQuadCurve(to: CGPoint(x: (110 - ox) * sx, y: (134 - oy) * sy), control: CGPoint(x: (98 - ox) * sx, y: (124 - oy) * sy))
            }.stroke(GhostPalette.feature, style: StrokeStyle(lineWidth: 4 * sx, lineCap: .round))
        }
    }
    
    private var sadFace: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: (69 - ox) * sx, y: (100 - oy) * sy))
                p.addQuadCurve(to: CGPoint(x: (87 - ox) * sx, y: (100 - oy) * sy), control: CGPoint(x: (78 - ox) * sx, y: (94 - oy) * sy))
            }.stroke(GhostPalette.feature, style: StrokeStyle(lineWidth: 4 * sx, lineCap: .round))
            Path { p in
                p.move(to: CGPoint(x: (108 - ox) * sx, y: (100 - oy) * sy))
                p.addQuadCurve(to: CGPoint(x: (126 - ox) * sx, y: (100 - oy) * sy), control: CGPoint(x: (117 - ox) * sx, y: (94 - oy) * sy))
            }.stroke(GhostPalette.feature, style: StrokeStyle(lineWidth: 4 * sx, lineCap: .round))
            Path { p in
                p.move(to: CGPoint(x: (85 - ox) * sx, y: (136 - oy) * sy))
                p.addQuadCurve(to: CGPoint(x: (111 - ox) * sx, y: (136 - oy) * sy), control: CGPoint(x: (98 - ox) * sx, y: (126 - oy) * sy))
            }.stroke(GhostPalette.feature, style: StrokeStyle(lineWidth: 4 * sx, lineCap: .round))
            Path { p in
                p.move(to: CGPoint(x: (131 - ox) * sx, y: (108 - oy) * sy))
                p.addCurve(to: CGPoint(x: (131 - ox) * sx, y: (132 - oy) * sy), control1: CGPoint(x: (137 - ox) * sx, y: (116 - oy) * sy), control2: CGPoint(x: (137 - ox) * sx, y: (124 - oy) * sy))
                p.addCurve(to: CGPoint(x: (131 - ox) * sx, y: (108 - oy) * sy), control1: CGPoint(x: (125 - ox) * sx, y: (124 - oy) * sy), control2: CGPoint(x: (125 - ox) * sx, y: (116 - oy) * sy))
                p.closeSubpath()
            }.fill(GhostPalette.teardrop)
        }
    }
    
    private var surprisedFace: some View {
        ZStack {
            Circle().fill(GhostPalette.feature).frame(width: 18 * sx, height: 18 * sy).position(x: 78 * sx, y: 99 * sy)
            Circle().fill(GhostPalette.feature).frame(width: 18 * sx, height: 18 * sy).position(x: 117 * sx, y: 99 * sy)
            Circle().fill(GhostPalette.white).frame(width: 5.2 * sx, height: 5.2 * sy).position(x: 75 * sx, y: 95 * sy)
            Circle().fill(GhostPalette.white).frame(width: 3.6 * sx, height: 3.6 * sy).position(x: 81 * sx, y: 101 * sy)
            Circle().fill(GhostPalette.white).frame(width: 5.2 * sx, height: 5.2 * sy).position(x: 114 * sx, y: 95 * sy)
            Circle().fill(GhostPalette.white).frame(width: 3.6 * sx, height: 3.6 * sy).position(x: 120 * sx, y: 101 * sy)
            Circle().fill(GhostPalette.white).frame(width: 16 * sx, height: 16 * sy).position(x: 98 * sx, y: 129 * sy)
        }
    }
    
    private var sleepyFace: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: (68 - ox) * sx, y: (101 - oy) * sy))
                p.addQuadCurve(to: CGPoint(x: (88 - ox) * sx, y: (101 - oy) * sy), control: CGPoint(x: (78 - ox) * sx, y: (106 - oy) * sy))
            }.stroke(GhostPalette.feature, style: StrokeStyle(lineWidth: 4 * sx, lineCap: .round))
            Path { p in
                p.move(to: CGPoint(x: (108 - ox) * sx, y: (101 - oy) * sy))
                p.addQuadCurve(to: CGPoint(x: (128 - ox) * sx, y: (101 - oy) * sy), control: CGPoint(x: (118 - ox) * sx, y: (106 - oy) * sy))
            }.stroke(GhostPalette.feature, style: StrokeStyle(lineWidth: 4 * sx, lineCap: .round))
            Circle().fill(GhostPalette.bodyMid).frame(width: 28 * sx, height: 28 * sy).position(x: 97 * sx, y: 129 * sy)
        }
    }
    
    private var closedFace: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: (68 - ox) * sx, y: (104 - oy) * sy))
                p.addQuadCurve(to: CGPoint(x: (88 - ox) * sx, y: (104 - oy) * sy), control: CGPoint(x: (78 - ox) * sx, y: (110 - oy) * sy))
            }.stroke(GhostPalette.feature, style: StrokeStyle(lineWidth: 4 * sx, lineCap: .round))
            Path { p in
                p.move(to: CGPoint(x: (108 - ox) * sx, y: (104 - oy) * sy))
                p.addQuadCurve(to: CGPoint(x: (128 - ox) * sx, y: (104 - oy) * sy), control: CGPoint(x: (118 - ox) * sx, y: (110 - oy) * sy))
            }.stroke(GhostPalette.feature, style: StrokeStyle(lineWidth: 4 * sx, lineCap: .round))
            Circle().fill(GhostPalette.bodyMid).frame(width: 32 * sx, height: 32 * sy).position(x: 98 * sx, y: 130 * sy)
        }
    }
    
    private var glassesFace: some View {
        ZStack {
            defaultEyesAndMouth
            Circle().stroke(GhostPalette.feature, lineWidth: 4 * sx).frame(width: 30 * sx, height: 30 * sy).position(x: 78 * sx, y: 99 * sy)
            Circle().stroke(GhostPalette.feature, lineWidth: 4 * sx).frame(width: 30 * sx, height: 30 * sy).position(x: 117 * sx, y: 99 * sy)
            Path { p in
                p.move(to: CGPoint(x: 93 * sx, y: 99 * sy))
                p.addLine(to: CGPoint(x: 102 * sx, y: 99 * sy))
            }.stroke(GhostPalette.feature, lineWidth: 3 * sx)
        }
    }
    
    private var winkFace: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: 69 * sx, y: 99 * sy))
                p.addLine(to: CGPoint(x: 87 * sx, y: 99 * sy))
            }.stroke(GhostPalette.feature, style: StrokeStyle(lineWidth: 4 * sx, lineCap: .round))
            Circle().fill(GhostPalette.feature).frame(width: 18 * sx, height: 18 * sy).position(x: 117 * sx, y: 99 * sy)
            Circle().fill(GhostPalette.white).frame(width: 5.2 * sx, height: 5.2 * sy).position(x: 114 * sx, y: 95 * sy)
            Circle().fill(GhostPalette.white).frame(width: 3.6 * sx, height: 3.6 * sy).position(x: 120 * sx, y: 101 * sy)
            Path { p in
                p.move(to: CGPoint(x: (81 - ox) * sx, y: (129 - oy) * sy))
                p.addCurve(to: CGPoint(x: (114 - ox) * sx, y: (129 - oy) * sy), control1: CGPoint(x: (87 - ox) * sx, y: (123 - oy) * sy), control2: CGPoint(x: (107 - ox) * sx, y: (123 - oy) * sy))
                p.addCurve(to: CGPoint(x: (81 - ox) * sx, y: (129 - oy) * sy), control1: CGPoint(x: (108 - ox) * sx, y: (136 - oy) * sy), control2: CGPoint(x: (87 - ox) * sx, y: (136 - oy) * sy))
                p.closeSubpath()
            }.fill(GhostPalette.white)
        }
    }
    
    private var flameEyesFace: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5 * sx).fill(GhostPalette.feature)
                .frame(width: 19 * sx, height: 19 * sy).position(x: (68 + 9.5) * sx, y: (88 + 9.5) * sy)
            RoundedRectangle(cornerRadius: 5 * sx).fill(GhostPalette.feature)
                .frame(width: 19 * sx, height: 19 * sy).position(x: (107 + 9.5) * sx, y: (88 + 9.5) * sy)
            Image(systemName: "sparkle")
                .font(.system(size: 8 * sx))
                .foregroundStyle(GhostPalette.white)
                .position(x: (68 + 9.5) * sx, y: (88 + 9.5) * sy)
            Image(systemName: "sparkle")
                .font(.system(size: 8 * sx))
                .foregroundStyle(GhostPalette.white)
                .position(x: (107 + 9.5) * sx, y: (88 + 9.5) * sy)
            Path { p in
                p.move(to: CGPoint(x: (82 - ox) * sx, y: (126 - oy) * sy))
                p.addCurve(to: CGPoint(x: (114 - ox) * sx, y: (126 - oy) * sy), control1: CGPoint(x: (88 - ox) * sx, y: (120 - oy) * sy), control2: CGPoint(x: (108 - ox) * sx, y: (120 - oy) * sy))
                p.addCurve(to: CGPoint(x: (82 - ox) * sx, y: (126 - oy) * sy), control1: CGPoint(x: (108 - ox) * sx, y: (133 - oy) * sy), control2: CGPoint(x: (88 - ox) * sx, y: (133 - oy) * sy))
                p.closeSubpath()
            }.fill(GhostPalette.white)
        }
    }
}

struct GhostPropsView: View {
    let pose: GhostPose
    let sx: CGFloat
    let sy: CGFloat
    let ox: CGFloat = 0
    let oy: CGFloat = 0
    
    var body: some View {
        ZStack {
            switch pose {
            case .wave:
                Path { p in
                    p.move(to: CGPoint(x: (21 - ox) * sx, y: (89 - oy) * sy))
                    p.addCurve(to: CGPoint(x: (1 - ox) * sx, y: (111 - oy) * sy), control1: CGPoint(x: (9 - ox) * sx, y: (90 - oy) * sy), control2: CGPoint(x: (1 - ox) * sx, y: (100 - oy) * sy))
                    p.addCurve(to: CGPoint(x: (16 - ox) * sx, y: (129 - oy) * sy), control1: CGPoint(x: (1 - ox) * sx, y: (121 - oy) * sy), control2: CGPoint(x: (8 - ox) * sx, y: (129 - oy) * sy))
                    p.addCurve(to: CGPoint(x: (31 - ox) * sx, y: (115 - oy) * sy), control1: CGPoint(x: (24 - ox) * sx, y: (129 - oy) * sy), control2: CGPoint(x: (30 - ox) * sx, y: (123 - oy) * sy))
                    p.addCurve(to: CGPoint(x: (21 - ox) * sx, y: (89 - oy) * sy), control1: CGPoint(x: (33 - ox) * sx, y: (104 - oy) * sy), control2: CGPoint(x: (31 - ox) * sx, y: (94 - oy) * sy))
                    p.closeSubpath()
                }
                .fill(GhostPalette.bodyDark)
            case .reading:
                bookProp
                pencilProp
            case .studying:
                bookProp
            case .writing:
                pencilProp
            case .flame:
                flameProp
            default:
                EmptyView()
            }
        }
    }
    
    private var bookProp: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: (23 - ox) * sx, y: (112 - oy) * sy))
                p.addCurve(to: CGPoint(x: (12 - ox) * sx, y: (124 - oy) * sy), control1: CGPoint(x: (17 - ox) * sx, y: (112 - oy) * sy), control2: CGPoint(x: (12 - ox) * sx, y: (117 - oy) * sy))
                p.addLine(to: CGPoint(x: (12 - ox) * sx, y: (158 - oy) * sy))
                p.addCurve(to: CGPoint(x: (23 - ox) * sx, y: (170 - oy) * sy), control1: CGPoint(x: (12 - ox) * sx, y: (165 - oy) * sy), control2: CGPoint(x: (17 - ox) * sx, y: (170 - oy) * sy))
                p.addLine(to: CGPoint(x: (41 - ox) * sx, y: (170 - oy) * sy))
                p.addLine(to: CGPoint(x: (41 - ox) * sx, y: (112 - oy) * sy))
                p.closeSubpath()
            }.fill(GhostPalette.book)
            Path { p in
                p.move(to: CGPoint(x: (41 - ox) * sx, y: (112 - oy) * sy))
                p.addLine(to: CGPoint(x: (52 - ox) * sx, y: (116 - oy) * sy))
                p.addLine(to: CGPoint(x: (52 - ox) * sx, y: (166 - oy) * sy))
                p.addLine(to: CGPoint(x: (41 - ox) * sx, y: (170 - oy) * sy))
                p.closeSubpath()
            }.fill(GhostPalette.bookDark)
            Path { p in
                p.move(to: CGPoint(x: (31 - ox) * sx, y: (113 - oy) * sy))
                p.addCurve(to: CGPoint(x: (13 - ox) * sx, y: (110 - oy) * sy), control1: CGPoint(x: (26 - ox) * sx, y: (107 - oy) * sy), control2: CGPoint(x: (18 - ox) * sx, y: (106 - oy) * sy))
                p.addCurve(to: CGPoint(x: (11 - ox) * sx, y: (128 - oy) * sy), control1: CGPoint(x: (8 - ox) * sx, y: (114 - oy) * sy), control2: CGPoint(x: (7 - ox) * sx, y: (122 - oy) * sy))
                p.addCurve(to: CGPoint(x: (29 - ox) * sx, y: (133 - oy) * sy), control1: CGPoint(x: (15 - ox) * sx, y: (134 - oy) * sy), control2: CGPoint(x: (22 - ox) * sx, y: (136 - oy) * sy))
                p.addCurve(to: CGPoint(x: (31 - ox) * sx, y: (113 - oy) * sy), control1: CGPoint(x: (34 - ox) * sx, y: (131 - oy) * sy), control2: CGPoint(x: (37 - ox) * sx, y: (122 - oy) * sy))
                p.closeSubpath()
            }.fill(GhostPalette.body)
        }
    }
    
    private var pencilProp: some View {
        ZStack {
            ZStack {
                RoundedRectangle(cornerRadius: 4 * sx).fill(GhostPalette.pencil)
                    .frame(width: 20 * sx, height: 50 * sy)
                    .position(x: (127 + 10) * sx, y: (118 + 25) * sy)
                RoundedRectangle(cornerRadius: 2 * sx).fill(GhostPalette.pencilBand)
                    .frame(width: 9 * sx, height: 50 * sy)
                    .position(x: (147 + 4.5) * sx, y: (118 + 25) * sy)
                Path { p in
                    p.move(to: CGPoint(x: (127 - ox) * sx, y: (168 - oy) * sy))
                    p.addLine(to: CGPoint(x: (137 - ox) * sx, y: (182 - oy) * sy))
                    p.addLine(to: CGPoint(x: (147 - ox) * sx, y: (168 - oy) * sy))
                    p.closeSubpath()
                }.fill(GhostPalette.pencilTip)
                Path { p in
                    p.move(to: CGPoint(x: (134 - ox) * sx, y: (176 - oy) * sy))
                    p.addLine(to: CGPoint(x: (140 - ox) * sx, y: (176 - oy) * sy))
                    p.addLine(to: CGPoint(x: (137 - ox) * sx, y: (182 - oy) * sy))
                    p.closeSubpath()
                }.fill(GhostPalette.feature)
            }
            .rotationEffect(.degrees(24), anchor: UnitPoint(x: 150.0 / 190.0, y: 140.0 / 240.0))
            Path { p in
                p.move(to: CGPoint(x: (130 - ox) * sx, y: (111 - oy) * sy))
                p.addCurve(to: CGPoint(x: (149 - ox) * sx, y: (113 - oy) * sy), control1: CGPoint(x: (136 - ox) * sx, y: (106 - oy) * sy), control2: CGPoint(x: (145 - ox) * sx, y: (107 - oy) * sy))
                p.addCurve(to: CGPoint(x: (145 - ox) * sx, y: (132 - oy) * sy), control1: CGPoint(x: (153 - ox) * sx, y: (119 - oy) * sy), control2: CGPoint(x: (151 - ox) * sx, y: (128 - oy) * sy))
                p.addCurve(to: CGPoint(x: (124 - ox) * sx, y: (129 - oy) * sy), control1: CGPoint(x: (138 - ox) * sx, y: (137 - oy) * sy), control2: CGPoint(x: (129 - ox) * sx, y: (136 - oy) * sy))
                p.addCurve(to: CGPoint(x: (130 - ox) * sx, y: (111 - oy) * sy), control1: CGPoint(x: (120 - ox) * sx, y: (123 - oy) * sy), control2: CGPoint(x: (123 - ox) * sx, y: (115 - oy) * sy))
                p.closeSubpath()
            }.fill(GhostPalette.body)
        }
    }
    
    private var flameProp: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: (0 - -33) * sx, y: (26 - -17) * sy))
                p.addCurve(to: CGPoint(x: (13 - -33) * sx, y: (4 - -17) * sy), control1: CGPoint(x: (-5 - -33) * sx, y: (15 - -17) * sy), control2: CGPoint(x: (2 - -33) * sx, y: (6 - -17) * sy))
                p.addCurve(to: CGPoint(x: (22 - -33) * sx, y: (17 - -17) * sy), control1: CGPoint(x: (12 - -33) * sx, y: (9 - -17) * sy), control2: CGPoint(x: (16 - -33) * sx, y: (14 - -17) * sy))
                p.addCurve(to: CGPoint(x: (38 - -33) * sx, y: (2 - -17) * sy), control1: CGPoint(x: (22 - -33) * sx, y: (8 - -17) * sy), control2: CGPoint(x: (29 - -33) * sx, y: (2 - -17) * sy))
                p.addCurve(to: CGPoint(x: (45 - -33) * sx, y: (18 - -17) * sy), control1: CGPoint(x: (35 - -33) * sx, y: (8 - -17) * sy), control2: CGPoint(x: (39 - -33) * sx, y: (13 - -17) * sy))
                p.addCurve(to: CGPoint(x: (51 - -33) * sx, y: (35 - -17) * sy), control1: CGPoint(x: (50 - -33) * sx, y: (22 - -17) * sy), control2: CGPoint(x: (52 - -33) * sx, y: (28 - -17) * sy))
                p.addCurve(to: CGPoint(x: (29 - -33) * sx, y: (54 - -17) * sy), control1: CGPoint(x: (49 - -33) * sx, y: (46 - -17) * sy), control2: CGPoint(x: (40 - -33) * sx, y: (53 - -17) * sy))
                p.addCurve(to: CGPoint(x: (2 - -33) * sx, y: (37 - -17) * sy), control1: CGPoint(x: (17 - -33) * sx, y: (55 - -17) * sy), control2: CGPoint(x: (7 - -33) * sx, y: (48 - -17) * sy))
                p.addCurve(to: CGPoint(x: (0 - -33) * sx, y: (26 - -17) * sy), control1: CGPoint(x: (1 - -33) * sx, y: (34 - -17) * sy), control2: CGPoint(x: (0 - -33) * sx, y: (30 - -17) * sy))
                p.closeSubpath()
            }.fill(GhostPalette.flameOuter)
            
            Path { p in
                p.move(to: CGPoint(x: (18 - -33) * sx, y: (36 - -17) * sy))
                p.addCurve(to: CGPoint(x: (27 - -33) * sx, y: (20 - -17) * sy), control1: CGPoint(x: (16 - -33) * sx, y: (29 - -17) * sy), control2: CGPoint(x: (21 - -33) * sx, y: (23 - -17) * sy))
                p.addCurve(to: CGPoint(x: (34 - -33) * sx, y: (31 - -17) * sy), control1: CGPoint(x: (27 - -33) * sx, y: (24 - -17) * sy), control2: CGPoint(x: (30 - -33) * sx, y: (28 - -17) * sy))
                p.addCurve(to: CGPoint(x: (39 - -33) * sx, y: (41 - -17) * sy), control1: CGPoint(x: (37 - -33) * sx, y: (33 - -17) * sy), control2: CGPoint(x: (39 - -33) * sx, y: (36 - -17) * sy))
                p.addCurve(to: CGPoint(x: (28 - -33) * sx, y: (52 - -17) * sy), control1: CGPoint(x: (39 - -33) * sx, y: (48 - -17) * sy), control2: CGPoint(x: (34 - -33) * sx, y: (52 - -17) * sy))
                p.addCurve(to: CGPoint(x: (16 - -33) * sx, y: (41 - -17) * sy), control1: CGPoint(x: (21 - -33) * sx, y: (52 - -17) * sy), control2: CGPoint(x: (16 - -33) * sx, y: (47 - -17) * sy))
                p.addCurve(to: CGPoint(x: (18 - -33) * sx, y: (36 - -17) * sy), control1: CGPoint(x: (16 - -33) * sx, y: (39 - -17) * sy), control2: CGPoint(x: (17 - -33) * sx, y: (37 - -17) * sy))
                p.closeSubpath()
            }.fill(GhostPalette.flameInner)
        }
    }
}

struct GhostWingsShape: Shape {
    var sx: CGFloat
    var sy: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let ox: CGFloat = 0
        let oy: CGFloat = 0
        p.move(to: CGPoint(x: (18 - ox) * sx, y: (117 - oy) * sy))
        p.addCurve(to: CGPoint(x: (8 - ox) * sx, y: (74 - oy) * sy), control1: CGPoint(x: (2 - ox) * sx, y: (106 - oy) * sy), control2: CGPoint(x: (-3 - ox) * sx, y: (88 - oy) * sy))
        p.addCurve(to: CGPoint(x: (32 - ox) * sx, y: (108 - oy) * sy), control1: CGPoint(x: (20 - ox) * sx, y: (80 - oy) * sy), control2: CGPoint(x: (29 - ox) * sx, y: (93 - oy) * sy))
        p.addCurve(to: CGPoint(x: (53 - ox) * sx, y: (74 - oy) * sy), control1: CGPoint(x: (34 - ox) * sx, y: (94 - oy) * sy), control2: CGPoint(x: (41 - ox) * sx, y: (81 - oy) * sy))
        p.addCurve(to: CGPoint(x: (31 - ox) * sx, y: (120 - oy) * sy), control1: CGPoint(x: (58 - ox) * sx, y: (94 - oy) * sy), control2: CGPoint(x: (46 - ox) * sx, y: (112 - oy) * sy))
        p.closeSubpath()
        p.move(to: CGPoint(x: (203 - ox) * sx, y: (117 - oy) * sy))
        p.addCurve(to: CGPoint(x: (213 - ox) * sx, y: (74 - oy) * sy), control1: CGPoint(x: (219 - ox) * sx, y: (106 - oy) * sy), control2: CGPoint(x: (224 - ox) * sx, y: (88 - oy) * sy))
        p.addCurve(to: CGPoint(x: (189 - ox) * sx, y: (108 - oy) * sy), control1: CGPoint(x: (201 - ox) * sx, y: (80 - oy) * sy), control2: CGPoint(x: (192 - ox) * sx, y: (93 - oy) * sy))
        p.addCurve(to: CGPoint(x: (168 - ox) * sx, y: (74 - oy) * sy), control1: CGPoint(x: (187 - ox) * sx, y: (94 - oy) * sy), control2: CGPoint(x: (180 - ox) * sx, y: (81 - oy) * sy))
        p.addCurve(to: CGPoint(x: (190 - ox) * sx, y: (120 - oy) * sy), control1: CGPoint(x: (163 - ox) * sx, y: (94 - oy) * sy), control2: CGPoint(x: (175 - ox) * sx, y: (112 - oy) * sy))
        p.closeSubpath()
        return p
    }
}

struct GhostCoffeeMachineProp: View {
    let sx: CGFloat
    let sy: CGFloat
    
    var body: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: (0 - -103) * sx, y: (0 - -46) * sy))
                p.addLine(to: CGPoint(x: (53 - -103) * sx, y: (0 - -46) * sy))
                p.addCurve(to: CGPoint(x: (71 - -103) * sx, y: (18 - -46) * sy), control1: CGPoint(x: (63 - -103) * sx, y: (0 - -46) * sy), control2: CGPoint(x: (71 - -103) * sx, y: (8 - -46) * sy))
                p.addLine(to: CGPoint(x: (71 - -103) * sx, y: (81 - -46) * sy))
                p.addCurve(to: CGPoint(x: (53 - -103) * sx, y: (99 - -46) * sy), control1: CGPoint(x: (71 - -103) * sx, y: (91 - -46) * sy), control2: CGPoint(x: (63 - -103) * sx, y: (99 - -46) * sy))
                p.addLine(to: CGPoint(x: (35 - -103) * sx, y: (99 - -46) * sy))
                p.addCurve(to: CGPoint(x: (19 - -103) * sx, y: (121 - -46) * sy), control1: CGPoint(x: (34 - -103) * sx, y: (108 - -46) * sy), control2: CGPoint(x: (28 - -103) * sx, y: (116 - -46) * sy))
                p.addCurve(to: CGPoint(x: (51 - -103) * sx, y: (104 - -46) * sy), control1: CGPoint(x: (33 - -103) * sx, y: (118 - -46) * sy), control2: CGPoint(x: (43 - -103) * sx, y: (113 - -46) * sy))
                p.addLine(to: CGPoint(x: (72 - -103) * sx, y: (104 - -46) * sy))
                p.addCurve(to: CGPoint(x: (88 - -103) * sx, y: (120 - -46) * sy), control1: CGPoint(x: (81 - -103) * sx, y: (104 - -46) * sy), control2: CGPoint(x: (88 - -103) * sx, y: (111 - -46) * sy))
                p.addLine(to: CGPoint(x: (88 - -103) * sx, y: (136 - -46) * sy))
                p.addLine(to: CGPoint(x: (4 - -103) * sx, y: (136 - -46) * sy))
                p.addLine(to: CGPoint(x: (4 - -103) * sx, y: (118 - -46) * sy))
                p.addLine(to: CGPoint(x: (42 - -103) * sx, y: (118 - -46) * sy))
                p.addCurve(to: CGPoint(x: (55 - -103) * sx, y: (96 - -46) * sy), control1: CGPoint(x: (52 - -103) * sx, y: (114 - -46) * sy), control2: CGPoint(x: (55 - -103) * sx, y: (106 - -46) * sy))
                p.addLine(to: CGPoint(x: (40 - -103) * sx, y: (96 - -46) * sy))
                p.addCurve(to: CGPoint(x: (24 - -103) * sx, y: (80 - -46) * sy), control1: CGPoint(x: (31 - -103) * sx, y: (96 - -46) * sy), control2: CGPoint(x: (24 - -103) * sx, y: (89 - -46) * sy))
                p.addLine(to: CGPoint(x: (24 - -103) * sx, y: (20 - -46) * sy))
                p.addCurve(to: CGPoint(x: (40 - -103) * sx, y: (4 - -46) * sy), control1: CGPoint(x: (24 - -103) * sx, y: (11 - -46) * sy), control2: CGPoint(x: (31 - -103) * sx, y: (4 - -46) * sy))
                p.addLine(to: CGPoint(x: (0 - -103) * sx, y: (4 - -46) * sy))
                p.closeSubpath()
            }.fill(GhostPalette.machine)
            
            RoundedRectangle(cornerRadius: 7 * sx).fill(GhostPalette.machineTop)
                .frame(width: 70 * sx, height: 14 * sy)
                .position(x: (103 - 9 + 35) * sx, y: (46 - 2 + 7) * sy)
            
            RoundedRectangle(cornerRadius: 5 * sx).fill(GhostPalette.machineDark)
                .frame(width: 82 * sx, height: 10 * sy)
                .position(x: (103 + 41) * sx, y: (46 + 116 + 5) * sy)
            
            Path { p in
                p.addRect(CGRect(x: (103 + 46) * sx, y: (46 + 28) * sy, width: 22 * sx, height: 2 * sy))
                p.addRect(CGRect(x: (103 + 39) * sx, y: (46 + 76) * sy, width: 23 * sx, height: 3 * sy))
            }.fill(GhostPalette.feature)
            
            RoundedRectangle(cornerRadius: 5 * sx).fill(GhostPalette.cup)
                .frame(width: 35 * sx, height: 10 * sy)
                .position(x: (103 + 33 + 17.5) * sx, y: (46 + 84 + 5) * sy)
                
            RoundedRectangle(cornerRadius: 4 * sx).fill(GhostPalette.machineTop)
                .frame(width: 32 * sx, height: 9 * sy)
                .position(x: (103 + 34 + 16) * sx, y: (46 + 94 + 4.5) * sy)
        }
    }
}
