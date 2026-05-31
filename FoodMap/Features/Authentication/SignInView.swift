import AuthenticationServices
import SwiftUI

/// The sign-in gate shown when there is no active session.
///
/// Sign in with Apple is offered as an optional identity affordance; the user
/// can also continue without an account to use the app fully offline. No
/// identity is shared with any third party — the Apple user id is stored only
/// in the local Keychain.
struct SignInView: View {
    @ObservedObject var model: AuthViewModel

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Spacer()

            VStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(DesignSystem.Colors.accent)
                    .accessibilityHidden(true)

                Text("FoodMap")
                    .font(DesignSystem.Typography.titleL)
                    .fontWeight(.bold)

                Text("Track what's in your pantry and never waste food again.")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
            }

            Spacer()

            VStack(spacing: DesignSystem.Spacing.md) {
                SignInWithAppleButton(.signIn, onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                }, onCompletion: handleCompletion)
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .accessibilityIdentifier("auth.signInWithApple")

                Button("Continue without an account") {
                    Task { await model.continueWithoutAccount() }
                }
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.accent)
                .accessibilityIdentifier("auth.continueWithoutAccount")

                Text("Optional. Signing in lets you keep your data across devices later.")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.bottom, DesignSystem.Spacing.xl)
        }
        .alert(
            "Sign in failed",
            isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if !$0 { model.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    private func handleCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case let .success(authorization):
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential
            else {
                model.handleSignInFailure(.authenticationFailed(reason: "Unexpected credential type."))
                return
            }
            let fullName = credential.fullName
                .map { PersonNameComponentsFormatter().string(from: $0) }
                .flatMap { $0.isEmpty ? nil : $0 }
            let mapped = AppleSignInCredential(
                userID: credential.user,
                fullName: fullName,
                email: credential.email
            )
            Task { await model.completeSignIn(with: mapped) }
        case let .failure(error):
            if let authError = error as? ASAuthorizationError {
                switch authError.code {
                case .canceled:
                    model.handleSignInFailure(.authenticationCancelled)
                case .unknown, .notInteractive:
                    // Surfaced when Sign in with Apple isn't entitled/configured
                    // for this build (e.g. unsigned builds without a team).
                    model.handleSignInFailure(.authenticationUnavailable)
                default:
                    model.handleSignInFailure(.authenticationFailed(reason: error.localizedDescription))
                }
            } else {
                model.handleSignInFailure(.authenticationFailed(reason: error.localizedDescription))
            }
        }
    }
}
