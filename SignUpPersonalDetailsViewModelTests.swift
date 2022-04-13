//
//  SignUpPersonalDetailsViewModelTests.swift
//
//
//  Created by Trupti Veer on 2/9/21.
//  Copyright © 2021. All rights reserved.
//

import XCTest
@testable import XYZ

class SignUpPersonalDetailsViewModelTests: XCTestCase {
    var subjectUnderTest: SignUpPersonalDetailsViewModel!
    var mockAuthService: MockAuthenticationService!
    private let calendar = Calendar(identifier: .gregorian)

    override func setUpWithError() throws {
        mockAuthService = MockFactory.buildMockAuthenticationService()
        subjectUnderTest = .init(
            zipCode: "11223",
            coordinator: MockFactory.mockSignUpCoordinator(authService: mockAuthService)
        )
        subjectUnderTest.onAppear()

        try! super.setUpWithError()
    }

    func testIsFirstNameValid() throws {
        let initialValue: String? = nil
        let emptyString = LocalizedString.ValidationError.firstName, whitespaceString = LocalizedString.ValidationError.firstName
        let validName = ""

        let inputValues = ["Test", "", "Another name", " "]

        let expectedValues = [initialValue, validName, emptyString, validName, whitespaceString]
        var receivedValues: [String?] = []

        let disposable = subjectUnderTest.$firstNameErrorMessage
            .sink {
                receivedValues.append($0)
                self.hasLatestValueEmitted = true
            }

        expectToEventually(hasLatestValueEmitted)

        inputValues.forEach {
            hasLatestValueEmitted = false
            subjectUnderTest.firstName = $0
            expectToEventually(hasLatestValueEmitted)
        }

        XCTAssertEqual(expectedValues, receivedValues)
        XCTAssertNotNil(disposable)
    }

    func testIsLastNameValid() throws {
        let initialValue: String? = nil
        let emptyString = LocalizedString.ValidationError.lastName, whitespaceString = LocalizedString.ValidationError.lastName
        let validName = ""

        let inputValues = ["Test", "", "Another name", " "]

        let expectedValues = [initialValue, validName, emptyString, validName, whitespaceString]
        var receivedValues: [String?] = []

        let disposable = subjectUnderTest.$lastNameErrorMessage
            .sink {
                receivedValues.append($0)
                self.hasLatestValueEmitted = true
            }

        expectToEventually(hasLatestValueEmitted)

        inputValues.forEach {
            hasLatestValueEmitted = false
            subjectUnderTest.lastName = $0
            expectToEventually(hasLatestValueEmitted)
        }

        XCTAssertEqual(expectedValues, receivedValues)
        XCTAssertNotNil(disposable)
    }

    func testIsDateOfBirthValid() throws {
        let initialValue: String? = nil
        let empty = LocalizedString.ValidationError.dateOfBirth
        let validDate = ""

        let inputValues = ["04/04/1987", "", "05/25/1988", " "]
        let expectedValues = [initialValue, validDate, empty, validDate, empty]
        var receivedValues: [String?] = []

        let disposable = subjectUnderTest.$dateOfBirthErrorMessage
            .sink {
                receivedValues.append($0)
                self.hasLatestValueEmitted = true
            }

        expectToEventually(hasLatestValueEmitted)

        inputValues.forEach {
            hasLatestValueEmitted = false
            subjectUnderTest.showDatePicker = true
            subjectUnderTest.birthdateString = $0
            subjectUnderTest.showDatePicker = false
            expectToEventually(hasLatestValueEmitted)
        }

        XCTAssertEqual(expectedValues, receivedValues)
        XCTAssertNotNil(disposable)
    }

    func testIsPhoneNumberValid() throws {
        let phoneNumberError = LocalizedString.ValidationError.phoneNumber
        let initialValue: String? = nil
        let whitespaceString = phoneNumberError, alphaOnlyString = phoneNumberError, specialCharactersString = phoneNumberError
        let validPhoneNumber = ""

        let inputValues = ["(203) 548-1364", " ", "invalid", "~555~555~5555", "520-360-5540"]
        let expectedValues = [initialValue, validPhoneNumber, whitespaceString, alphaOnlyString, specialCharactersString, validPhoneNumber]
        var receivedValues: [String?] = []

        let disposable = subjectUnderTest.$phoneErrorMessage
            .sink {
                receivedValues.append($0)
                self.hasLatestValueEmitted = true
            }

        expectToEventually(hasLatestValueEmitted)

        inputValues.forEach {
            hasLatestValueEmitted = false
            subjectUnderTest.mobilePhone = $0
            expectToEventually(hasLatestValueEmitted)
        }

        XCTAssertEqual(expectedValues, receivedValues)
        XCTAssertNotNil(disposable)
    }

    func testFormattedPhoneNumber() throws {
        // Too short
        subjectUnderTest.formattedMobilePhone.wrappedValue = "203"
        XCTAssertEqual(subjectUnderTest.mobilePhone, "203")
        // Valid
        subjectUnderTest.formattedMobilePhone.wrappedValue = "2035481364"
        XCTAssertEqual(subjectUnderTest.mobilePhone, "(203) 548-1364")
        // Too long
        subjectUnderTest.formattedMobilePhone.wrappedValue = "203548136499"
        XCTAssertEqual(subjectUnderTest.mobilePhone, "203548136499")
        // Valid
        subjectUnderTest.formattedMobilePhone.wrappedValue = "5555555555"
        XCTAssertEqual(subjectUnderTest.mobilePhone, "(555) 555-5555")
    }

    func testIsEmailValid() throws {
        let initialValue: String? = nil
        let whitespaceString = LocalizedString.ValidationError.email, invalidFormat = LocalizedString.ValidationError.email
        let validEmail = ""

        let inputValues = ["invalid", " ", "invalid@", "invalid@123.", "test@email.com"]

        let expectedValues = [initialValue, invalidFormat, whitespaceString, invalidFormat, invalidFormat, validEmail]
        var receivedValues: [String?] = []

        let disposable = subjectUnderTest.$emailErrorMessage
            .sink {
                receivedValues.append($0)
                self.hasLatestValueEmitted = true
            }

        expectToEventually(hasLatestValueEmitted)

        inputValues.forEach {
            hasLatestValueEmitted = false
            subjectUnderTest.email = $0
            expectToEventually(hasLatestValueEmitted)
        }

        XCTAssertEqual(expectedValues, receivedValues)
        XCTAssertNotNil(disposable)
    }

    func testIsPasswordValid() throws {
        let initialValue: String? = nil
        let whitespaceString = LocalizedString.ValidationError.password, tooShort = LocalizedString.ValidationError.password, noSpecialCharacter = LocalizedString.ValidationError.password, noNumber = LocalizedString.ValidationError.password, noUppercase = LocalizedString.ValidationError.password, noLowercase = LocalizedString.ValidationError.password
        let validPassword = ""

        let inputValues = [" ", "Abc123!", "Secret123", "Secret!.", "secret123!", "SECRET123!", "Secret123!"]
        let expectedValues = [initialValue, whitespaceString, tooShort, noSpecialCharacter, noNumber, noUppercase, noLowercase, validPassword]
        var receivedValues: [String?] = []

        let disposable = subjectUnderTest.$passwordErrorMessage
            .sink {
                receivedValues.append($0)
                self.hasLatestValueEmitted = true
            }

        expectToEventually(hasLatestValueEmitted)

        inputValues.forEach {
            hasLatestValueEmitted = false
            subjectUnderTest.password = $0
            expectToEventually(hasLatestValueEmitted)
        }

        XCTAssertEqual(expectedValues, receivedValues)
        XCTAssertNotNil(disposable)
    }

    func testIsConfirmPasswordValid() throws {
        let initialValue: String? = nil
        let nonMatching = LocalizedString.ValidationError.confirmPassword, invalid = LocalizedString.ValidationError.confirmPassword, nonMatchingInvalid = LocalizedString.ValidationError.confirmPassword
        let matchingValidPassword = ""

        let inputValues = [("Secret123", "invalid"), (" ", " "), ("Abcd1234!", "Secret123!"), ("Abcd1234!", "Abcd1234!")]
        let expectedValues = [initialValue, nonMatchingInvalid, invalid, nonMatching, matchingValidPassword]
        var receivedValues: [String?] = []

        let disposable = subjectUnderTest.$confirmPasswordErrorMessage
            .sink {
                receivedValues.append($0)
                self.hasLatestValueEmitted = true
            }

        expectToEventually(hasLatestValueEmitted)

        inputValues.forEach { password, confirmPassword in
            hasLatestValueEmitted = false
            subjectUnderTest.password = password
            subjectUnderTest.confirmPassword = confirmPassword
            expectToEventually(hasLatestValueEmitted)
        }

        XCTAssertEqual(expectedValues, receivedValues)
        XCTAssertNotNil(disposable)
    }

    func testValidSignUpInformation() throws {
        let initialValue = true, enabled = true
        let disabled = false

        let expectedValues = [initialValue, disabled, enabled]
        var receivedValues: [Bool] = []

        let disposable = subjectUnderTest.$isPrimaryCTAEnabled.sink {
            receivedValues.append($0)
            self.hasLatestValueEmitted = true
        }

        expectToEventually(hasLatestValueEmitted)
        hasLatestValueEmitted = false

        subjectUnderTest.firstName = "Test"
        subjectUnderTest.lastName = "Test"
        subjectUnderTest.mobilePhone = "203-548-1364"
        subjectUnderTest.email = "test@test.com"
        subjectUnderTest.password = "Secret123!"
        subjectUnderTest.confirmPassword = "Secret123!"
        subjectUnderTest.isTermsChecked = true
        let dateComponents = DateComponents(year: 1987, month: 4, day: 4)
        subjectUnderTest.dateOfBirth = calendar.date(from: dateComponents)!

        expectToEventually(hasLatestValueEmitted)

        XCTAssertEqual(expectedValues, receivedValues)
        XCTAssertNotNil(disposable)
    }

    func testRegisterUser() throws {
        let success = true, failure = false

        let shouldNetworkSucceed = [false, true]
        let expectedValues = [failure, success]
        var receivedValues: [Bool] = []

        let disposable = mockAuthService.loggedInUser.sink {
            switch $0 {
            case .success:
                receivedValues.append(success)
            case .failure:
                receivedValues.append(failure)
            }
            self.hasLatestValueEmitted = true
        }

        shouldNetworkSucceed.forEach {
            hasLatestValueEmitted = false

            mockAuthService.shouldNetworkSucceed = $0
            subjectUnderTest.registerUser()

            expectToEventually(hasLatestValueEmitted)
        }

        XCTAssertEqual(expectedValues, receivedValues)
        XCTAssertNotNil(disposable)
    }
}
