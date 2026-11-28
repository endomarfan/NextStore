import Foundation

public enum AnisettePolicy {
    public static let defaultClientInfo = "<MacBookPro18,3> <Mac OS X;26.6;25F84> <com.apple.AuthKit/1 (com.apple.akd/1.0)>"
    public static let defaultUserAgent = "AuthKit/1 (Macintosh; OS X 26.6) (com.apple.akd/1.0)"
    public static let defaultServerURL = "https://mac-ani.jkcoxson.com"

    private static let macADIHosts = [
        "mac-ani.jkcoxson.com",
        "new.ani.sidestore.io",
        "ani.iloader.app",
        "ani3.stikstore.app",
        "ani.jkcoxson.com",
        "ani2.stikstore.app",
    ]

    public static let macADIServerURLs: [String] = macADIHosts.map { "https://\($0)" }

    private static let brokenClientInfoMarkers = ["<macOS;", "com.apple.dt.Xcode", "<Android;", "<Windows;"]

    public static func normalizedClientInfo(_ clientInfo: String) -> String {
        var result = clientInfo.replacingOccurrences(of: "<macOS;", with: "<Mac OS X;")
        result = result.replacingOccurrences(
            of: "com\\.apple\\.dt\\.Xcode/[^)]*",
            with: "com.apple.akd/1.0",
            options: .regularExpression
        )
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func isBrokenClientInfo(_ clientInfo: String) -> Bool {
        if clientInfo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return true
        }
        return brokenClientInfoMarkers.contains { clientInfo.contains($0) }
    }

    public static func isMacADIServer(_ url: String) -> Bool {
        guard let host = URL(string: url.trimmingCharacters(in: .whitespacesAndNewlines))?.host?.lowercased() else {
            return false
        }
        return macADIHosts.contains(host)
    }

    public static func failoverOrder(selected: String, available: [String]) -> [String] {
        var result: [String] = []
        var seen = Set<String>()
        func append(_ url: String) {
            if seen.insert(key(url)).inserted {
                result.append(url)
            }
        }
        append(selected)
        available.filter(isMacADIServer).forEach(append)
        macADIServerURLs.forEach(append)
        return result
    }

    public static func needsReprovisioning(provisionedClientInfo: String?, currentClientInfo: String) -> Bool {
        guard let provisionedClientInfo else { return false }
        return normalizedClientInfo(provisionedClientInfo) != normalizedClientInfo(currentClientInfo)
    }

    public struct Settings: Equatable {
        public var useOnDeviceAnisette: Bool
        public var serverURL: String
        public var clientInfo: String?
        public var userAgent: String?

        public init(useOnDeviceAnisette: Bool, serverURL: String, clientInfo: String?, userAgent: String?) {
            self.useOnDeviceAnisette = useOnDeviceAnisette
            self.serverURL = serverURL
            self.clientInfo = clientInfo
            self.userAgent = userAgent
        }
    }

    public struct Migration: Equatable {
        public var settings: Settings
        public var resetAdiBlob: Bool
        public var changes: [String]

        public init(settings: Settings, resetAdiBlob: Bool, changes: [String]) {
            self.settings = settings
            self.resetAdiBlob = resetAdiBlob
            self.changes = changes
        }
    }

    public static func migrate(_ settings: Settings) -> Migration {
        var result = settings
        var reset = false
        var changes: [String] = []

        if result.useOnDeviceAnisette {
            result.useOnDeviceAnisette = false
            reset = true
            changes.append("on-device anisette off")
        }
        if !isMacADIServer(result.serverURL) {
            result.serverURL = defaultServerURL
            reset = true
            changes.append("server → \(defaultServerURL)")
        }
        if let clientInfo = result.clientInfo, !clientInfo.isEmpty {
            if isBrokenClientInfo(clientInfo) {
                result.clientInfo = defaultClientInfo
                result.userAgent = defaultUserAgent
                reset = true
                changes.append("client info → Mac OS X 26.6")
            }
        } else {
            reset = true
            changes.append("default client info updated")
        }
        return Migration(settings: result, resetAdiBlob: reset, changes: changes)
    }

    private static func key(_ url: String) -> String {
        var trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        while trimmed.hasSuffix("/") {
            trimmed.removeLast()
        }
        return trimmed
    }
}

public enum SignInFailure: Equatable {
    case deviceIdentityRejected
    case anisetteServerRefused
    case serviceRefused

    public static func classify(errorCode: Int?, rawPayload: String?) -> SignInFailure? {
        switch errorCode {
        case -22410: return .deviceIdentityRejected
        case -80046: return .anisetteServerRefused
        default: break
        }
        if let rawPayload, rawPayload.contains("503") || rawPayload.localizedCaseInsensitiveContains("Service Unavailable") {
            return .serviceRefused
        }
        return nil
    }

    public var message: String {
        switch self {
        case .deviceIdentityRejected:
            return "Apple rejected this device identity. NextStore registered a new one — please sign in again; Apple may ask for a verification code."
        case .anisetteServerRefused:
            return "Apple refused the sign-in for this anisette server. Use a Mac anisette server (Settings → Anisette Servers) and keep On-Device Anisette off."
        case .serviceRefused:
            return "Apple's sign-in service refused this client (HTTP 503). Check that Client Info says “Mac OS X”, not “macOS”."
        }
    }
}
