import SwiftUI

/// Gates the app behind the sign-in screen. Restores any persisted session on
/// launch; shows `SignInView` when there is no session, otherwise the wrapped
/// content (the main tab interface).
struct AuthGateView<Content: View>: View {
    @EnvironmentObject private var container: AppContainer
    @StateObject private var model: AuthViewModel
    private let content: () -> Content

    init(model: AuthViewModel, @ViewBuilder content: @escaping () -> Content) {
        _model = StateObject(wrappedValue: model)
        self.content = content
    }

    var body: some View {
        Group {
            if model.isRestoring {
                ProgressView()
                    .accessibilityIdentifier("auth.restoring")
            } else if model.isAuthenticated {
                content()
            } else {
                SignInView(model: model)
            }
        }
        .task { await model.restore() }
    }
}
