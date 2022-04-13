//
//  AuthenticationNetworkTests.swift
//
//
//  Created by Trupti Veer on 10/19/21.
//  Copyright © 2021 . All rights reserved.
//

import XCTest
@testable import XYZ

class AuthenticationNetworkTests: XCTestCase {
    var mockOktaWrapper: MockOktaWrapper!
    var subjectUnderTest: AuthenticationNetwork!

    override func setUpWithError() throws {
        mockOktaWrapper = MockOktaWrapper()
        subjectUnderTest = AuthenticationNetwork(
            networkManager: MockFactory.mockApolloManager(oktaWrapper: mockOktaWrapper)
        )
        
        MockNetworkTransport.shouldNetworkSucceed = true
        MockNetworkTransport.shouldListenForVolumeChanged = false
    }
    
    func testRenewToken() throws {
        let renewExpectation = expectation(description: "token renewed")
        
        mockOktaWrapper.renewToken {
            if case .success = $0 {
                renewExpectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testRenewTokenFails() throws {
        let renewExpectation = expectation(description: "renew token failed")
        
        mockOktaWrapper.shouldAuthSucceed = false
        
        mockOktaWrapper.renewToken {
            if case .failure = $0 {
                renewExpectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testRegisterUser() throws {
        let registeredExpectation = expectation(description: "user registered")
        
        let disposable = subjectUnderTest.registerUser(
            with: .init(
                firstName: "test",
                lastName: "test",
                dateOfBirth: "10/25/1988",
                phoneNumber: "6035203434",
                email: "test@test.com",
                password: "Secret123!",
                zipCode: "11223"
            )
        )
        .sink {
            if case .failure(let error) = $0 {
                XCTFail(error.localizedDescription)
            }
        } receiveValue: { profile in
            XCTAssertEqual(profile.id, "CKdzEydrDNcPCxy6imRUB")
            XCTAssertEqual(profile.patientID, "CKdzEydrDNcPCxy6imRUB")
            XCTAssertEqual(profile.firstName, "trupti")
            XCTAssertEqual(profile.lastName, "trupti")
            registeredExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 2) { _ in
            XCTAssertNotNil(disposable)
        }
    }
    
    func testRegisterUserFails() throws {
        let registeredExpectation = expectation(description: "user registration failed")
        
        MockNetworkTransport.shouldNetworkSucceed = false
        
        let disposable = subjectUnderTest.registerUser(
            with: .init(
                firstName: "test",
                lastName: "test",
                dateOfBirth: "10/25/1988",
                phoneNumber: "6035203434",
                email: "test@test.com",
                password: "Secret123!",
                zipCode: "11223"
            )
        )
        .sink {
            if case .failure = $0 {
                registeredExpectation.fulfill()
            }
        } receiveValue: { _ in
            // no-op
        }
        
        waitForExpectations(timeout: 2) { _ in
            XCTAssertNotNil(disposable)
        }
    }
    
    func testLogInStep1() throws {
        let loginExpectation = expectation(description: "logged in")
        
        let disposable = subjectUnderTest.logInStep1(email: "test@test.com", password: "").sink {
            if case .failure(let error) = $0 {
                XCTFail(error.localizedDescription)
            }
        } receiveValue: { response in
            XCTAssertEqual(response.sessionToken, "20111")
            XCTAssertEqual(response.status, "SUCCESS")
            XCTAssertEqual(response.profile.firstName, "trupti")
            loginExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 2) { _ in
            XCTAssertNotNil(disposable)
        }
    }
    
    func testLogInStep1Fails() throws {
        let loginExpectation = expectation(description: "login failed")
        
        MockNetworkTransport.shouldNetworkSucceed = false
        
        let disposable = subjectUnderTest.logInStep1(email: "test@test.com", password: "").sink {
            if case .failure = $0 {
                loginExpectation.fulfill()
            }
        } receiveValue: { _ in
            // no-op
        }
        
        waitForExpectations(timeout: 2) { _ in
            XCTAssertNotNil(disposable)
        }
    }
    
    func testLogInStep2() throws {
        let loginExpectation = expectation(description: "logged in")
        
        let disposable = subjectUnderTest.logInStep2(
            .init(
                sessionToken: MockFactory.defaultMockSessionToken,
                status: "SUCCESS",
                profile: MockFactory.getMockProfile()
            )
        )
        .sink {
            if case .failure(let error) = $0 {
                XCTFail(error.localizedDescription)
            }
        } receiveValue: { profile in
            XCTAssertEqual(profile.firstName, "mock user first name")
            loginExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 1) { _ in
            XCTAssertNotNil(disposable)
        }
    }
    
    func testLogInStep2Fails() throws {
        let loginExpectation = expectation(description: "login failed")
        
        mockOktaWrapper.shouldAuthSucceed = false
        
        let disposable = subjectUnderTest.logInStep2(
            .init(
                sessionToken: "",
                status: "",
                profile: MockFactory.getMockProfile()
            )
        )
        .sink {
            if case .failure = $0 {
                loginExpectation.fulfill()
            }
        } receiveValue: { _ in
            // no-op
        }
        
        waitForExpectations(timeout: 2) { _ in
            XCTAssertNotNil(disposable)
        }
    }
    
    func testRequestPasswordReset() throws {
        let resetExpectation = expectation(description: "reset requested")
        
        let disposable = subjectUnderTest.requestPasswordReset(for: "test@test.com").sink {
            if case .failure(let error) = $0 {
                XCTFail(error.localizedDescription)
            }
        } receiveValue: { status in
            if status == .recoveryChallenge {
                resetExpectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1) { _ in
            XCTAssertNotNil(disposable)
        }
    }
    
    func testRequestPasswordResetFails() throws {
        let resetExpectation = expectation(description: "reset request failed")
        
        mockOktaWrapper.shouldAuthSucceed = false
        
        let disposable = subjectUnderTest.requestPasswordReset(for: "test@test.com").sink {
            if case .failure(let error) = $0, error != .recoveryForbidden {
                resetExpectation.fulfill()
            }
        } receiveValue: { _ in
            // no-op
        }
        
        waitForExpectations(timeout: 1) { _ in
            XCTAssertNotNil(disposable)
        }
    }
    
    func testRequestPasswordResetNotOnFile() throws {
        let resetExpectation = expectation(description: "reset requested; email not on file")
        
        mockOktaWrapper.isRecoveryEmailOnFile = false
        
        let disposable = subjectUnderTest.requestPasswordReset(for: "test@test.com").sink {
            if case .failure(let error) = $0, error == .recoveryForbidden {
                resetExpectation.fulfill()
            }
        } receiveValue: { _ in
            // no-op
        }
        
        waitForExpectations(timeout: 1) { _ in
            XCTAssertNotNil(disposable)
        }
    }
}
