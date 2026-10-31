import Testing
@testable import Pecule

@Suite("Contrôleur de verrouillage")
struct AppLockControllerTests {
    @Test("Authentification réussie : déverrouille")
    func unlocks() async {
        let lock = AppLockController(isEnabled: true, authenticator: FakeDeviceAuthenticator(succeeds: true))
        await lock.unlock()
        #expect(!lock.state.isLocked)
    }

    @Test("Authentification refusée : reste verrouillée")
    func staysLocked() async {
        let lock = AppLockController(isEnabled: true, authenticator: FakeDeviceAuthenticator(succeeds: false))
        await lock.unlock()
        #expect(lock.state.isLocked)
    }

    @Test("Activation impossible sans méthode disponible")
    func unavailable() async {
        let lock = AppLockController(isEnabled: false, authenticator: FakeDeviceAuthenticator(method: .unavailable))
        let confirmed = await lock.confirmIdentity()
        #expect(!confirmed)
    }

    @Test("Arrière-plan puis retour : verrouillée")
    func scenePhase() async {
        let lock = AppLockController(isEnabled: true, authenticator: FakeDeviceAuthenticator())
        await lock.unlock()
        lock.scenePhaseChanged(.background)
        #expect(lock.state.isLocked)
    }
}
