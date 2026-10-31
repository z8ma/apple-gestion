import Foundation
import PeculeCore

// Libellés affichés des énumérations du domaine (String Catalog, français d'abord).

extension AccountType {
    var label: LocalizedStringResource {
        switch self {
        case .checking: "Compte courant"
        case .savings: "Épargne"
        case .card: "Carte"
        case .investment: "Investissement"
        case .lifeInsurance: "Assurance vie"
        case .crypto: "Crypto"
        case .loan: "Prêt"
        case .realEstate: "Immobilier"
        case .otherAsset: "Autre actif"
        }
    }

    var symbol: String {
        switch self {
        case .checking: "building.columns.fill"
        case .savings: "archivebox.fill"
        case .card: "creditcard.fill"
        case .investment: "chart.line.uptrend.xyaxis"
        case .lifeInsurance: "umbrella.fill"
        case .crypto: "bitcoinsign.circle.fill"
        case .loan: "percent"
        case .realEstate: "house.fill"
        case .otherAsset: "shippingbox.fill"
        }
    }
}

extension TransactionKind {
    var label: LocalizedStringResource {
        switch self {
        case .expense: "Dépense"
        case .income: "Revenu"
        case .transfer: "Virement"
        case .refund: "Remboursement"
        }
    }
}

extension TransactionSource {
    var label: LocalizedStringResource {
        switch self {
        case .manual: "Saisie manuelle"
        case .applePay: "Apple Pay"
        case .bank: "Banque"
        case .import: "Import"
        }
    }
}

extension CategoryKind {
    var label: LocalizedStringResource {
        switch self {
        case .expense: "Dépenses"
        case .income: "Revenus"
        case .transfer: "Virements"
        case .saving: "Épargne"
        }
    }
}
