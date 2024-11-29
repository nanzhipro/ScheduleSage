import SwiftUI

// 日程列表页
struct EventListView: View {
    // MARK: - Properties
    let remainingUses: Int
    let events: [Event]
    let onUpgrade: () -> Void
    let onAdd: () -> Void
    let onImport: () -> Void
    
    @State private var selectedEventIds: Set<String> = []
    
    // MARK: - Initialization
    init(
        remainingUses: Int,
        events: [Event],
        onUpgrade: @escaping () -> Void,
        onAdd: @escaping () -> Void,
        onImport: @escaping () -> Void
    ) {
        self.remainingUses = remainingUses
        self.events = events
        self.onUpgrade = onUpgrade
        self.onAdd = onAdd
        self.onImport = onImport
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // 顶部状态栏
            statusBar
            
            // 主要内容区域
            VStack(spacing: ScheduleDesignSystem.Dimensions.listContentSpacing) {
                // 列表头部
                listHeaderView
                
                // 事件列表
                ScrollView {
                    LazyVStack(spacing: ScheduleDesignSystem.Dimensions.eventCardSpacing) {
                        ForEach(events) { event in
                            EventCard(
                                title: event.title,
                                time: event.time,
                                location: event.location,
                                isRecurring: event.isRecurring,
                                calendar: event.calendar,
                                isSelected: selectedEventIds.contains(event.id)
                            ) {
                                toggleEventSelection(event.id)
                            }
                        }
                    }
                    .padding(.bottom, ScheduleDesignSystem.Spacing.vertical)
                }
            }
            .padding(.horizontal, ScheduleDesignSystem.Spacing.listContentPadding)
            .padding(.vertical, ScheduleDesignSystem.Dimensions.listVerticalPadding)
            .background(ScheduleDesignSystem.Colors.containerGray)
            
            // 导入按钮
            importButton
        }
        .frame(
            width: ScheduleDesignSystem.Dimensions.containerWidth,
            height: ScheduleDesignSystem.Dimensions.containerHeight
        )
        .background(ScheduleDesignSystem.Colors.background)
        .cornerRadius(ScheduleDesignSystem.Dimensions.containerCornerRadius)
    }
    
    // MARK: - Private Views
    private var statusBar: some View {
        HStack {
            // Pro 状态
            HStack(spacing: ScheduleDesignSystem.Spacing.elementSpacing) {
                ZStack {
                    Circle()
                        .fill(ScheduleDesignSystem.Colors.lightGray)
                        .frame(
                            width: ScheduleDesignSystem.Dimensions.crownIconSize,
                            height: ScheduleDesignSystem.Dimensions.crownIconSize
                        )
                    Image(systemName: "crown")
                        .foregroundColor(ScheduleDesignSystem.Colors.secondaryGray)
                }
                Text(String(format: NSLocalizedString("remaining_uses", comment: ""), remainingUses))
                    .font(ScheduleDesignSystem.Typography.statusText)
                    .foregroundColor(ScheduleDesignSystem.Colors.secondaryText)
                Text(NSLocalizedString("separator", comment: ""))
                    .font(ScheduleDesignSystem.Typography.statusText)
                    .foregroundColor(ScheduleDesignSystem.Colors.secondaryText)
                Text(NSLocalizedString("upgrade_prompt", comment: ""))
                    .font(ScheduleDesignSystem.Typography.statusText)
                    .foregroundColor(ScheduleDesignSystem.Colors.primaryBlue)
                    .onTapGesture(perform: onUpgrade)
            }
            .padding(.leading, ScheduleDesignSystem.Spacing.headerHorizontalPadding)
            
            Spacer()
            
            // 添加按钮
            Button(action: {
                print("Add schedule button tapped")
            }) {
                Image(systemName: "plus")
                    .foregroundColor(ScheduleDesignSystem.Colors.background)
                    .frame(
                        width: ScheduleDesignSystem.Dimensions.addButtonSize,
                        height: ScheduleDesignSystem.Dimensions.addButtonSize
                    )
                    .background(ScheduleDesignSystem.Colors.primaryBlue)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(.trailing, ScheduleDesignSystem.Spacing.headerHorizontalPadding)
        }
        .frame(height: ScheduleDesignSystem.Dimensions.headerHeight)
        .background(ScheduleDesignSystem.Colors.background)
    }
    
    private var listHeaderView: some View {
        Text(String(format: NSLocalizedString("detected_events", comment: ""), events.count))
            .font(ScheduleDesignSystem.Typography.eventCount)
            .foregroundColor(ScheduleDesignSystem.Colors.secondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: ScheduleDesignSystem.Dimensions.listHeaderHeight)
    }
    
    private var importButton: some View {
        Button(action: onImport) {
            Text(NSLocalizedString("import_calendar", comment: ""))
                .font(ScheduleDesignSystem.Typography.buttonLabel)
                .foregroundColor(ScheduleDesignSystem.Colors.background)
                .frame(maxWidth: .infinity)
                .frame(height: ScheduleDesignSystem.Dimensions.buttonHeight)
                .background(ScheduleDesignSystem.Colors.primaryBlue)
                .cornerRadius(ScheduleDesignSystem.Dimensions.buttonCornerRadius)
        }
        .buttonStyle(.plain)
        .padding(ScheduleDesignSystem.Layout.containerPadding)
    }
    
    // MARK: - Private Methods
    private func toggleEventSelection(_ id: String) {
        if selectedEventIds.contains(id) {
            selectedEventIds.remove(id)
        } else {
            selectedEventIds.insert(id)
        }
    }
}

// MARK: - Preview
#if DEBUG
struct EventListView_Previews: PreviewProvider {
    static var previews: some View {
        EventListView(
            remainingUses: 12,
            events: PreviewData.events,
            onUpgrade: {},
            onAdd: {},
            onImport: {}
        )
    }
}
#endif 
