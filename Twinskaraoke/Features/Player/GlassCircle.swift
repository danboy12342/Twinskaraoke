import SwiftUI

struct GlassCircle: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        if reduceTransparency {
            content
                .background(Circle().fill(Color.appSecondaryBackground))
                .overlay(Circle().stroke(Color.appDivider, lineWidth: contrast == .increased ? 1 : 0.5))
                .clipShape(Circle())
                .contentShape(Circle())
        } else if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular.interactive(), in: Circle())
                .overlay {
                    if contrast == .increased {
                        Circle().stroke(Color.appDivider, lineWidth: 1)
                    }
                }
                .contentShape(Circle())
        } else {
            content
                .background(
                    Circle()
                        .fill(Color.appGlassFill)
                )
                .overlay(
                    Circle()
                        .stroke(Color.appDivider.opacity(contrast == .increased ? 1 : 0.7), lineWidth: contrast == .increased ? 1 : 0.5)
                )
                .clipShape(Circle())
                .contentShape(Circle())
        }
    }
}

struct GlassRoundedRect: ViewModifier {
    let cornerRadius: CGFloat
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if reduceTransparency {
            content
                .background(shape.fill(Color.appSecondaryBackground))
                .overlay {
                    if contrast == .increased {
                        shape.stroke(Color.appDivider, lineWidth: 1)
                    }
                }
                .shadow(color: .appShadow, radius: 14, y: 6)
        } else if #available(iOS 26.0, *) {
            content
                .glassEffect(in: shape)
                .shadow(color: .appShadow, radius: 14, y: 6)
        } else {
            content
                .background(
                    shape.fill(Color.appGlassFill)
                )
                .shadow(color: .appShadow, radius: 14, y: 6)
        }
    }
}
