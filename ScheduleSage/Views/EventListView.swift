import SwiftUI

// 日程列表页
struct EventListView: View {
    // MARK: - Properties
    let proStatus: ProStatus
    let events: [Event]
    let onUpgrade: () -> Void
    let onAdd: () -> Void
    let onImport: () -> Void
    let onBack: () -> Void
    
    @State private var selectedEventIds: Set<String> = []
    
    // MARK: - Initialization
    init(
        proStatus: ProStatus,
        events: [Event],
        onUpgrade: @escaping () -> Void,
        onAdd: @escaping () -> Void,
        onImport: @escaping () -> Void,
        onBack: @escaping () -> Void
    ) {
        self.proStatus = proStatus
        self.events = events
        self.onUpgrade = onUpgrade
        self.onAdd = onAdd
        self.onImport = onImport
        self.onBack = onBack
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // 导航栏
            navigationBar
            
            // 主要内容区域
            VStack(spacing: ScheduleDesignSystem.Dimensions.listContentSpacing) {
                // 列表头部
                listHeaderView
                
                // 事件列表
                eventListContent
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
    }
    
    // MARK: - Private Views
    private var navigationBar: some View {
        HStack {
            // 返回按钮
            Button(action: onBack) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                    Text(NSLocalizedString("back_to_add", comment: ""))
                        .font(ScheduleDesignSystem.Typography.navigationText)
                }
                .foregroundColor(ScheduleDesignSystem.Colors.primary)
            }
            .buttonStyle(.plain)
            .withHoverEffect()
            
            Spacer()
            
            // Pro 状态
            ProStatusView(
                status: proStatus,
                onUpgrade: onUpgrade,
                style: .compact
            )
        }
        .frame(height: ScheduleDesignSystem.Dimensions.headerHeight)
        .padding(.horizontal, ScheduleDesignSystem.Layout.statusBarPadding.leading)
        .padding(.top, ScheduleDesignSystem.Layout.statusBarPadding.top)
        .padding(.bottom, ScheduleDesignSystem.Layout.statusBarPadding.bottom)
        .background(ScheduleDesignSystem.Colors.background)
    }
    
    private var eventListContent: some View {
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
    
    private var listHeaderView: some View {
        HStack {
            Text(String(format: NSLocalizedString("detected_events", comment: ""), events.count))
                .font(ScheduleDesignSystem.Typography.eventCount)
                .foregroundColor(ScheduleDesignSystem.Colors.secondaryText)
        }
        .frame(height: ScheduleDesignSystem.Dimensions.listHeaderHeight)
    }
    
    private var importButton: some View {
        Button(action: onImport) {
            Text(NSLocalizedString("import_calendar", comment: ""))
                .font(ScheduleDesignSystem.Typography.buttonLabel)
                .foregroundColor(ScheduleDesignSystem.Colors.background)
                .frame(maxWidth: .infinity)
                .frame(height: ScheduleDesignSystem.Dimensions.buttonHeight)
                .background(ScheduleDesignSystem.Colors.primary)
                .cornerRadius(ScheduleDesignSystem.Dimensions.buttonCornerRadius)
        }
        .buttonStyle(.plain)
        .withHoverEffect()
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
            proStatus: .free(remainingUses: 12),
            events: PreviewData.events,
            onUpgrade: {},
            onAdd: {},
            onImport: {},
            onBack: {}
        )
    }
}
#endif 
