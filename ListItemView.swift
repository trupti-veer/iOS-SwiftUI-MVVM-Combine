//
//  ListItemView.swift
//
//
//  Created by Trupti Veer on 31/05/21.
//  Copyright © 2021. All rights reserved.
//

import SwiftUI

struct AccountList<Data>: View where Data: RandomAccessCollection, Data.Element: ListItem & Hashable {
    let title: String?
    let data: Data
    let onTap: (Data.Element) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            if let title = title {
                ListHeader(title: title)
            }
            
            ForEach(data, id: \.self) { item in
                ListItemView(item: item)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onTap(item)
                    }
                
                Appearance.separator
            }
        }
        .padding(.horizontal, Appearance.Dimensions.contentPadding)
        .background(Color.white)
    }
}

struct ListItemView<Item: ListItem>: View {
    let item: Item

    var body: some View {
        HStack(spacing: Spacer.small.rawValue) {
            Image(item.icon.name)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Dimensions.iconSize, height: Dimensions.iconSize)
                            
            Text(item.title)
                .Font(.h4)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .renderingMode(.template)
                .font(.system(size: 16, weight: .semibold))
        }
        .foregroundColor(.accessibleGrayBlack)
        .frame(height: Spacer.xxxLarge.rawValue)
    }
}

// MARK: - Constants
private enum Dimensions {
    static let iconSize: CGFloat = 20
}

struct ListHeader: View {
    var title: String
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Text(title)
                    .Font(.b2, color: .gray)
                
                Spacer()
            }
            
            Spacer()
        }
        .frame(height: 44)
    }
}
