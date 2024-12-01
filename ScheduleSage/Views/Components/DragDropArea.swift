import SwiftUI

struct DragDropArea<Content: View>: View {
    let content: Content
    @Binding var isDragging: Bool
    @Binding var isOCRProcessing: Bool
    let onDrop: ([URL]) -> Void
    let onDragEntered: () -> Void
    let onDragExited: () -> Void
    
    init(
        isDragging: Binding<Bool>,
        isOCRProcessing: Binding<Bool>,
        onDrop: @escaping ([URL]) -> Void,
        onDragEntered: @escaping () -> Void,
        onDragExited: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self._isDragging = isDragging
        self._isOCRProcessing = isOCRProcessing
        self.onDrop = onDrop
        self.onDragEntered = onDragEntered
        self.onDragExited = onDragExited
    }
    
    var body: some View {
        ZStack {
            // 背景和内容
            content
            
            // 虚线边框
            RoundedRectangle(cornerRadius: ScheduleDesignSystem.Dimensions.cardCornerRadius)
                .strokeBorder(
                    style: StrokeStyle(
                        lineWidth: 2,
                        dash: [4, 4]
                    )
                )
                .foregroundColor(isDragging ? 
                    ScheduleDesignSystem.Colors.primary : 
                    ScheduleDesignSystem.Colors.borderGray)
                .padding(.horizontal, ScheduleDesignSystem.Layout.containerPadding.leading)
                .padding(.top, ScheduleDesignSystem.Layout.containerPadding.top)
                .padding(.bottom, ScheduleDesignSystem.Layout.containerPadding.bottom + ScheduleDesignSystem.Dimensions.buttonHeight + 16)
                .animation(.easeInOut(duration: 0.3), value: isDragging)
        }
        .background(ScheduleDesignSystem.Colors.containerGray)
        .onDrop(
            of: [.fileURL],
            delegate: ImageDropDelegate(
                onDrop: onDrop,
                onEntered: onDragEntered,
                onExited: onDragExited,
                onOCRStateChange: { processing in
                    isOCRProcessing = processing
                }
            )
        )
    }
} 