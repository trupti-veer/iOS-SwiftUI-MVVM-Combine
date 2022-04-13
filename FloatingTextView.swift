//
//  FloatingTextView.swift
//  
//
//  Created by Trupti Veer on 7/1/21.
//  Copyright © 2021. All rights reserved.
//

import SwiftUI

struct FloatingTextView: View {
    enum ValidationMode {
        case optional
        case textRequired
        case other(_ validationHandler: (String) -> Bool, _ errorMessage: String)
    }
    
    @Binding var text: String
    var placeholder: String
    var mode: ValidationMode = .optional
    var height = Constants.textViewHeight
    @State private var isEditing = false
    @State private var errorMessage: String?
    
    var body: some View {
        if #available(iOS 14.0, *) {
            VStack {
                ZStack(alignment: .topLeading) {
                    TextView(text: $text, isEditing: $isEditing)
                        .padding(Spacer.xSmall.rawValue)
                        .overlay(
                            RoundedRectangle(cornerRadius: Spacer.xxSmall.rawValue)
                                .stroke(borderColor, lineWidth: 1)
                        )
                        .frame(height: height)

                    // Floating placeholder
                    if isEditing || !text.isValid {
                        Text(placeholder)
                            .Font(placeholderStyle, color: placeholderColor)
                            .padding(.leading, Constants.smallestPadding)
                            .padding(.trailing, Spacer.xxSmall.rawValue)
                            .background(Color.white)
                            .padding(.leading, Spacer.xSmall.rawValue)
                            .offset(y: placeholderOffset)
                            .onTapGesture {
                                isEditing = true
                            }
                    }
                }
                .onChange(of: isEditing) {
                    // Shows an error when the user taps into the text view, doesn't type anything, and taps out.
                    switch mode {
                    case .textRequired:
                        // For freeform text, clear the error message when editing begins; show the error message
                        // when editing ends *and* there's no (non-whitespace) text.
                        errorMessage = !text.isValid && !$0 ? LocalizedString.ValidationError.freeformTextView : ""
                    case .other(_, let errorText):
                        // For other validation requirements, (most) validation will be handled when the `text`
                        // value changes. Here, validate only when editing ends *and* there's no (non-whitespace) text.
                        if !$0, !text.isValid {
                            errorMessage = errorText
                        }
                    case .optional: return
                    }
                }
                .onChange(of: text) {
                    guard case .other(let validationHandler, let errorMessage) = mode else { return }
                    self.errorMessage = validationHandler($0) ? "" : errorMessage
                }
            
                if hasErrorMessage, let errorMessage = errorMessage {
                    HStack {
                        Text(errorMessage)
                            .Font(.b3, color: .red)
                            .lineLimit(nil)
                            .padding(.leading, Spacer.small.rawValue)

                        Spacer()
                    }
                }
            }
        } else {
            TextView(text: $text, isEditing: $isEditing)
        }
    }
}

// MARK: - Private Extension
private extension FloatingTextView {
    var hasErrorMessage: Bool {
        errorMessage?.isValid == true
    }
    var borderColor: Color {
        if hasErrorMessage {
            return .red500
        }
        return isEditing ? .blue500 : .lightGray400
    }
    var placeholderStyle: TextStyle {
        if isEditing {
            return hasErrorMessage ? .b3 : .b3M
        }
        return .b1
    }
    var placeholderColor: TextColor {
        if isEditing {
            return hasErrorMessage ? .red : .blue
        }
        return .gray
    }
    var placeholderOffset: CGFloat {
        isEditing ? -5 : Spacer.small.rawValue
    }

    // MARK: - Constants
    enum Constants {
        static let textViewHeight: CGFloat = 80
        static let smallestPadding: CGFloat = 4
    }
}

struct FloatingTextView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewView()
    }
    
    private struct PreviewView: View {
        @ObservedObject var viewModel = ViewModel()

        var body: some View {
            Group {
                FloatingTextView(text: $viewModel.requiredText, placeholder: "Valid text required", mode: .textRequired)
                    .padding(.horizontal, Spacer.small.rawValue)
                    .previewLayout(.sizeThatFits)
                
                FloatingTextView(
                    text: $viewModel.email,
                    placeholder: "Valid email required",
                    mode: .other(ValidationUtil.isEmailValid(_:), "Enter a valid email")
                )
                .padding(.horizontal, Spacer.small.rawValue)
                .previewLayout(.sizeThatFits)
                
                FloatingTextView(text: $viewModel.optionalText, placeholder: "Optional")
                    .padding(.horizontal, Spacer.small.rawValue)
                    .previewLayout(.sizeThatFits)
            }
        }
    }
    
    private class ViewModel: ObservableObject {
        @Published var requiredText = ""
        @Published var email = ""
        @Published var optionalText = ""
    }
}
