import SwiftData
import SwiftUI

/// Enveloppe le contenu : écran de verrouillage et masque du sélecteur d'apps.
struct LockContainerView<Content: View>: View {
    @Environment(AppLockController.self) private var lock
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \UserSettings.createdAt) private var settings: [UserSettings]
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            content
                .accessibilityHidden(lock.state.isLocked)
            if lock.state.isLocked {
                LockScreenView()
                    .transition(.opacity)
            } else if lock.state.isObscured {
                PrivacyCoverView()
            }
        }
        .animation(.default, value: lock.state.isLocked)
        .onChange(of: scenePhase) { _, phase in
            lock.scenePhaseChanged(phase)
            if phase == .active, lock.state.shouldPromptAutomatically {
                Task { await lock.unlock() }
            }
        }
        .onChange(of: settings.first?.lockWithBiometrics ?? false) { _, enabled in
            lock.handle(.enabledChanged(enabled))
        }
        .task {
            if lock.state.shouldPromptAutomatically { await lock.unlock() }
        }
    }
}

struct LockScreenView: View {
    @Environment(AppLockController.self) private var lock

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "lock.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text("Pécule est verrouillé")
                .font(.title2.bold())
            Spacer()
            Button {
                Task { await lock.unlock() }
            } label: {
                Label {
                    Text("Déverrouiller")
                } icon: {
                    Image(systemName: lock.availableMethod.symbol)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(lock.isAuthenticating)
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}

/// Masque affiché quand l'app n'est pas active : aucun contenu financier dans l'aperçu.
struct PrivacyCoverView: View {
    var body: some View {
        ZStack {
            Rectangle().fill(.background)
            Image(systemName: "eurosign.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

#Preview("Verrouillé") {
    LockScreenView()
        .environment(AppLockController(isEnabled: true, authenticator: FakeDeviceAuthenticator()))
}

#Preview("Masque") {
    PrivacyCoverView()
}
