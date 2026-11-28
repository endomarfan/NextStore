public enum PairingSelection {
    public enum Kind: String, Sendable {
        case lockdown
        case rppairing
    }

    public static func recommended(supportsRemotePairing: Bool) -> Kind {
        supportsRemotePairing ? .rppairing : .lockdown
    }

    public static func needsConfirmationWarning(for kind: Kind, supportsRemotePairing: Bool) -> Bool {
        kind != recommended(supportsRemotePairing: supportsRemotePairing)
    }

    public static func choose(
        preferred: Kind?,
        available: Set<Kind>,
        supportsRemotePairing: Bool
    ) -> Kind? {
        if let preferred, available.contains(preferred) {
            return preferred
        }
        let recommended = recommended(supportsRemotePairing: supportsRemotePairing)
        if available.contains(recommended) {
            return recommended
        }
        if recommended == .rppairing, available.contains(.lockdown) {
            return .lockdown
        }
        return nil
    }
}
