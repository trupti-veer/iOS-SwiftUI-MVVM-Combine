//
//  CheckboxView.swift
//  
//
//  Created by Trupti Veer on 24/12/20.
//  Copyright © 2020. All rights reserved.
//

import SwiftUI

// MARK: - CheckboxView struct
struct CheckboxView<Content: View>: View {
    @Binding var isChecked: Bool
    private let style: Checkbox.Style
    private let alignment: VerticalAlignment
    private let content: Content
    
    init(
        isChecked: Binding<Bool>,
        style: Checkbox.Style = .default,
        alignment: VerticalAlignment = .center,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._isChecked = isChecked
        self.style = style
        self.alignment = alignment
        self.content = content()
    }
    
    var body: some View {
        HStack(alignment: alignment) {
            Checkbox(isChecked: $isChecked, style: style)
            
            content
                .onTapGesture {
                    isChecked.toggle()
                }
                .accessibilityAction {
                    isChecked.toggle()
                }
        }
    }
}

// MARK: - Checkbox struct
struct Checkbox: View {
    @Binding var isChecked: Bool
    private let style: Checkbox.Style
    
    init(isChecked: Binding<Bool>, style: Style = .default) {
        self._isChecked = isChecked
        self.style = style
    }
    
    var body: some View {
        ImageButton(type: .asset(isChecked ? style.checkedIcon : style.uncheckedIcon)) {
            isChecked.toggle()
        }
        .frame(width: Constants.size, height: Constants.size)
        .accessibility(label: Text(LocalizedString.Checkbox.accessibilityLabel))
        .accessibility(
            value: Text(isChecked ? LocalizedString.Checkbox.checked : LocalizedString.Checkbox.unchecked)
        )
    }
}

// MARK: - Checkbox.Style enum
extension Checkbox {
    enum Style: String {
        /// Appearance: white border (unchecked) or white fill w/ blue check (checked).
        /// Use this style on a `blue500` background.
        case lightContent
        /// Appearance: black border (unchecked) or blue fill w/ white check (checked).
        /// Use this style on a white background.
        case `default`
        
        var checkedIcon: ImageAsset {
            switch self {
            case .default: return Assets.Icons.checkOn
            case .lightContent: return Assets.Icons.lightCheckOn
            }
        }
        
        var uncheckedIcon: ImageAsset {
            switch self {
            case .default: return Assets.Icons.checkOff
            case .lightContent: return Assets.Icons.lightCheckOff
            }
        }
    }
}

// MARK: - Checkbox.Constants
private extension Checkbox {
    enum Constants {
        static let size: CGFloat = 24
    }
}

// MARK: - Previews
struct CheckboxView_Previews: PreviewProvider {
    struct CheckboxViewHolder: View {
        @State var isChecked = false

        var body: some View {
            VStack {
                ZStack(alignment: .leading) {
                    Color.white
                    
                    CheckboxView(isChecked: $isChecked) {
                        labelText(for: .default)
                            .foregroundColor(.blue500)
                            .fontWeight(.medium)
                    }
                    .padding()
                }
                .frame(height: 100)
                
                ZStack(alignment: .leading) {
                    Color.blue500
                    
                    CheckboxView(isChecked: $isChecked, style: .lightContent) {
                        labelText(for: .lightContent)
                            .foregroundColor(.white)
                            .fontWeight(.medium)
                    }
                    .padding()
                }
                .frame(height: 100)
            }
        }
        
        private func labelText(for style: Checkbox.Style) -> Text {
            Text("\(isChecked ? "checked" : "unchecked") \(style.rawValue) style")
        }
    }

    static var previews: some View {
        CheckboxViewHolder()
    }
}
