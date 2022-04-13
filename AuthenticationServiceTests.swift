//
//  AuthenticationServiceTests.swift
//
//
//  Created by Trupti Veer on 7/27/21.
//  Copyright © 2021. All rights reserved.
//

import XCTest
@testable import XYZ

class AuthenticationServiceTests: XCTestCase {
    var network: MockAuthenticationNetwork!
    var userSession: UserSession!
    var subjectUnderTest: AuthenticationService!
    let fakeEmail = "test@test.com"
    let fakePassword = "Secret123!"

    override func setUpWithError() throws {
        network = MockAuthenticationNetwork()
        userSession = MockFactory.mockUserSession()
        subjectUnderTest = .init(
            authNetwork: network,
            biometricAuthWrapper: MockBiometricAuthWrapper(),
            userSession: userSession
        )
        
        try! super.setUpWithError()
    }
    
    func testLogInUser() throws {
        let expectedValues = [true, false, false, true]
        var receivedValues: [Bool?] = []
        
        let disposable = subjectUnderTest.loggedInUser.sink {
            switch $0 {
            case .success:
                receivedValues.append(true)
            case .failure:
                receivedValues.append(false)
            }
            self.hasLatestValueEmitted = true
        }
        
        hasLatestValueEmitted = false
        subjectUnderTest.logInWith(email: fakeEmail, password: fakePassword)
        expectToEventually(hasLatestValueEmitted)
        
        hasLatestValueEmitted = false
        network.shouldAuthenticationSucceed = false
        subjectUnderTest.logInWith(email: fakeEmail, password: fakePassword)
        expectToEventually(hasLatestValueEmitted)
        
        hasLatestValueEmitted = false
        network.shouldNetworkSucceed = false
        subjectUnderTest.logInWith(email: fakeEmail, password: fakePassword)
        expectToEventually(hasLatestValueEmitted)
        
        hasLatestValueEmitted = false
        network.shouldNetworkSucceed = true
        network.shouldAuthenticationSucceed = true
        subjectUnderTest.logInWith(email: fakeEmail, password: fakePassword)
        expectToEventually(hasLatestValueEmitted)
        
        XCTAssertEqual(expectedValues, receivedValues)
        XCTAssertNotNil(disposable)
    }

    func testRequestResetPassword() throws {
        let requested = true
        let failure: Bool? = nil
        let expectedValues = [requested, failure, requested]
        var receivedValues: [Bool?] = []
        
        let disposable = subjectUnderTest.passwordResetRequested.sink {
            switch $0 {
            case .success:
                receivedValues.append(requested)
            case .failure:
                receivedValues.append(failure)
            }
            self.hasLatestValueEmitted = true
        }
        
        hasLatestValueEmitted = false
        subjectUnderTest.requestResetPassword(email: fakeEmail)
        expectToEventually(hasLatestValueEmitted)
        
        hasLatestValueEmitted = false
        network.shouldNetworkSucceed = false
        subjectUnderTest.requestResetPassword(email: fakeEmail)
        expectToEventually(hasLatestValueEmitted)
        
        hasLatestValueEmitted = false
        network.shouldNetworkSucceed = true
        network.isPasswordResetEmailOnFile = false
        subjectUnderTest.requestResetPassword(email: fakeEmail)
        expectToEventually(hasLatestValueEmitted)
        
        XCTAssertEqual(expectedValues, receivedValues)
        XCTAssertNotNil(disposable)
    }
    
    func testBiometricAuthentication() throws {
        let expectedValues = [false, true, false, false, true, false]
        var receivedValues: [Bool?] = []
        
        let disposable = subjectUnderTest.loggedInUser.sink {
            switch $0 {
            case .success:
                receivedValues.append(true)
            case .failure:
                receivedValues.append(false)
            }
            self.hasLatestValueEmitted = true
        }
        
        hasLatestValueEmitted = false
        subjectUnderTest.requestBiometricAuthentication()
        expectToEventually(hasLatestValueEmitted)
        
        hasLatestValueEmitted = false
        userSession.updateBiometricAuth(.enabled(fakeEmail, fakePassword))
        subjectUnderTest.requestBiometricAuthentication()
        expectToEventually(hasLatestValueEmitted)
        
        hasLatestValueEmitted = false
        network.shouldAuthenticationSucceed = false
        subjectUnderTest.requestBiometricAuthentication()
        expectToEventually(hasLatestValueEmitted)
        
        hasLatestValueEmitted = false
        network.shouldAuthenticationSucceed = true
        network.shouldNetworkSucceed = false
        subjectUnderTest.requestBiometricAuthentication()
        expectToEventually(hasLatestValueEmitted)
        
        hasLatestValueEmitted = false
        network.shouldNetworkSucceed = true
        subjectUnderTest.requestBiometricAuthentication()
        expectToEventually(hasLatestValueEmitted)
        
        hasLatestValueEmitted = false
        userSession.updateBiometricAuth(.disabled)
        subjectUnderTest.requestBiometricAuthentication()
        expectToEventually(hasLatestValueEmitted)
        
        XCTAssertEqual(expectedValues, receivedValues)
        XCTAssertNotNil(disposable)
    }
}
