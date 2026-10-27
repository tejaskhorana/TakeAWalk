import SwiftUI

/// The overall status, shared by the app and the widget.
/// Ideal: an open door with warm light spilling out.
/// Not ideal: a closed door.
struct StatusDoor: View {
    let isIdeal: Bool
    let size: CGFloat

    private let frame = Color(red: 0.36, green: 0.22, blue: 0.16)
    private let openTop = Color(red: 0.95, green: 0.56, blue: 0.34)
    private let openBottom = Color(red: 0.80, green: 0.38, blue: 0.22)
    private let closedTop = Color(red: 0.62, green: 0.52, blue: 0.48)
    private let closedBottom = Color(red: 0.46, green: 0.37, blue: 0.34)
    private let gold = Color(red: 0.98, green: 0.80, blue: 0.40)

    var body: some View {
        Canvas { ctx, canvas in
            // All coordinates are in a 0–1 square, scaled to the canvas.
            let s = min(canvas.width, canvas.height)
            func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }
            func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ radius: CGFloat) -> Path {
                Path(roundedRect: CGRect(x: x * s, y: y * s, width: w * s, height: h * s),
                     cornerRadius: radius * s)
            }

            // Door frame
            ctx.fill(rect(0.18, 0.08, 0.64, 0.84, 0.04), with: .color(frame))

            if isIdeal {
                // Sunlight through the opening
                ctx.fill(rect(0.25, 0.14, 0.50, 0.76, 0.02), with: .radialGradient(
                    Gradient(colors: [Color(red: 1.0, green: 0.98, blue: 0.82),
                                      Color(red: 1.0, green: 0.80, blue: 0.45)]),
                    center: pt(0.5, 0.45), startRadius: 0, endRadius: 0.5 * s))

                // Light spilling onto the floor
                var beam = Path()
                beam.move(to: pt(0.25, 0.90))
                beam.addLine(to: pt(0.75, 0.90))
                beam.addLine(to: pt(0.95, 0.99))
                beam.addLine(to: pt(0.05, 0.99))
                beam.closeSubpath()
                ctx.fill(beam, with: .color(Color(red: 1.0, green: 0.85, blue: 0.50).opacity(0.35)))

                // The door leaf, swung open toward the viewer
                var leaf = Path()
                leaf.move(to: pt(0.25, 0.14))
                leaf.addLine(to: pt(0.41, 0.21))
                leaf.addLine(to: pt(0.41, 0.85))
                leaf.addLine(to: pt(0.25, 0.90))
                leaf.closeSubpath()
                ctx.fill(leaf, with: .linearGradient(
                    Gradient(colors: [openTop, openBottom]),
                    startPoint: pt(0.25, 0.14), endPoint: pt(0.41, 0.85)))

                // Handle
                ctx.fill(Path(ellipseIn: CGRect(x: 0.36 * s, y: 0.52 * s, width: 0.035 * s, height: 0.035 * s)),
                         with: .color(gold))
            } else {
                // Closed door
                ctx.fill(rect(0.25, 0.14, 0.50, 0.76, 0.02), with: .linearGradient(
                    Gradient(colors: [closedTop, closedBottom]),
                    startPoint: pt(0.25, 0.14), endPoint: pt(0.75, 0.90)))

                // Two raised panels
                let panel = frame.opacity(0.45)
                ctx.stroke(rect(0.33, 0.22, 0.34, 0.24, 0.02), with: .color(panel), lineWidth: 0.014 * s)
                ctx.stroke(rect(0.33, 0.52, 0.34, 0.30, 0.02), with: .color(panel), lineWidth: 0.014 * s)

                // Handle
                ctx.fill(Path(ellipseIn: CGRect(x: 0.66 * s, y: 0.52 * s, width: 0.04 * s, height: 0.04 * s)),
                         with: .color(gold))
            }
        }
        .frame(width: size, height: size)
    }
}
