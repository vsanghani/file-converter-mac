import SwiftUI

/// One-time first-launch panel: local-only processing, no accounts or analytics by default.
struct PrivacyOnboardingView: View {
    @Binding var isPresented: Bool
    var onOpenHowConversionsWork: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.green.opacity(0.35), Color.cyan.opacity(0.25)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(.white)
                }

                Text("Your files stay on this Mac")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)

                Text("File Converter processes documents and media entirely on your device. Nothing is uploaded to the cloud.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 420)

                VStack(alignment: .leading, spacing: 12) {
                    onboardingRow(icon: "person.crop.circle.badge.xmark", text: "No account or sign-in required")
                    onboardingRow(icon: "icloud.slash", text: "No uploads — files never leave your Mac")
                    onboardingRow(icon: "chart.bar.xaxis", text: "No analytics or tracking by default")
                }
                .padding(.vertical, 4)
            }
            .padding(32)

            Divider()
                .background(Color.white.opacity(0.12))

            VStack(spacing: 12) {
                Button(action: {
                    isPresented = false
                }) {
                    Text("Continue")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.3, green: 0.5, blue: 1.0),
                                    Color(red: 0.5, green: 0.35, blue: 0.95)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                Button(action: onOpenHowConversionsWork) {
                    Text("How conversions work")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.cyan.opacity(0.9))
                }
                .buttonStyle(.plain)
            }
            .padding(20)
        }
        .frame(width: 480)
        .background(
            ZStack {
                Color(red: 0.09, green: 0.09, blue: 0.14)
                LinearGradient(
                    colors: [Color.white.opacity(0.06), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        )
    }

    private func onboardingRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.cyan.opacity(0.85))
                .frame(width: 24, alignment: .center)
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}
