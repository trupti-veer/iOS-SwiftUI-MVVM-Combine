//
//  FloatingTextField.swift
//
//  Created by Trupti Veer on 02/11/20.
//  Copyright © 2020. All rights reserved.
//

import SwiftUI

struct FloatingTextField: View {
    // MARK: - Properties
    @Binding var text: String
    @Binding var errorMessage: String?
    @Binding var wrappedIsSecure: Bool
    @Binding var showValidationIcon: Bool
    var isPickerPresented: Binding<Bool>?
    var placeholderText: String
    var accessoryType: TextFieldAccessoryType?
    var config: TextFieldConfig
    var editingChanged: ((String) -> Void)?
    @State private var isEditing = false

    // MARK: - Initializer
    init(
        text: Binding<String>,
        placeholderText: String,
        accessoryType: TextFieldAccessoryType? = nil,
        errorMessage: Binding<String?> = .constant(nil),
        showValidationIcon: Binding<Bool> = .constant(true),
        isSecure: Binding<Bool> = .constant(false),
        config: TextFieldConfig = .init(),
        editingChanged: ((String) -> Void)? = nil
    ) {
        self._text = text
        self.placeholderText = placeholderText
        self.accessoryType = accessoryType
        self._errorMessage = errorMessage
        self._showValidationIcon = showValidationIcon
        self._wrappedIsSecure = isSecure
        self.config = config
        self.editingChanged = editingChanged
        
        switch accessoryType {
        case .pickerIndicator(let isPresented):
            isPickerPresented = isPresented
        case .datePickerIndicator(let isPresented):
            isPickerPresented = isPresented
        default:
            isPickerPresented = nil
        }
    }

    // MARK: - Body
    var body: some View {
        VStack {
            ZStack(alignment: .leading) {
                HStack {
                    ToolbarTextField(
                        text: $text,
                        isEditing: $isEditing,
                        isSecure: isSecure,
                        config: config,
                        editingChanged: editingChanged
                    )

                    rightAccessoryView

                    TextFieldValidationView(errorMessage: $errorMessage, isVisible: $showValidationIcon)
                }
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .opacity(0)
                )
                .frame(height: Appearance.Dimensions.textFieldHeight)

                // Floating placeholder
                Text(placeholderText)
                    .Font(placeholderFont, color: placeholderColor)
                    .padding(.leading, 4)
                    .padding(.trailing, Spacer.xxSmall.rawValue)
                    .background(placeholderBackgroundColor)
                    .padding(.bottom, shouldPlaceholderMove ? Appearance.Dimensions.textFieldHeight - 5 : 0)
                    .padding(.leading, Spacer.xSmall.rawValue)
                    .zIndex(shouldPlaceholderMove ? 1 : -1)
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(placeholderBackgroundColor)
            )

            if hasErrorMessage, let errorMessage = errorMessage {
                HStack {
                    Text(errorMessage)
                        .Font(.b3, color: .red)
                        .lineLimit(nil)
                        .fixedHeight()
                        .padding(.leading, Spacer.small.rawValue)

                    Spacer()
                }
            }
        }
    }
}

// MARK: - AccessoryTextField
extension FloatingTextField: AccessoryTextField {
    var isSecure: Binding<Bool> {
        $wrappedIsSecure
    }
}

// MARK: - Private Extension
private extension FloatingTextField {
    var showEditingState: Bool {
        isEditing || isPickerPresented?.wrappedValue == true
    }
    var shouldPlaceholderMove: Bool {
        text.isValid || isEditing
    }
    var hasErrorMessage: Bool {
        errorMessage?.isValid == true
    }
    var placeholderBackgroundColor: Color {
        shouldPlaceholderMove ? .white : .lightGray50
    }
    var placeholderLineHeight: CGFloat {
        shouldPlaceholderMove ? 4 : 10
    }
    var borderColor: Color {
        if hasErrorMessage {
            return .red500
        }
        return showEditingState ? .blue500 : .lightGray400
    }
    var borderWidth: CGFloat {
        isEditing ? 1.5 : 1
    }
    var placeholderFont: TextStyle {
        guard shouldPlaceholderMove else {
            return .b1
        }
        return showEditingState ? .b3M : .b3
    }
    var placeholderColor: TextColor {
        guard shouldPlaceholderMove else {
            return .gray
        }
        if hasErrorMessage {
            return .red
        }
        if showEditingState {
            return .blue
        }
        return .gray
    }
}

// MARK: - Previews
struct FloatingTextField_Previews: PreviewProvider {
    @ObservedObject static var viewModel = PreviewViewModel()

    static var previews: some View {
        VStack(spacing: 16) {
            FloatingTextField(
                text: $viewModel.name,
                placeholderText: "Name*"
            )

            FloatingTextField(
                text: $viewModel.birthday,
                placeholderText: "Date of birth*",
                accessoryType: .otherIcon(Assets.Icons.calendar)
            )

            FloatingTextField(
                text: $viewModel.email,
                placeholderText: "Email*",
                errorMessage: $viewModel.emailError
            )

            FloatingTextField(
                text: $viewModel.password,
                placeholderText: "Password*",
                accessoryType: .toggleSecureTextButton,
                errorMessage: $viewModel.passwordError
            )

            FloatingTextField(
                text: .constant(""),
                placeholderText: "Picker",
                accessoryType: .pickerIndicator(.constant(true))
            )
        }
        .padding()
    }

    class PreviewViewModel: ObservableObject {
        @Published var name = ""
        @Published var birthday = ""
        @Published var email = ""
        @Published var password = ""
        @Published var emailError: String? = "please enter your email address"
        @Published var passwordError: String? = "please enter your password"
    }
}
