//
//  SignUpPersonalDetailsView.swift
//
//
//  Created by Trupti Veer on 01/12/20.
//  Copyright © 2020. All rights reserved.
//

import SwiftUI

struct SignUpPersonalDetailsView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @ObservedObject var viewModel: SignUpPersonalDetailsViewModel
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: SignUpAppearance.Dimensions.cardContentPadding) {
                    TopCardView {
                        ZStack(alignment: .bottomPickerTrailing) {
                            VStack(alignment: .leading, spacing: SignUpAppearance.Dimensions.cardContentSpacing) {
                                VStack(alignment: .leading, spacing: Spacer.small.rawValue) {
                                    Text(LocalizedString.CreateAccount.subtitle)
                                        .Font(.b3M)
                                    
                                    Text(LocalizedString.CreateAccount.description)
                                        .Font(.b2)
                                }
                                .padding(.top, Spacer.mediumSmall.rawValue)
                                
                                FloatingTextField(
                                    text: $viewModel.firstName,
                                    placeholderText: Field.firstName.placeholder,
                                    errorMessage: $viewModel.firstNameErrorMessage,
                                    config: .init(.firstName)
                                )
                                .accessibility(label: Text(Field.firstName.accessibilityLabel))
                                
                                FloatingTextField(
                                    text: $viewModel.lastName,
                                    placeholderText: Field.lastName.placeholder,
                                    errorMessage: $viewModel.lastNameErrorMessage,
                                    config: .init(.lastName)
                                )
                                .accessibility(label: Text(Field.lastName.accessibilityLabel))

                                FloatingTextField(
                                    text: $viewModel.birthdateString,
                                    placeholderText: Field.birthdate.placeholder,
                                    accessoryType: .datePickerIndicator($viewModel.showDatePicker),
                                    errorMessage: $viewModel.dateOfBirthErrorMessage
                                )
                                .accessibility(label: Text(Field.birthdate.accessibilityLabel))
                                .disabled(true)
                                .alignmentGuide(.bottomPicker) { $0[.bottom] }
                                .onTapGesture {
                                    viewModel.toggleShowDatePicker()
                                }
                                
                                FloatingTextField(
                                    text: viewModel.formattedMobilePhone,
                                    placeholderText: Field.mobilePhone.placeholder,
                                    errorMessage: $viewModel.phoneErrorMessage,
                                    config: .init(.phoneNumber)
                                )
                                .accessibility(label: Text(Field.mobilePhone.accessibilityLabel))

                                FloatingTextField(
                                    text: $viewModel.email,
                                    placeholderText: Field.email.placeholder,
                                    errorMessage: $viewModel.emailErrorMessage,
                                    config: .init(.email)
                                )
                                .accessibility(label: Text(Field.email.accessibilityLabel))
                                
                                FloatingTextField(
                                    text: $viewModel.password,
                                    placeholderText: Field.password.placeholder,
                                    accessoryType: .toggleSecureTextButton,
                                    errorMessage: $viewModel.passwordErrorMessage,
                                    isSecure: $viewModel.isPasswordSecure,
                                    config: .init(.password)
                                )
                                .accessibility(label: Text(Field.password.accessibilityLabel))

                                FloatingTextField(
                                    text: $viewModel.confirmPassword,
                                    placeholderText: Field.confirmPassword.placeholder,
                                    accessoryType: .toggleSecureTextButton,
                                    errorMessage: $viewModel.confirmPasswordErrorMessage,
                                    isSecure: $viewModel.isConfirmPasswordSecure,
                                    config: .init(.password)
                                )
                                .accessibility(label: Text(Field.confirmPassword.accessibilityLabel))
                                                               
                            }
                            .padding(.horizontal, SignUpAppearance.Dimensions.cardContentPadding)
                            .onTapGesture {
                                viewModel.toggleShowDatePicker(false)
                            }
                            
                            if viewModel.showDatePicker {
                                FieldInputDatePicker(selected: $viewModel.dateOfBirth, config: .birthdate)
                                    .alignmentGuide(.bottomPicker) { $0[.top] }
                                    .zIndex(2)
                                    .padding(.horizontal, Appearance.Dimensions.contentPadding)
                            }
                        }
                    }
                    
                    Spacer.buttonContainerSpacer
                }
                .background(Color.blue500)
            }
            
            CTAButtonContainer(
                style: .dark,
                primaryTitle: $viewModel.primaryCTATitle,
                isPrimaryEnabled: $viewModel.isPrimaryCTAEnabled,
                isPrimaryLoading: $viewModel.isLoading,
                onPrimaryTapped: viewModel.primaryButtonTapped
            )
        }
        .addNavigationLink(to: $viewModel.nextView, isActive: $viewModel.isPushNavigationActive)
        .navigationBarWithBackButton(title: $viewModel.title, backButtonAction: viewModel.goBack)
        .trackViewAppeared(name)
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .onReceive(viewModel.goBackSubject) {
            presentationMode.wrappedValue.dismiss()
        }
        .alert(isPresented: $viewModel.alert.isNullBinding()) {
            viewModel.alert ?? viewModel.defaultAlert()
        }
        .sheet(isPresented: $viewModel.isSheetPresented) {
            NavigationView {
                viewModel.nextView
            }
        }
    }
}

// MARK: - Enums
extension SignUpPersonalDetailsView {
    enum Field {
        case birthdate, confirmPassword, email, firstName, lastName, mobilePhone, password
        
        var placeholder: String {
            switch self {
            case .birthdate: return LocalizedString.CreateAccount.Placeholder.dateOfBirth.capitalized
            case .confirmPassword: return LocalizedString.CreateAccount.Placeholder.confirmPassword.capitalized
            case .email: return LocalizedString.FormFields.Email.placeholder.capitalized
            case .firstName: return LocalizedString.CreateAccount.Placeholder.firstName.capitalized
            case .lastName: return LocalizedString.CreateAccount.Placeholder.lastName.capitalized
            case .mobilePhone: return LocalizedString.CreateAccount.Placeholder.mobilePhone.capitalized
            case .password: return LocalizedString.CreateAccount.Placeholder.password.capitalized
            }
        }
        var accessibilityLabel: String {
            switch self {
            case .birthdate: return LocalizedString.CreateAccount.AccessibilityLabel.dateOfBirth
            case .confirmPassword: return LocalizedString.CreateAccount.AccessibilityLabel.confirmPassword
            case .email: return LocalizedString.FormFields.Email.accessibilityLabel
            case .firstName: return LocalizedString.CreateAccount.AccessibilityLabel.firstName
            case .lastName: return LocalizedString.CreateAccount.AccessibilityLabel.lastName
            case .mobilePhone: return LocalizedString.CreateAccount.AccessibilityLabel.mobilePhone
            case .password: return LocalizedString.CreateAccount.AccessibilityLabel.password
            }
        }
    }
}

struct SignUpPersonalDetailsView_Previews: PreviewProvider {
    static let coordinator = SignUpCoordinator.previewCoordinator()

    static var previews: some View {
        Group {
            NavigationView {
                SignUpPersonalDetailsView(
                    viewModel: SignUpPersonalDetailsViewModel(zipCode: "10001", coordinator: coordinator)
                )
            }
            .previewInDevice(.iPhone12Mini)
            
            NavigationView {
                SignUpPersonalDetailsView(
                    viewModel: SignUpPersonalDetailsViewModel(zipCode: "10001", coordinator: coordinator)
                )
            }
            .previewInDevice(.iPhone12ProMax)
            
            NavigationView {
                SignUpPersonalDetailsView(
                    viewModel: SignUpPersonalDetailsViewModel(zipCode: "10001", coordinator: coordinator)
                )
            }
            .previewInDevice(.iPodtouchGen7)
        }
    }
}
