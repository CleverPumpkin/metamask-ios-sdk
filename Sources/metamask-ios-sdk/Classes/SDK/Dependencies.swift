//
//  Dependencies.swift
//  metamask-ios-sdk
//

import Foundation

public final class Dependencies {
    public static let shared = Dependencies()

    public lazy var network: any Networking = Network()
    public lazy var tracker: Tracking = Analytics(network: network, debug: true)
    public lazy var store: SecureStore = Keychain(service: SDKInfo.bundleIdentifier ?? UUID().uuidString)
    public lazy var sessionManager: SessionManager = SessionManager(store: store, sessionDuration: 24 * 3600 * 30)
    
    public lazy var commClientFactory: CommClientFactory = CommClientFactory()

    public func ethereum(transport: Transport, sdkOptions: SDKOptions?) -> Ethereum {
        Ethereum.shared(
            transport: transport,
            store: store,
            commClientFactory: commClientFactory,
            readOnlyRPCProvider: ReadOnlyRPCProvider(infuraAPIKey: sdkOptions?.infuraAPIKey, readonlyRPCMap: sdkOptions?.readonlyRPCMap)
        ) { event, parameters in
            self.trackEvent(event, parameters: parameters)
        }.updateTransportLayer(transport)
    }

    public lazy var keyExchange: KeyExchange = KeyExchange(storage: store)

    public lazy var deeplinkManager: DeeplinkManager = DeeplinkManager()

    public lazy var socketClient: CommClient = SocketClient(
        session: sessionManager,
        channel: SocketChannel(),
        keyExchange: keyExchange,
        urlOpener: DefaultURLOpener(),
        trackEvent: { event, parameters in
            self.trackEvent(event, parameters: parameters)
        }
    )

    public func deeplinkClient(dappScheme: String) -> DeeplinkClient {
        DeeplinkClient(
            session: sessionManager,
            keyExchange: keyExchange,
            deeplinkManager: deeplinkManager,
            dappScheme: dappScheme)
    }

    public func trackEvent(_ event: Event, parameters: [String: Any] = [:]) {
        Task {
            await self.tracker.trackEvent(event, parameters: parameters)
        }
    }
}
