//
//  OktaAuthManager.swift
//
//
//  Created by Trupti Veer on 10/15/21.
//  Copyright © 2021. All rights reserved.
//

import Combine
import OktaAuthSdk
import OktaOidc

protocol OktaAuthWrapperInterface {
    var shouldMockAuthRequests: Bool { get }
    var baseURL: URL? { get }
    var stateManager: OktaOidcStateManager? { get set }
    var oidcClient: OktaOidc? { get }
    var accessToken: String? { get set }
    var secureDataStore: SecureDataStore { get }
    func renewToken(completion: @escaping (Result<String, NetworkError>) -> Void)
    func authenticate(_ input: User.LoginStep1Response) -> AnyPublisher<User.AuthProfile, AuthError>
    func recoverPassword(for email: String) -> AnyPublisher<AuthStatus, AuthError>
}

extension OktaAuthWrapperInterface where Self: AnyObject {
    var accessToken: String? {
        get { secureDataStore.retrieve(withKey: OktaConstants.Keys.accessToken) }
        set { secureDataStore.save(newValue, forKey: OktaConstants.Keys.accessToken) }
    }
    
    func renewToken(completion: @escaping (Result<String, NetworkError>) -> Void) {
        guard !shouldMockAuthRequests else {
            return completion(.success(OktaConstants.mockAccessToken))
        }
        stateManager?.renew { [weak self] stateManager, _ in
            guard let self = self,
                  let token = stateManager?.accessToken else {
                return completion(.failure(.authenticationFailed))
            }
            self.accessToken = token
            completion(.success(token))
        }
    }
    
    func authenticate(_ input: User.LoginStep1Response) -> AnyPublisher<User.AuthProfile, AuthError> {
        guard !shouldMockAuthRequests else {
            accessToken = OktaConstants.mockAccessToken
            return Just(input.profile)
                .setFailureType(to: AuthError.self)
                .eraseToAnyPublisher()
        }
        guard let oidcClient = oidcClient else {
            return Fail(error: .authenticationFailed).eraseToAnyPublisher()
        }
        return Future { promise in
            oidcClient.authenticate(withSessionToken: input.sessionToken) { [weak self] stateManager, _ in
                guard let accessToken = stateManager?.accessToken else {
                    return promise(.failure(.authenticationFailed))
                }
                self?.stateManager = stateManager
                self?.accessToken = accessToken
                promise(.success(input.profile))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func recoverPassword(for email: String) -> AnyPublisher<AuthStatus, AuthError> {
        guard !shouldMockAuthRequests else {
            return Just(.recoveryChallenge).setFailureType(to: AuthError.self).eraseToAnyPublisher()
        }
        guard let baseURL = baseURL else {
            return Fail(error: .authenticationFailed).eraseToAnyPublisher()
        }
        return Future { promise in
            OktaAuthSdk.recoverPassword(with: baseURL, username: email, factorType: .email) {
                promise(.success(AuthStatus($0)))
            } onError: {
                promise(.failure(AuthError($0)))
            }
        }
        .eraseToAnyPublisher()
    }
}

class OktaAuthManager: OktaAuthWrapperInterface {
    /// Determines whether Okta SDK network requests should be triggered normally *or* intercepted and replaced
    /// with mock data responses.
    var shouldMockAuthRequests: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    var baseURL: URL? {
        guard let urlString = secrets.secretStringValue(key: .baseOktaURL) else {
            return nil
        }
        return URL(string: urlString)
    }
    var stateManager: OktaOidcStateManager? {
        get {
            guard let config = config,
                  let stateManager = OktaOidcStateManager.readFromSecureStorage(for: config) else {
                return nil
            }
            return stateManager
        }
        set {
            newValue?.writeToSecureStorage()
        }
    }
    var oidcClient: OktaOidc? {
        try? .init(configuration: config)
    }
    private(set) lazy var config: OktaOidcConfig? = {
        guard let issuer = secrets.secretStringValue(key: .oktaIssuerURL),
              let clientID = secrets.secretStringValue(key: .oktaClientID),
              let redirectURI = secrets.secretStringValue(key: .oktaRedirectURI),
              let logoutRedirectURI = secrets.secretStringValue(key: .oktaLogoutRedirectURI) else {
            return try? .default()
        }
        return try? .init(
            with: [
                OktaConstants.Keys.issuer: issuer,
                OktaConstants.Keys.clientID: clientID,
                OktaConstants.Keys.redirectURI: redirectURI,
                OktaConstants.Keys.logoutRedirectURI: logoutRedirectURI,
                OktaConstants.Keys.scopes: OktaConstants.scopes,
            ]
        )
    }()
    let secureDataStore: SecureDataStore
    private let secrets = Secrets.shared
    
    init(secureDataStore: SecureDataStore = Keychain()) {
        self.secureDataStore = secureDataStore
    }
}

// MARK: - Constants
private enum OktaConstants {
    static let scopes = "openid profile offline_access"
    static let mockAccessToken = "Mock-Access-Token"
    
    enum Keys {
        static let accessToken = "AccessToken"
        static let clientID = "clientId"
        static let issuer = "issuer"
        static let logoutRedirectURI = "logoutRedirectUri"
        static let redirectURI = "redirectUri"
        static let scopes = "scopes"
    }
}
