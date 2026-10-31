import LocalAuthentication

/// Méthode d'authentification disponible sur l'appareil.
enum AuthenticationMethod: Equatable {
    case faceID, touchID, opticID, passcode, unavailable

    var label: LocalizedStringResource {
        switch self {
        case .faceID: "Face ID"
        case .touchID: "Touch ID"
        case .opticID: "Optic ID"
        case .passcode: "Code de l'appareil"
        case .unavailable: "Indisponible"
        }
    }

    var symbol: String {
        switch self {
        case .faceID: "faceid"
        case .touchID: "touchid"
        case .opticID: "opticid"
        case .passcode, .unavailable: "lock.fill"
        }
    }
}

/// Service d'authentification (protocole : remplaçable par un faux en preview et en test).
protocol DeviceAuthenticator {
    func availableMethod() -> AuthenticationMethod
    func authenticate(reason: String) async -> Bool
}

/// Face ID / Touch ID, avec repli sur le code de l'appareil.
struct LocalDeviceAuthenticator: DeviceAuthenticator {
    func availableMethod() -> AuthenticationMethod {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else { return .unavailable }
        switch context.biometryType {
        case .faceID: return .faceID
        case .touchID: return .touchID
        case .opticID: return .opticID
        default: return .passcode
        }
    }

    func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        return await withCheckedContinuation { continuation in
            // Rappel exécuté hors du MainActor : la closure doit être @Sendable.
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { @Sendable success, _ in
                continuation.resume(returning: success)
            }
        }
    }
}

/// Authentificateur factice pour les previews et les tests.
struct FakeDeviceAuthenticator: DeviceAuthenticator {
    var method: AuthenticationMethod = .faceID
    var succeeds = true

    func availableMethod() -> AuthenticationMethod { method }
    func authenticate(reason: String) async -> Bool { succeeds }
}
