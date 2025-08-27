import SwiftUI

/// LiquidGlassBackground
/// A reusable glass-morphism backdrop that mimics the modern iOS "liquid glass" look.
///
/// Why this exists:
/// - We want a premium, fluid frosted-glass effect for bars/overlays without hand-tuning per-view.
/// - This encapsulates blur + animated soft glow "blobs" + specular highlights + subtle edge stroke.
/// - Keeping it in a single component helps future changes be consistent across the app.
///
/// Performance notes:
/// - Uses Canvas + TimelineView to animate a few low-opacity radial gradients.
/// - Only draws within its own bounds; keep heights modest for bars to minimize work.
/// - All overlays are non-interactive and do not block touches.
struct LiquidGlassBackground: View {
    /// Corner radius for the clipping shape. Use 0 for full-width bars.
    var cornerRadius: CGFloat = 0
    /// Primary tint to infuse into the liquid highlights.
    var tint: Color = .accentColor
    /// Material used for the blur layer.
    var material: Material = .ultraThinMaterial
    /// Which edge should receive a stronger highlight. For headers use `.bottom`, for bottom bars use `.top`.
    var highlightEdge: Edge = .top
    /// Controls overall intensity of glow overlays.
    var intensity: CGFloat = 0.8

    var body: some View {
        ZStack {
            // Base frosted blur
            Rectangle()
                .fill(material)

            // Animated soft glow "liquid" blobs
            LiquidBlobs(tint: tint, intensity: intensity)
                .blendMode(.plusLighter)
                .allowsHitTesting(false)

            // Specular highlight that gives the glass edge a crisp sheen
            EdgeHighlight(edge: highlightEdge)
                .allowsHitTesting(false)

            // Subtle inner stroke for definition on light/dark backgrounds
            Rectangle()
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.75)
                .blendMode(.overlay)
                .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .compositingGroup() // Ensures blend modes behave correctly within the clipped shape
        .accessibilityHidden(true)
    }
}

/// Animated glowing circles that drift slowly to give a "liquid" impression under the blur.
private struct LiquidBlobs: View {
    var tint: Color
    var intensity: CGFloat
    @State private var time: TimeInterval = Date().timeIntervalSinceReferenceDate

    var body: some View {
        Canvas { context, size in
            // Time seed (driven by a timer publisher below)
            let t = time

            // Helper to generate a smooth looping value [0, 1]
            func loop(_ speed: Double, _ offset: Double = 0) -> CGFloat {
                let v = sin((t * speed) + offset) * 0.5 + 0.5
                return CGFloat(v)
            }

            // Define a few blobs with different paths
            let blobs: [(CGPoint, CGFloat, Color)] = [
                // Center-left
                (CGPoint(x: size.width * (0.25 + 0.10 * loop(0.6)),
                         y: size.height * (0.40 + 0.10 * loop(0.8, .pi/3))),
                 max(size.width, size.height) * 0.7,
                 tint.opacity(0.20 * intensity)),
                // Center-right
                (CGPoint(x: size.width * (0.72 + 0.12 * loop(0.5, .pi/2)),
                         y: size.height * (0.55 + 0.10 * loop(0.7, .pi/5))),
                 max(size.width, size.height) * 0.65,
                 Color.purple.opacity(0.18 * intensity)),
                // Top subtle cool tint
                (CGPoint(x: size.width * (0.55 + 0.15 * loop(0.7, .pi)),
                         y: size.height * (0.10 + 0.08 * loop(0.9, .pi/7))),
                 max(size.width, size.height) * 0.55,
                 Color.cyan.opacity(0.12 * intensity))
            ]

            for (center, radius, color) in blobs {
                let gradient = Gradient(colors: [color, color.opacity(0.0)])
                let shader = GraphicsContext.Shading.radialGradient(
                    gradient,
                    center: center,
                    startRadius: 0,
                    endRadius: radius
                )
                context.fill(Path(ellipseIn: CGRect(x: center.x - radius,
                                                    y: center.y - radius,
                                                    width: radius * 2,
                                                    height: radius * 2)), with: shader)
            }

            // Very subtle noise dither to avoid banding on some displays
            let noiseOpacity = 0.04 * intensity
            if noiseOpacity > 0.0 {
                let noiseShading: GraphicsContext.Shading = .color(.white.opacity(noiseOpacity))
                let step = CGFloat(30)
                var x: CGFloat = 0
                while x < size.width {
                    var y: CGFloat = 0
                    while y < size.height {
                        let dotRect = CGRect(x: x, y: y, width: 1, height: 1)
                        context.fill(Path(ellipseIn: dotRect), with: noiseShading)
                        y += step
                    }
                    x += step
                }
            }
        }
        .onReceive(Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()) { date in
            // Update time at ~30 FPS to keep the blobs moving smoothly.
            time = date.timeIntervalSinceReferenceDate
        }
    }
}

/// A directional highlight to emphasize either the top or bottom edge of the bar.
private struct EdgeHighlight: View {
    var edge: Edge

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let highlightGradient = gradient(for: edge)
            Rectangle()
                .fill(highlightGradient)
                .frame(width: size.width, height: size.height)
        }
        .allowsHitTesting(false)
    }

    private func gradient(for edge: Edge) -> LinearGradient {
        switch edge {
        case .top:
            return LinearGradient(
                colors: [Color.white.opacity(0.40), Color.white.opacity(0.15), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        case .bottom:
            return LinearGradient(
                colors: [.clear, Color.white.opacity(0.15), Color.white.opacity(0.40)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .leading:
            return LinearGradient(
                colors: [Color.white.opacity(0.40), Color.white.opacity(0.10), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .trailing:
            return LinearGradient(
                colors: [.clear, Color.white.opacity(0.10), Color.white.opacity(0.40)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}


