//
//  SignUpPersonalDetailsViewModel.swift
//
//
//  Created by Trupti Veer on 10/12/20.
//  Copyright © 2020. All rights reserved.
//

import Combine
import SwiftUI

class SignUpPersonalDetailsViewModel: BaseViewModel, ObservableObject {
    // MARK: Input
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var zipCode = ""
    @Published var mobilePhone = ""
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var birthdateString = ""
    @Published var isTermsChecked = false
    @Published var dateOfBirth = FieldInputDatePicker.Config.birthdate.defaultValue
    @Published var showDatePicker = false
    @Published var firstNameErrorMessage: String?
    @Published var lastNameErrorMessage: String?
    @Published var dateOfBirthErrorMessage: String?
    @Published var phoneErrorMessage: String?
    @Published var emailErrorMessage: String?
    @Published var passwordErrorMessage: String?
    @Published var confirmPasswordErrorMessage: String?
    @Published var isPasswordSecure = true
    @Published var isConfirmPasswordSecure = true

    // MARK: Output
    @Published var isEmailAvailable = false
    @Published var isSignUpSuccessful = false
    var formattedMobilePhone: Binding<String> {
        Binding<String>(
            get: { self.mobilePhone },
            set: { self.mobilePhone = $0.formattedPhoneNumber }
        )
    }

    // MARK: Private Properties
    private let authService: AuthenticationServiceInterface

    // MARK: Lifecycle
    init(zipCode: String, coordinator: SignUpCoordinator) {
        self.zipCode = zipCode
        authService = coordinator.authService
        super.init(coordinator: coordinator)

        title = LocalizedString.CreateAccount.title
        primaryCTATitle = LocalizedString.CreateAccount.create
    }

    override func onAppear() {
        super.onAppear()
        configureViewSubscribers()
        configureValidationSubscribers()
        configureAuthServiceSubscribers()
    }
    
    override func primaryButtonTapped() {
        registerUser()
    }
}

// MARK: - Internal Methods
extension SignUpPersonalDetailsViewModel {
    func registerUser() {
        isLoading = true
        authService.registerUser(with: CreateAccountInput(self))
    }

    func toggleShowDatePicker(_ showPicker: Bool? = nil) {
        withAnimation(.halfSecondEaseInOut) {
            if let showPicker = showPicker {
                showDatePicker = showPicker
            } else {
                showDatePicker.toggle()
            }
        }
    }

    func presentSheet(_ content: WebViewContent) {
        prepareForNavigation(with: SignUpDestination.webView(content), type: .sheet)
    }
}

// MARK: - Private Extension
private extension SignUpPersonalDetailsViewModel {
    func configureValidationSubscribers() {
        let isFirstNameValid = $firstName.map { $0.isValid }
        isFirstNameValid
            .dropFirst()
            .debounce(for: .seconds(Appearance.debounceTime), scheduler: RunLoop.main)
            .receive(on: RunLoop.main)
            .sink { [weak self] isValid in
                if !isValid {
                    self?.firstNameErrorMessage = LocalizedString.ValidationError.firstName
                }
            }
            .store(in: &cancellableSet)
        isFirstNameValid
            .receive(on: RunLoop.main)
            .sink { [weak self] isValid in
                if isValid {
                    self?.firstNameErrorMessage = ""
                }
            }
            .store(in: &cancellableSet)
        
        let isLastNameValid = $lastName.map { $0.isValid }
        isLastNameValid
            .dropFirst()
            .debounce(for: .seconds(Appearance.debounceTime), scheduler: RunLoop.main)
            .receive(on: RunLoop.main)
            .sink { [weak self] isValid in
                if !isValid {
                    self?.lastNameErrorMessage = LocalizedString.ValidationError.lastName
                }
            }
            .store(in: &cancellableSet)
        isLastNameValid
            .receive(on: RunLoop.main)
            .sink { [weak self] isValid in
                if isValid {
                    self?.lastNameErrorMessage = ""
                }
            }
            .store(in: &cancellableSet)
        
        // FIXME: Should we also check that the user is over 13, per... some data security requirement (can't remember
        // which one it is right now though)?
        let isDateOfBirthValid = $birthdateString.map { $0.isValid }
        isDateOfBirthValid
            .receive(on: RunLoop.main)
            .sink { [weak self] isValid in
                if isValid {
                    self?.dateOfBirthErrorMessage = ""
                }
            }
            .store(in: &cancellableSet)
        // Only show error message when the date picker has been dismissed and no date is selected.
        $showDatePicker
            .dropFirst()
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                if !$0, self?.birthdateString.isValid == false {
                    self?.dateOfBirthErrorMessage = LocalizedString.ValidationError.dateOfBirth
                }
            }
            .store(in: &cancellableSet)
        
        let isPhoneNumberValid = $mobilePhone
            .removeDuplicates()
            .map { ValidationUtil.isPhoneNumberValid($0) }
        isPhoneNumberValid
            .dropFirst()
            .debounce(for: .seconds(Appearance.debounceTime), scheduler: RunLoop.main)
            .receive(on: RunLoop.main)
            .sink { [weak self] isValid in
                if !isValid {
                    self?.phoneErrorMessage = LocalizedString.ValidationError.phoneNumber
                }
            }
            .store(in: &cancellableSet)
        isPhoneNumberValid
            .receive(on: RunLoop.main)
            .sink { [weak self] isValid in
                if isValid {
                    self?.phoneErrorMessage = ""
                }
            }
            .store(in: &cancellableSet)
        
        let isEmailValid = $email
            .removeDuplicates()
            .map { ValidationUtil.isEmailValid($0) }
        isEmailValid
            .dropFirst()
            .debounce(for: .seconds(Appearance.debounceTime), scheduler: RunLoop.main)
            .receive(on: RunLoop.main)
            .sink { [weak self] isValid in
                if !isValid {
                    self?.emailErrorMessage = LocalizedString.ValidationError.email
                }
            }
            .store(in: &cancellableSet)
        isEmailValid
            .receive(on: RunLoop.main)
            .sink { [weak self] isValid in
                if isValid {
                    self?.emailErrorMessage = ""
                }
            }
            .store(in: &cancellableSet)
        
        let isPasswordValid = $password.map { ValidationUtil.isPasswordValid($0) }
        isPasswordValid
            .dropFirst()
            .debounce(for: .seconds(Appearance.debounceTime), scheduler: RunLoop.main)
            .receive(on: RunLoop.main)
            .sink { [weak self] isValid in
                if !isValid {
                    self?.passwordErrorMessage = LocalizedString.ValidationError.password
                }
            }
            .store(in: &cancellableSet)
        isPasswordValid
            .receive(on: RunLoop.main)
            .sink { [weak self] isValid in
                if isValid {
                    self?.passwordErrorMessage = ""
                }
            }
            .store(in: &cancellableSet)
        
        let isConfirmPasswordValid = $confirmPassword.map { [weak self] confirmPassword in
            confirmPassword.isValid && confirmPassword == self?.password
        }
        isConfirmPasswordValid
            .dropFirst()
            .debounce(for: .seconds(Appearance.debounceTime), scheduler: RunLoop.main)
            .receive(on: RunLoop.main)
            .sink { [weak self] isValid in
                if !isValid {
                    self?.confirmPasswordErrorMessage = LocalizedString.ValidationError.confirmPassword
                }
            }
            .store(in: &cancellableSet)
        isConfirmPasswordValid
            .receive(on: RunLoop.main)
            .sink { [weak self] isValid in
                if isValid {
                    self?.confirmPasswordErrorMessage = ""
                }
            }
            .store(in: &cancellableSet)
        
        let publisherSet1 = Publishers.CombineLatest4(
            isFirstNameValid,
            isLastNameValid,
            isPhoneNumberValid,
            isEmailValid
        )
        .map { $0 && $1 && $2 && $3 }

        let publisherSet2 = Publishers.CombineLatest4(
            isPasswordValid,
            isConfirmPasswordValid,
            $isTermsChecked,
            isDateOfBirthValid
        )
        .map { $0 && $1 && $2 && $3 }

        Publishers.CombineLatest(publisherSet1, publisherSet2)
            .map { $0 && $1 }
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .assign(to: \.isPrimaryCTAEnabled, on: self)
            .store(in: &cancellableSet)

        $isEmailAvailable
            .dropFirst()
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] isAvailable in
                if !isAvailable {
                    self?.emailErrorMessage = LocalizedString.ValidationError.emailInUse
                }
            }
            .store(in: &cancellableSet)
    }

    func configureAuthServiceSubscribers() {
        authService.loggedInUser
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                guard let self = self else { return }
                self.isLoading = false
                switch $0 {
                case .success(let user):
                    self.isSignUpSuccessful = true
                    // TODO: Store temporarily or only store email/password when biometric auth is enabled (IOS-710).
                    self.userSession.logIn(user, with: true, email: self.email, password: self.password)
                    self.prepareForNavigation(with: SignUpDestination.allergies)
                case .failure(let error):
                    self.showAlert(message: error.localizedDescription)
                }
            }
            .store(in: &cancellableSet)
    }

    func configureViewSubscribers() {
        $dateOfBirth
            .dropFirst()
            .receive(on: RunLoop.main)
            .compactMap { DateFormatter.compactDate.string(from: $0) }
            .assign(to: \.birthdateString, on: self)
            .store(in: &cancellableSet)                
    }
}
