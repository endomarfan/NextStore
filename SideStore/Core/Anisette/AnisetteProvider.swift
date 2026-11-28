//
//  AnisetteProvider.swift
//  SideStore
//
//  Created by Magesh K on 8/9/26.
//  Copyright © 2026 SideStore. All rights reserved.
//

import Foundation
import SideSign
import NextStoreKit

enum AnisetteProvider {
    static func fetch(handler: AnisetteServerHandler? = nil) async throws -> ALTAnisetteData {
        if UserDefaults.standard.useOnDeviceAnisette {
            debugLog("[AnisetteProvider] Fetching anisette via On-Device Anisette (ODA)...")
            return try await OnDeviceAnisetteManager.shared.fetchAnisetteData()
        } else {
            debugLog("[AnisetteProvider] Fetching anisette via remote server...")
            return try await fetchRemote(handler: handler)
        }
    }

    private static func fetchRemote(handler: AnisetteServerHandler? = nil) async throws -> ALTAnisetteData {
        let activeServerURLs = await AnisetteServersManager.shared.getActiveServerURLs()
        let lastServer = UserDefaults.standard.menuAnisetteURL
        let serverUrlStrings = UserDefaults.standard.disableAnisetteRotation
            ? [lastServer]
            : AnisettePolicy.failoverOrder(selected: lastServer, available: activeServerURLs)
        let servers = serverUrlStrings.compactMap { URL(string: $0) }
        guard !servers.isEmpty else {
            throw AnisetteError.noServersConfigured
        }

        let startIndex = servers.firstIndex(where: { $0.absoluteString == lastServer }) ?? 0

        let provider = SideSign.AnisetteDataManager.shared
        await AnisetteConfigManager.shared.discardAdiBlobIfClientInfoChanged()
        let existingBlob = AnisetteConfigManager.shared.anisetteAdiBlob.flatMap { Data(base64Encoded: $0) }
        let identifier = await AnisetteConfigManager.shared.resolveDeviceIdentifier()
        let headers = await AnisetteConfigManager.shared.makeRequestHeaders()

        let (anisetteData, newAdiBlob) = try await provider.fetchAnisetteDataWithFailover(
            servers: UserDefaults.standard.disableAnisetteRotation ? [servers[startIndex]] : servers,
            startIndex: startIndex,
            identifier: identifier,
            existingAdiBlob: existingBlob,
            headers: headers,
            onError: { error in
                if let anisetteError = error as? SideSign.AnisetteError,
                   case .outdatedV1Server(let serverURL, _) = anisetteError {
                    if UserDefaults.standard.defaultServerURL == serverURL.absoluteString {
                        return true
                    }
                    if let handler = handler {
                        let shouldContinue = try await handler.warnOutdatedAnisetteServer()
                        if shouldContinue {
                            UserDefaults.standard.defaultServerURL = serverURL.absoluteString
                        }
                        return shouldContinue
                    }
                }
                return false
            },
            onSuccess: { successfulServer in
                UserDefaults.standard.menuAnisetteURL = successfulServer.absoluteString
                debugLog("[AnisetteProvider] Successfully fetched Anisette data from \(successfulServer.absoluteString)")
            }
        )

        if let freshBlob = newAdiBlob {
            AnisetteConfigManager.shared.anisetteAdiBlob = freshBlob.base64EncodedString()
            await AnisetteConfigManager.shared.recordProvisionedClientInfo()
        }

        return anisetteData
    }
}
