import Foundation
import PeculeCore
import SwiftData

/// Connexion DSP2 à une banque via l'agrégateur (M3).
@Model
final class BankConnection {
    var id: UUID = UUID()
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    var provider: String = ""
    var providerConnectionID: String = ""
    var institutionName: String = ""
    var consentExpiresAt: Date = Date.now
    var statusRaw: String = ConnectionStatus.active.rawValue
    var lastSyncAt: Date?
    var lastError: String?

    @Relationship(deleteRule: .nullify, inverse: \Account.connection)
    var accounts: [Account]? = []

    init(provider: String, providerConnectionID: String, institutionName: String, consentExpiresAt: Date) {
        self.provider = provider
        self.providerConnectionID = providerConnectionID
        self.institutionName = institutionName
        self.consentExpiresAt = consentExpiresAt
    }

    var status: ConnectionStatus {
        get { .decoded(statusRaw, default: .active) }
        set { statusRaw = newValue.rawValue }
    }
}
