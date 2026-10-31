import Observation
import PeculeCore
import SwiftUI

/// Pilote le verrouillage biométrique de l'app (état pur : `AppLockState`).
@Observable
final class AppLockController {
    private(set) var state: AppLockState
    private(set) var isAuthenticating = false
    let authenticator: any DeviceAuthenticator

    init(isEnabled: Bool, authenticator: any DeviceAuthenticator = LocalDeviceAuthenticator()) {
        self.state = AppLockState(isEnabled: isEnabled)
        self.authenticator = authenticator
    }

    var availableMethod: AuthenticationMethod { authenticator.availableMethod() }

    func handle(_ event: AppLockState.Event) {
        state.handle(event)
    }

    func scenePhaseChanged(_ phase: ScenePhase) {
        switch phase {
        case .active: state.handle(.phaseChanged(.active))
        case .inactive: state.handle(.phaseChanged(.inactive))
        case .background: state.handle(.phaseChanged(.background))
        @unknown default: break
        }
    }

    /// Demande l'authentification si l'app est verrouillée (une seule demande à la fois).
    func unlock() async {
        guard state.isLocked, !isAuthenticating else { return }
        isAuthenticating = true
        defer { isAuthenticating = false }
        let success = await authenticator.authenticate(reason: String(localized: "Déverrouillez Pécule pour accéder à vos finances."))
        state.handle(success ? .authenticationSucceeded : .authenticationFailed)
    }

    /// Vérifie l'identité avant d'activer l'option (évite de s'enfermer dehors).
    func confirmIdentity() async -> Bool {
        guard availableMethod != .unavailable else { return false }
        return await authenticator.authenticate(reason: String(localized: "Confirmez pour activer le verrouillage de Pécule."))
    }
}
