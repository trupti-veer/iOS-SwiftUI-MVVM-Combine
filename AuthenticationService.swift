//
//  AuthenticationService.swift
//  
//
//  Created by Trupti Veer on 24/03/21.
//  Copyright © 2021. All rights reserved.
//

import Foundation
import Combine

protocol AuthenticationServiceInterface {
    var loggedInUser: AnyPublisher<Result<User, NetworkError>, Never> { get }
    var passwordResetRequested: AnyPublisher<Result<Void, NetworkError>, Never> { get }
    func registerUser(with input: CreateAccountInput)
    func logInWith(email: String, password: String)
    func requestResetPassword(email: String)
    func requestBiometricAuthentication()
}

// MARK: - Class
class AuthenticationService: ObservableObject {
    private var loggedInSubject = PassthroughSubject<Result<User, NetworkError>, Never>()
    private var passwordResetSubject = PassthroughSubject<Result<Void, NetworkError>, Never>()
    private var cancellableSet: Set<AnyCancellable> = []
    private let authNetwork: AuthenticationNetworkInterface
    private let biometricAuthWrapper: BiometricAuthWrapperInterface
    let userSession: UserSession
    
    init(
        authNetwork: AuthenticationNetworkInterface,
        biometricAuthWrapper: BiometricAuthWrapperInterface,
        userSession: UserSession
    ) {
        self.authNetwork = authNetwork
        self.biometricAuthWrapper = biometricAuthWrapper
        self.userSession = userSession
    }
}

// MARK: - Interface Impl
extension AuthenticationService: AuthenticationServiceInterface {
    var loggedInUser: AnyPublisher<Result<User, NetworkError>, Never> {
        loggedInSubject.eraseToAnyPublisher()
    }
    var passwordResetRequested: AnyPublisher<Result<Void, NetworkError>, Never> {
        passwordResetSubject.eraseToAnyPublisher()
    }
    
    func registerUser(with input: CreateAccountInput) {
        authNetwork.registerUser(with: input).flatMap { user in
            self.combinedLoginSteps(email: input.email, password: input.password)
        }
        .sink { [weak self] in
            if case .failure(let error) = $0 {
                self?.loggedInSubject.send(.failure(error))
            }
        } receiveValue: { [weak self] user in
            self?.userSession.user = user
            self?.loggedInSubject.send(.success(user))
        }
        .store(in: &cancellableSet)
    }
    
    func logInWith(email: String, password: String) {
        combinedLoginSteps(email: email, password: password).sink { [weak self] in
            if case .failure(let error) = $0 {
                self?.loggedInSubject.send(.failure(error))
            }
        } receiveValue: { [weak self] user in
            self?.userSession.user = user
            self?.loggedInSubject.send(.success(user))
        }
        .store(in: &cancellableSet)
    }

    func requestResetPassword(email: String) {
        authNetwork.requestPasswordReset(for: email)
            .sink { [weak self] in
                guard case .failure(let error) = $0 else { return }
                // This error should be handled exactly like a successful value received case — so treat as success.
                if case .recoveryForbidden = error {
                    self?.passwordResetSubject.send(.success(()))
                } else {
                    self?.passwordResetSubject.send(.failure(.authError(error)))
                }
            } receiveValue: { [weak self] in
                if case .recoveryChallenge = $0 {
                    self?.passwordResetSubject.send(.success(()))
                } else {
                    // It shouldn't be possible to get a different status here, but we handle the edge case anyway.
                    self?.passwordResetSubject.send(.failure(.authenticationFailed))
                }
            }
            .store(in: &cancellableSet)
    }
    
    func requestBiometricAuthentication() {
        guard let email = userSession.secureData.retrieve(withKey: UserSession.Keys.email) else {
            return loggedInSubject.send(.failure(.unknown))
        }
        
        biometricAuthWrapper.requestBiometricAuthentication { [weak self] result in
            switch result {
            case .success:
                self?.handleSuccessfulBiometricAuthentication(for: email)
            case .failure(let error):
                self?.loggedInSubject.send(.failure(.biometricAuthError(error)))
            }
        }
    }
}

// MARK: - Private Extension
private extension AuthenticationService {
    func combinedLoginSteps(email: String, password: String) -> AnyPublisher<User, NetworkError> {
        authNetwork.logInStep1(email: email, password: password).flatMap {
            self.authNetwork.logInStep2($0)
        }
        .map { User($0) }
        .eraseToAnyPublisher()
    }
    
    /// Helper method meant to be called after successful biometric authentication.
    /// If biometric auth is already enabled, this method will log the user in.
    /// If it's not yet enabled, this method will enable it for future logins.
    func handleSuccessfulBiometricAuthentication(for email: String) {
        if let password = userSession.secureData.retrieve(withKey: email) {
            logInWith(email: email, password: password)
        } else {
            userSession.isBiometricAuthEnabled = true
            loggedInSubject.send(.failure(.unknown))
        }
    }    
}
