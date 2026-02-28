import SwiftUI

// MARK: - Glassmorphism Components

/// Reusable glass card background
struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 20
    var opacity: Double = 0.12
    var borderOpacity: Double = 0.18

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.white.opacity(opacity))
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(borderOpacity),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 20, opacity: Double = 0.12) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius, opacity: opacity))
    }
}

// MARK: - Animated Mesh Background

struct AnimatedMeshBackground: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            // Base dark gradient
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.06, blue: 0.14),
                    Color(red: 0.08, green: 0.04, blue: 0.18),
                    Color(red: 0.04, green: 0.08, blue: 0.16),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Floating orbs
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.blue.opacity(0.4), Color.blue.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: animate ? -60 : -120, y: animate ? -100 : -50)
                .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: animate)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.purple.opacity(0.35), Color.purple.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 250
                    )
                )
                .frame(width: 500, height: 500)
                .offset(x: animate ? 150 : 100, y: animate ? 80 : 140)
                .animation(.easeInOut(duration: 10).repeatForever(autoreverses: true), value: animate)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.cyan.opacity(0.2), Color.cyan.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 180
                    )
                )
                .frame(width: 350, height: 350)
                .offset(x: animate ? -80 : -20, y: animate ? 200 : 160)
                .animation(.easeInOut(duration: 7).repeatForever(autoreverses: true), value: animate)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.pink.opacity(0.15), Color.pink.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .offset(x: animate ? 200 : 250, y: animate ? -180 : -120)
                .animation(.easeInOut(duration: 9).repeatForever(autoreverses: true), value: animate)
        }
        .ignoresSafeArea()
        .onAppear { animate = true }
    }
}

// MARK: - Glow Button

struct GlowButton: View {
    let title: String
    let icon: String
    let colors: [Color]
    let action: () -> Void
    let isDisabled: Bool

    @State private var isHovered = false

    init(title: String, icon: String, colors: [Color] = [.blue, .purple],
         isDisabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.colors = colors
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: isDisabled
                                    ? [.gray.opacity(0.3), .gray.opacity(0.2)]
                                    : colors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    if isHovered && !isDisabled {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.15))
                    }
                }
            )
            .foregroundColor(.white)
            .shadow(
                color: isDisabled ? .clear : colors.first!.opacity(isHovered ? 0.5 : 0.3),
                radius: isHovered ? 16 : 10,
                y: 4
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .onHover { hovering in
            withAnimation(.spring(response: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Glassmorphic Format Tag

struct GlassFormatTag: View {
    let text: String
    let color: Color
    let isLarge: Bool

    init(_ text: String, color: Color = .blue, isLarge: Bool = false) {
        self.text = text
        self.color = color
        self.isLarge = isLarge
    }

    var body: some View {
        Text(text)
            .font(.system(size: isLarge ? 11 : 9, weight: .bold, design: .monospaced))
            .padding(.horizontal, isLarge ? 10 : 6)
            .padding(.vertical, isLarge ? 5 : 3)
            .background(
                Capsule()
                    .fill(color.opacity(0.2))
                    .overlay(
                        Capsule()
                            .strokeBorder(color.opacity(0.3), lineWidth: 0.5)
                    )
            )
            .foregroundColor(color)
    }
}
