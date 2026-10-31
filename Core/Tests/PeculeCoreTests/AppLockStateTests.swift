import Testing
@testable import PeculeCore

@Suite("Verrouillage de l'app")
struct AppLockStateTests {
    @Test("Lancement : verrouillée seulement si l'option est active")
    func launch() {
        #expect(AppLockState(isEnabled: true).isLocked)
        #expect(!AppLockState(isEnabled: false).isLocked)
        #expect(AppLockState(isEnabled: true).shouldPromptAutomatically)
    }

    @Test("Arrière-plan : verrouille et masque ; retour actif : reste verrouillée")
    func background() {
        var state = AppLockState(isEnabled: true)
        state.handle(.authenticationSucceeded)
        #expect(!state.isLocked)
        state.handle(.phaseChanged(.inactive))
        state.handle(.phaseChanged(.background))
        #expect(state.isLocked && state.isObscured)
        state.handle(.phaseChanged(.active))
        #expect(state.isLocked && !state.isObscured)
        #expect(state.shouldPromptAutomatically)
    }

    @Test("Inactive (sélecteur d'apps, feuille Face ID) : masque sans reverrouiller")
    func inactive() {
        var state = AppLockState(isEnabled: true)
        state.handle(.authenticationSucceeded)
        state.handle(.phaseChanged(.inactive))
        #expect(state.isObscured)
        #expect(!state.isLocked)
        state.handle(.phaseChanged(.active))
        #expect(!state.isObscured && !state.isLocked)
    }

    @Test("Échec d'authentification : reste verrouillée")
    func failure() {
        var state = AppLockState(isEnabled: true)
        state.handle(.authenticationFailed)
        #expect(state.isLocked)
    }

    @Test("Option désactivée : jamais verrouillée ni masquée")
    func disabled() {
        var state = AppLockState(isEnabled: false)
        state.handle(.phaseChanged(.background))
        #expect(!state.isLocked && !state.isObscured)
        var enabled = AppLockState(isEnabled: true)
        enabled.handle(.enabledChanged(false))
        #expect(!enabled.isLocked && !enabled.isObscured)
    }

    @Test("Activation depuis les réglages : pas de verrouillage immédiat, verrouillage au prochain arrière-plan")
    func enabling() {
        var state = AppLockState(isEnabled: false)
        state.handle(.enabledChanged(true))
        #expect(!state.isLocked)
        state.handle(.phaseChanged(.background))
        #expect(state.isLocked)
    }
}
