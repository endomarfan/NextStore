public enum PairingSelection {
    public enum Kind: String, Sendable {
        case lockdown
        case rppairing
    }

    public static func choose(
        preferred: Kind?,
        active: Kind?,
        available: Set<Kind>,
        supportsRemotePairing: Bool
    ) -> Kind? {
        if let preferred, available.contains(preferred) {
            return preferred
        }
        if let active, available.contains(active) {
            return active
        }
        if supportsRemotePairing, available.contains(.rppairing) {
            return .rppairing
        }
        if available.contains(.lockdown) {
            return .lockdown
        }
        return nil
    }
}
