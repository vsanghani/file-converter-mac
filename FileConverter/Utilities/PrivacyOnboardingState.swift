import Foundation

/// Persists whether the user has seen the one-time privacy introduction.
enum PrivacyOnboardingState {
    private static let key = "hasSeenPrivacyOnboarding"

    static var hasSeen: Bool {
        get { UserDefaults.standard.bool(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}
