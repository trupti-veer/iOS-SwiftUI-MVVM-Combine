//
//  ApolloNetworkManager.swift
//
//
//  Created by Trupti Veer on 22/02/21.
//  Copyright © 2021. All rights reserved.
//

import Foundation
import Apollo
import OktaOidc

class ApolloNetworkManager {
    private(set) lazy var apollo: ApolloClientProtocol = {
        guard let urlString = Secrets.shared.secretStringValue(key: .harborURL),
              let url = URL(string: urlString + NetworkPath.graphQL) else {
            fatalError("unexpected url")
        }
        var client: ApolloClientProtocol
        #if DEBUG
        // Use ApolloClientProtocol-conforming class to return mock data in development.
        client = MockApolloClient()
        #else
        let store = ApolloStore(cache: InMemoryNormalizedCache())
        let provider = NetworkInterceptorProvider(store: store, oktaWrapper: oktaWrapper)
        let transport = RequestChainNetworkTransport(interceptorProvider: provider, endpointURL: url)
        client = ApolloClient(networkTransport: transport, store: store)
        #endif
        return client
    }()
    private(set) var oktaWrapper: OktaAuthWrapperInterface
    
    init(oktaWrapper: OktaAuthWrapperInterface) {
        self.oktaWrapper = oktaWrapper
    }
}

/// Every operation sent through a RequestChainNetworkTransport will be passed into an InterceptorProvider before going
/// to the network. This protocol creates an array of interceptors for use by a single request chain based on the
/// provided operation. Here we are adding a CustomInterceptor.
class NetworkInterceptorProvider: DefaultInterceptorProvider {
    private let oktaWrapper: OktaAuthWrapperInterface
    
    init(store: ApolloStore, oktaWrapper: OktaAuthWrapperInterface) {
        self.oktaWrapper = oktaWrapper
        super.init(store: store)
    }
    
    override func interceptors<Operation: GraphQLOperation>(for operation: Operation) -> [ApolloInterceptor] {
        var interceptors = super.interceptors(for: operation)
        interceptors.insert(AuthHeaderInterceptor(oktaWrapper: oktaWrapper), at: 0)
        return interceptors
    }
}

/// An interceptor which can be used to add headers to the request.
class AuthHeaderInterceptor: ApolloInterceptor {
    private enum Header {
        static let authorization = "Authorization"
        static let apiKeyName = "x-api-key"
        static let apiKeyValue = "xxx-xxxxxxxxxxxxxxxxxxxxxxx"
    }
    
    private let oktaWrapper: OktaAuthWrapperInterface
    
    init(oktaWrapper: OktaAuthWrapperInterface) {
        self.oktaWrapper = oktaWrapper
    }
    
    /**
     Called when this interceptor should do its work.
     
     - Parameters:
       - chain: The chain the interceptor is a part of.
       - request: The request, as far as it has been constructed.
       - response: [optional] The response, if received.
       - completion: The completion block to fire when data needs to be returned to the UI.
     */
    func interceptAsync<Operation: GraphQLOperation>(
        chain: RequestChain,
        request: HTTPRequest<Operation>,
        response: HTTPResponse<Operation>?,
        completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void
    ) {
        guard let stateManager = oktaWrapper.stateManager, let token = oktaWrapper.accessToken else {
            return chain.proceedAsync(request: request, response: response, completion: completion)
        }
        
        // Check if the saved token is valid.
        let error = stateManager.validateToken(idToken: token)
        if error == nil {
            request.addHeader(name: Header.authorization, value: token)
            chain.proceedAsync(request: request, response: response, completion: completion)
        } else {
            // If invalid, try to renew the token.
            oktaWrapper.renewToken { result in
                switch result {
                case .success(let token):
                    request.addHeader(name: Header.authorization, value: token)
                    chain.retry(request: request, completion: completion)
                case .failure(let error):
                    chain.handleErrorAsync(error, request: request, response: response, completion: completion)
                }
            }
        }
    }
}
