//
//  AuthenticationNetwork.swift
//
//
//  Created by Trupti Veer on 24/03/21.
//  Copyright © 2021. All rights reserved.
//

import Combine

typealias AuthResponse = (profile: User.AuthProfile, accessToken: String)

// MARK: - Interface
protocol AuthenticationNetworkInterface {
    func registerUser(with input: CreateAccountInput) -> AnyPublisher<User.AuthProfile, NetworkError>
    func logInStep1(email: String, password: String) -> AnyPublisher<User.LoginStep1Response, NetworkError>
    func logInStep2(_ input: User.LoginStep1Response) -> AnyPublisher<User.AuthProfile, NetworkError>
    func requestPasswordReset(for email: String) -> AnyPublisher<AuthStatus, AuthError>
}

class AuthenticationNetwork {
    private let networkManager: ApolloNetworkManager
    
    init(networkManager: ApolloNetworkManager) {
        self.networkManager = networkManager
    }
}

extension AuthenticationNetwork: AuthenticationNetworkInterface {
    func registerUser(with input: CreateAccountInput) -> AnyPublisher<User.AuthProfile, NetworkError> {
        networkManager.apollo.performPublisher(
            mutation: SignUpUserMutation(
                createProfileInput: CreateProfileInput(
                    dateOfBirth: input.dateOfBirth,
                    email: input.email,
                    firstName: input.firstName,
                    groupIds: input.groupIDs,
                    lastName: input.lastName,
                    password: input.password,
                    primaryPhone: input.phoneNumber.unformattedPhoneNumber
                )
            )
        )
        .tryMap {
            guard let json = $0.data?.createProfile?.jsonObject else {
                throw NetworkError.mutationFailed
            }
            do {
                return try JSONSerialization.data(withJSONObject: json)
            } catch {
                throw NetworkError.mutationFailed
            }
        }
        .decode(type: User.AuthProfile.self, decoder: JSONDecoder())
        .mapError { _ in .mutationFailed }
        .eraseToAnyPublisher()
    }

    func logInStep1(email: String, password: String) -> AnyPublisher<User.LoginStep1Response, NetworkError> {
        networkManager.apollo.performPublisher(
            mutation: LogInUserMutation(loginInput: LoginInput(username: email, password: password, loginType: .email))
        )
        .tryMap {
            guard let json = $0.data?.loginProfile?.jsonObject else {
                throw NetworkError.mutationFailed
            }
            do {
                return try JSONSerialization.data(withJSONObject: json)
            } catch {
                throw NetworkError.mutationFailed
            }
        }
        .decode(type: User.LoginStep1Response.self, decoder: JSONDecoder())
        .mapError { _ in .authenticationFailed }
        .eraseToAnyPublisher()
    }
    
    func logInStep2(_ input: User.LoginStep1Response) -> AnyPublisher<User.AuthProfile, NetworkError> {
        networkManager.oktaWrapper.authenticate(input).mapError { .authError($0) }.eraseToAnyPublisher()
    }
    
    func requestPasswordReset(for email: String) -> AnyPublisher<AuthStatus, AuthError> {
        networkManager.oktaWrapper.recoverPassword(for: email).eraseToAnyPublisher()
    }
}
