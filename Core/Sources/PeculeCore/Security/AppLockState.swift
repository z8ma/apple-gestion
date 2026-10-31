import Foundation

/// Machine à états du verrouillage biométrique.
///
/// - Passer en arrière-plan verrouille (si le verrouillage est activé).
/// - Dès que l'app n'est plus active, son contenu est masqué : le sélecteur d'apps
///   n'en montre jamais l'aperçu.
/// - La feuille Face ID rend l'app *inactive* sans la mettre en arrière-plan :
///   cela masque l'écran mais ne reverrouille pas.
public struct AppLockState: Equatable, Sendable {
    public enum Phase: Sendable { case active, inactive, background }

    public enum Event: Sendable {
        case enabledChanged(Bool)
        case phaseChanged(Phase)
        case authenticationSucceeded
        case authenticationFailed
    }

    public private(set) var isEnabled: Bool
    public private(set) var isLocked: Bool
    /// Contenu masqué (sélecteur d'apps, centre de contrôle…).
    public private(set) var isObscured = false

    /// Au lancement, l'app est verrouillée si l'option est active.
    public init(isEnabled: Bool) {
        self.isEnabled = isEnabled
        self.isLocked = isEnabled
    }

    /// Une demande d'authentification automatique est-elle pertinente ?
    public var shouldPromptAutomatically: Bool { isLocked && !isObscured }

    public mutating func handle(_ event: Event) {
        switch event {
        case .enabledChanged(let enabled):
            isEnabled = enabled
            // Activer depuis les réglages suppose une authentification déjà réussie.
            if !enabled { isLocked = false; isObscured = false }
        case .phaseChanged(let phase):
            guard isEnabled else { isObscured = false; return }
            switch phase {
            case .background:
                isLocked = true
                isObscured = true
            case .inactive:
                isObscured = true
            case .active:
                isObscured = false
            }
        case .authenticationSucceeded:
            isLocked = false
        case .authenticationFailed:
            break
        }
    }
}
