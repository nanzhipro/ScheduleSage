//
//  AddMethodButton.swift
//  ScheduleSage
//
//  Created by 南朋友 on 2024/03/26.
//

import SwiftUI

struct AddMethodButton: View {
    let icon: String
    let text: String
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        isHovered ? 
                            ScheduleDesignSystem.Colors.lightGray.opacity(0.8) :
                            ScheduleDesignSystem.Colors.lightGray
                    )
                    .frame(
                        width: ScheduleDesignSystem.Dimensions.methodIconSize,
                        height: ScheduleDesignSystem.Dimensions.methodIconSize
                    )
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(
                        isHovered ?
                            ScheduleDesignSystem.Colors.primary :
                            ScheduleDesignSystem.Colors.iconGray
                    )
            }
            Text(text)
                .font(ScheduleDesignSystem.Typography.methodLabel)
                .foregroundColor(ScheduleDesignSystem.Colors.secondaryText)
        }
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#if DEBUG
struct AddMethodButton_Previews: PreviewProvider {
    static var previews: some View {
        AddMethodButton(
            icon: "doc.text.fill",
            text: "从剪贴板导入"
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif 