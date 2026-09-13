import re

def parse_svg_path_to_swift(d_str, indent="            ", sx_name="sx", sy_name="sy", ox_name="ox", oy_name="oy"):
    tokens = re.findall(r'([A-Za-z]|[-+]?(?:\d*\.\d+|\d+))', d_str)
    lines = []
    i = 0
    current_cmd = None
    cur_x = 0.0
    cur_y = 0.0
    
    while i < len(tokens):
        token = tokens[i]
        if token.isalpha():
            current_cmd = token
            i += 1
            if i >= len(tokens) and current_cmd in ('Z', 'z'):
                lines.append(f"{indent}p.closeSubpath()")
                break
        
        if current_cmd == 'M':
            x = float(tokens[i])
            y = float(tokens[i+1])
            lines.append(f"{indent}p.move(to: CGPoint(x: ({x:g} - {ox_name}) * {sx_name}, y: ({y:g} - {oy_name}) * {sy_name}))")
            cur_x, cur_y = x, y
            i += 2
            current_cmd = 'L'
        elif current_cmd == 'L':
            x = float(tokens[i])
            y = float(tokens[i+1])
            lines.append(f"{indent}p.addLine(to: CGPoint(x: ({x:g} - {ox_name}) * {sx_name}, y: ({y:g} - {oy_name}) * {sy_name}))")
            cur_x, cur_y = x, y
            i += 2
        elif current_cmd == 'H':
            x = float(tokens[i])
            lines.append(f"{indent}p.addLine(to: CGPoint(x: ({x:g} - {ox_name}) * {sx_name}, y: ({cur_y:g} - {oy_name}) * {sy_name}))")
            cur_x = x
            i += 1
        elif current_cmd == 'V':
            y = float(tokens[i])
            lines.append(f"{indent}p.addLine(to: CGPoint(x: ({cur_x:g} - {ox_name}) * {sx_name}, y: ({y:g} - {oy_name}) * {sy_name}))")
            cur_y = y
            i += 1
        elif current_cmd == 'C':
            c1x = float(tokens[i])
            c1y = float(tokens[i+1])
            c2x = float(tokens[i+2])
            c2y = float(tokens[i+3])
            ex = float(tokens[i+4])
            ey = float(tokens[i+5])
            lines.append(f"{indent}p.addCurve(to: CGPoint(x: ({ex:g} - {ox_name}) * {sx_name}, y: ({ey:g} - {oy_name}) * {sy_name}), control1: CGPoint(x: ({c1x:g} - {ox_name}) * {sx_name}, y: ({c1y:g} - {oy_name}) * {sy_name}), control2: CGPoint(x: ({c2x:g} - {ox_name}) * {sx_name}, y: ({c2y:g} - {oy_name}) * {sy_name}))")
            cur_x, cur_y = ex, ey
            i += 6
        elif current_cmd == 'Q':
            cx = float(tokens[i])
            cy = float(tokens[i+1])
            ex = float(tokens[i+2])
            ey = float(tokens[i+3])
            lines.append(f"{indent}p.addQuadCurve(to: CGPoint(x: ({ex:g} - {ox_name}) * {sx_name}, y: ({ey:g} - {oy_name}) * {sy_name}), control: CGPoint(x: ({cx:g} - {ox_name}) * {sx_name}, y: ({cy:g} - {oy_name}) * {sy_name}))")
            cur_x, cur_y = ex, ey
            i += 4
        elif current_cmd == 'Z' or current_cmd == 'z':
            lines.append(f"{indent}p.closeSubpath()")
            current_cmd = None
        else:
            i += 1
            
    return "\n".join(lines)

p_body = parse_svg_path_to_swift("M71 28 C96 21, 128 23, 148 34 C163 42, 171 56, 171 76 L171 163 C171 182, 168 199, 164 211 C160 221, 151 227, 141 227 C132 227, 125 223, 119 214 C113 225, 103 231, 92 231 C81 231, 71 225, 65 214 C59 224, 49 231, 37 231 C27 231, 18 225, 15 214 C11 201, 9 184, 9 164 L9 79 C9 58, 17 43, 33 34 C44 28, 57 25, 71 28 Z", indent="                ")
p_accent = parse_svg_path_to_swift("M171 164 C171 183, 168 199, 164 211 C160 221, 151 227, 141 227 C132 227, 125 223, 119 214 C113 225, 103 231, 92 231 C81 231, 71 225, 65 214 C59 224, 49 231, 37 231 C27 231, 18 225, 15 214 C11 201, 9 184, 9 164 C21 173, 34 178, 51 178 C73 178, 90 169, 105 171 C123 173, 138 181, 156 176 C162 174, 167 170, 171 164 Z", indent="                ")
p_mid = parse_svg_path_to_swift("M171 164 C167 176, 162 180, 154 183 C140 188, 130 183, 118 178 C108 174, 98 173, 90 175 C80 177, 71 182, 60 184 C44 187, 27 184, 9 164 C9 184, 11 201, 15 214 C18 225, 27 231, 37 231 C49 231, 59 224, 65 214 C71 225, 81 231, 92 231 C103 231, 113 225, 119 214 C125 223, 132 227, 141 227 C151 227, 160 221, 164 211 C168 199, 171 182, 171 164 Z", indent="                ")
p_arm = parse_svg_path_to_swift("M170 116 C179 117, 185 124, 185 132 C185 140, 180 146, 173 147 C167 147, 163 142, 163 135 C163 128, 165 121, 170 116 Z", indent="                ")
p_mouth_def = parse_svg_path_to_swift("M81 129 C87 123, 107 123, 114 129 C108 136, 87 136, 81 129 Z", indent="                ")
p_mouth_happy = parse_svg_path_to_swift("M80 128 C88 121, 108 121, 116 128 C109 139, 87 139, 80 128 Z", indent="                ")
p_angry_b1 = parse_svg_path_to_swift("M67 89 L84 94", indent="                ")
p_angry_b2 = parse_svg_path_to_swift("M127 94 L144 89", indent="                ")
p_angry_m = parse_svg_path_to_swift("M86 134 Q98 124 110 134", indent="                ")
p_sad_b1 = parse_svg_path_to_swift("M69 100 Q78 94 87 100", indent="                ")
p_sad_b2 = parse_svg_path_to_swift("M108 100 Q117 94 126 100", indent="                ")
p_sad_m = parse_svg_path_to_swift("M85 136 Q98 126 111 136", indent="                ")
p_tear = parse_svg_path_to_swift("M131 108 C137 116, 137 124, 131 132 C125 124, 125 116, 131 108 Z", indent="                ")
p_sleepy_e1 = parse_svg_path_to_swift("M68 101 Q78 106 88 101", indent="                ")
p_sleepy_e2 = parse_svg_path_to_swift("M108 101 Q118 106 128 101", indent="                ")
p_closed_e1 = parse_svg_path_to_swift("M68 104 Q78 110 88 104", indent="                ")
p_closed_e2 = parse_svg_path_to_swift("M108 104 Q118 110 128 104", indent="                ")
p_flame_m = parse_svg_path_to_swift("M82 126 C88 120, 108 120, 114 126 C108 133, 88 133, 82 126 Z", indent="                ")
p_wave_arm = parse_svg_path_to_swift("M21 89 C9 90, 1 100, 1 111 C1 121, 8 129, 16 129 C24 129, 30 123, 31 115 C33 104, 31 94, 21 89 Z", indent="                    ")
p_book_cov = parse_svg_path_to_swift("M23 112 C17 112, 12 117, 12 124 L12 158 C12 165, 17 170, 23 170 L41 170 L41 112 Z", indent="                ")
p_book_dark = parse_svg_path_to_swift("M41 112 L52 116 L52 166 L41 170 Z", indent="                ")
p_book_hand = parse_svg_path_to_swift("M31 113 C26 107, 18 106, 13 110 C8 114, 7 122, 11 128 C15 134, 22 136, 29 133 C34 131, 37 122, 31 113 Z", indent="                ")
p_pencil_tip = parse_svg_path_to_swift("M127 168 L137 182 L147 168 Z", indent="                    ")
p_pencil_lead = parse_svg_path_to_swift("M134 176 L140 176 L137 182 Z", indent="                    ")
p_pencil_hand = parse_svg_path_to_swift("M130 111 C136 106, 145 107, 149 113 C153 119, 151 128, 145 132 C138 137, 129 136, 124 129 C120 123, 123 115, 130 111 Z", indent="                ")
p_flame_out = parse_svg_path_to_swift("M0 26 C-5 15 2 6 13 4 C12 9 16 14 22 17 C22 8 29 2 38 2 C35 8 39 13 45 18 C50 22 52 28 51 35 C49 46 40 53 29 54 C17 55 7 48 2 37 C1 34 0 30 0 26 Z", indent="                ", ox_name="-33", oy_name="-17")
p_flame_in = parse_svg_path_to_swift("M18 36 C16 29 21 23 27 20 C27 24 30 28 34 31 C37 33 39 36 39 41 C39 48 34 52 28 52 C21 52 16 47 16 41 C16 39 17 37 18 36 Z", indent="                ", ox_name="-33", oy_name="-17")
p_wing_l = parse_svg_path_to_swift("M18 117 C2 106, -3 88, 8 74 C20 80, 29 93, 32 108 C34 94, 41 81, 53 74 C58 94, 46 112, 31 120 Z", indent="        ")
p_wing_r = parse_svg_path_to_swift("M203 117 C219 106, 224 88, 213 74 C201 80, 192 93, 189 108 C187 94, 180 81, 168 74 C163 94, 175 112, 190 120 Z", indent="        ")
p_machine_b = parse_svg_path_to_swift("M0 0 H53 C63 0, 71 8, 71 18 V81 C71 91, 63 99, 53 99 H35 C34 108, 28 116, 19 121 C33 118, 43 113, 51 104 H72 C81 104, 88 111, 88 120 V136 H4 V118 H42 C52 114, 55 106, 55 96 H40 C31 96, 24 89, 24 80 V20 C24 11, 31 4, 40 4 H0 Z", indent="                ", ox_name="-103", oy_name="-46")

template = """//
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
    
    @Environment(\\.accessibilityReduceMotion) private var reduceMotion
    
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
__P_BODY__
            }
            .fill(GhostPalette.body)
            
            Path { p in
__P_ACCENT__
            }
            .fill(GhostPalette.accent.opacity(0.35))
            
            Path { p in
__P_MID__
            }
            .fill(GhostPalette.bodyMid.opacity(0.20))
            
            Path { p in
__P_ARM__
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
__P_MOUTH_DEF__
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
__P_MOUTH_HAPPY__
            }
            .fill(GhostPalette.white)
        }
    }
    
    private var angryFace: some View {
        ZStack {
            Path { p in
__P_ANGRY_B1__
            }.stroke(GhostPalette.feature, style: StrokeStyle(lineWidth: 4 * sx, lineCap: .round))
            Path { p in
__P_ANGRY_B2__
            }.stroke(GhostPalette.feature, style: StrokeStyle(lineWidth: 4 * sx, lineCap: .round))
            Circle().fill(GhostPalette.feature).frame(width: 16 * sx, height: 16 * sy).position(x: 79 * sx, y: 100 * sy)
            Circle().fill(GhostPalette.feature).frame(width: 16 * sx, height: 16 * sy).position(x: 116 * sx, y: 100 * sy)
            Circle().fill(GhostPalette.white).frame(width: 4.4 * sx, height: 4.4 * sy).position(x: 77 * sx, y: 97 * sy)
            Circle().fill(GhostPalette.white).frame(width: 4.4 * sx, height: 4.4 * sy).position(x: 114 * sx, y: 97 * sy)
            Path { p in
__P_ANGRY_M__
            }.stroke(GhostPalette.feature, style: StrokeStyle(lineWidth: 4 * sx, lineCap: .round))
        }
    }
    
    private var sadFace: some View {
        ZStack {
            Path { p in
__P_SAD_B1__
            }.stroke(GhostPalette.feature, style: StrokeStyle(lineWidth: 4 * sx, lineCap: .round))
            Path { p in
__P_SAD_B2__
            }.stroke(GhostPalette.feature, style: StrokeStyle(lineWidth: 4 * sx, lineCap: .round))
            Path { p in
__P_SAD_M__
            }.stroke(GhostPalette.feature, style: StrokeStyle(lineWidth: 4 * sx, lineCap: .round))
            Path { p in
__P_TEAR__
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
__P_SLEEPY_E1__
            }.stroke(GhostPalette.feature, style: StrokeStyle(lineWidth: 4 * sx, lineCap: .round))
            Path { p in
__P_SLEEPY_E2__
            }.stroke(GhostPalette.feature, style: StrokeStyle(lineWidth: 4 * sx, lineCap: .round))
            Circle().fill(GhostPalette.bodyMid).frame(width: 28 * sx, height: 28 * sy).position(x: 97 * sx, y: 129 * sy)
        }
    }
    
    private var closedFace: some View {
        ZStack {
            Path { p in
__P_CLOSED_E1__
            }.stroke(GhostPalette.feature, style: StrokeStyle(lineWidth: 4 * sx, lineCap: .round))
            Path { p in
__P_CLOSED_E2__
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
__P_MOUTH_DEF__
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
__P_FLAME_M__
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
__P_WAVE_ARM__
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
__P_BOOK_COV__
            }.fill(GhostPalette.book)
            Path { p in
__P_BOOK_DARK__
            }.fill(GhostPalette.bookDark)
            Path { p in
__P_BOOK_HAND__
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
__P_PENCIL_TIP__
                }.fill(GhostPalette.pencilTip)
                Path { p in
__P_PENCIL_LEAD__
                }.fill(GhostPalette.feature)
            }
            .rotationEffect(.degrees(24), anchor: UnitPoint(x: 150.0 / 190.0, y: 140.0 / 240.0))
            Path { p in
__P_PENCIL_HAND__
            }.fill(GhostPalette.body)
        }
    }
    
    private var flameProp: some View {
        ZStack {
            Path { p in
__P_FLAME_OUT__
            }.fill(GhostPalette.flameOuter)
            
            Path { p in
__P_FLAME_IN__
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
__P_WING_L__
__P_WING_R__
        return p
    }
}

struct GhostCoffeeMachineProp: View {
    let sx: CGFloat
    let sy: CGFloat
    
    var body: some View {
        ZStack {
            Path { p in
__P_MACHINE_B__
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
"""

replacements = {
    "__P_BODY__": p_body,
    "__P_ACCENT__": p_accent,
    "__P_MID__": p_mid,
    "__P_ARM__": p_arm,
    "__P_MOUTH_DEF__": p_mouth_def,
    "__P_MOUTH_HAPPY__": p_mouth_happy,
    "__P_ANGRY_B1__": p_angry_b1,
    "__P_ANGRY_B2__": p_angry_b2,
    "__P_ANGRY_M__": p_angry_m,
    "__P_SAD_B1__": p_sad_b1,
    "__P_SAD_B2__": p_sad_b2,
    "__P_SAD_M__": p_sad_m,
    "__P_TEAR__": p_tear,
    "__P_SLEEPY_E1__": p_sleepy_e1,
    "__P_SLEEPY_E2__": p_sleepy_e2,
    "__P_CLOSED_E1__": p_closed_e1,
    "__P_CLOSED_E2__": p_closed_e2,
    "__P_FLAME_M__": p_flame_m,
    "__P_WAVE_ARM__": p_wave_arm,
    "__P_BOOK_COV__": p_book_cov,
    "__P_BOOK_DARK__": p_book_dark,
    "__P_BOOK_HAND__": p_book_hand,
    "__P_PENCIL_TIP__": p_pencil_tip,
    "__P_PENCIL_LEAD__": p_pencil_lead,
    "__P_PENCIL_HAND__": p_pencil_hand,
    "__P_FLAME_OUT__": p_flame_out,
    "__P_FLAME_IN__": p_flame_in,
    "__P_WING_L__": p_wing_l,
    "__P_WING_R__": p_wing_r,
    "__P_MACHINE_B__": p_machine_b,
}

swift_code = template
for k, v in replacements.items():
    swift_code = swift_code.replace(k, v)

with open('App/GhostMascotView.swift', 'w', encoding='utf-8') as f:
    f.write(swift_code)

print("Generated App/GhostMascotView.swift successfully! Total bytes:", len(swift_code))
