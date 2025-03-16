//
//  EventListView.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import SwiftUI

/// 事件列表视图 | 日程列表
struct EventListView: View {
  // MARK: - Properties
  let events: [CalendarEvent]
  let onAdd: () -> Void
  let onImport: (Set<String>) -> Void
  let onBack: () -> Void
  let onUpdate: (CalendarEvent) -> Void
  let viewModel: AddScheduleViewModel

  @State private var selectedEventIds: Set<String> = []
  @State private var showToast = false
  @State private var toastType: ToastType = .success
  @State private var toastMessage: String = ""
  @State private var displayEvents: [CalendarEvent]
  @State private var needsRefresh = false

  private var hasSelectedEvents: Bool { !selectedEventIds.isEmpty }
  private var allEventsSelected: Bool { selectedEventIds.count == displayEvents.count && !displayEvents.isEmpty }

  init(events: [CalendarEvent], onAdd: @escaping () -> Void, onImport: @escaping (Set<String>) -> Void, onBack: @escaping () -> Void, onUpdate: @escaping (CalendarEvent) -> Void, viewModel: AddScheduleViewModel) {
    self.events = events
    self.onAdd = onAdd
    self.onImport = onImport
    self.onBack = onBack
    self.onUpdate = onUpdate
    self.viewModel = viewModel
    _displayEvents = State(initialValue: events)
  }

  // MARK: - Body
  var body: some View {
    VStack(spacing: 0) {
      compactHeaderView
      contentArea
      listHeader
      importButton
    }
    .frame(
      width: DesignSystem.Dimensions.mainViewWidth * 0.8,   // 800 * 0.8 = 640
      height: DesignSystem.Dimensions.mainViewHeight * 0.8  // 640 * 0.8 = 512
    )
    .background(DesignSystem.Colors.background)
    .cornerRadius(DesignSystem.Dimensions.containerCornerRadius)
    .toast(
      isPresented: $showToast,
      type: toastType,
      message: toastMessage,
      duration: 2.0
    )
    .onAppear {
      // 默认全选所有事件
      selectAllEvents()
    }
    .onReceive(NotificationCenter.default.publisher(for: .eventDidUpdate)) { notification in
      if let updatedEvent = notification.userInfo?["event"] as? CalendarEvent {
        handleEventUpdate(updatedEvent)
      }
    }
    .onChange(of: viewModel.importStatus) { newStatus in
      handleImportStatusChange(newStatus)
    }
    .id(needsRefresh)
    .onReceive(NotificationCenter.default.publisher(for: .themeDidChange)) { _ in
      needsRefresh.toggle()
    }
  }

  // MARK: - Event Update Handler
  private func handleEventUpdate(_ updatedEvent: CalendarEvent) {
    if let index = displayEvents.firstIndex(where: { $0.eventIdentifier == updatedEvent.eventIdentifier }) {
      displayEvents[index] = updatedEvent
      toastType = .success
      toastMessage = NSLocalizedString("update_success", comment: "")
      showToast = true
    }
  }
  
  // MARK: - Import Status Handler
  private func handleImportStatusChange(_ status: AddScheduleViewModel.ImportStatus) {
    switch status {
    case .success:
      toastType = .success
      toastMessage = NSLocalizedString("import_success", comment: "")
      showToast = true
      
      Task {
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        await MainActor.run {
          onBack()
        }
      }
    case .failure(let error):
      toastType = .error
      toastMessage = error.localizedDescription
      showToast = true
    case .importing, .none:
      break
    }
  }
  
  // MARK: - Compact Header View
  private var compactHeaderView: some View {
    HStack {
      Text(NSLocalizedString("event_list_title", comment: ""))
        .font(DesignSystem.Typography.largeHeaderTitle)
        .foregroundColor(DesignSystem.Colors.primaryText)
        .padding(.leading, 20)
      
      Spacer()
      
      SageCloseButton(action: onBack)
        .padding(.trailing, 20)
    }
    .padding(.vertical, 16)
    .background(DesignSystem.Colors.background)
  }
}

// MARK: - View Components
private extension EventListView {
  var contentArea: some View {
    VStack(spacing: DesignSystem.Dimensions.listContentSpacing) {
      eventListView
    }
    .padding(.horizontal, DesignSystem.Spacing.listContentPadding)
    .padding(.vertical, DesignSystem.Dimensions.listVerticalPadding)
    .background(DesignSystem.Colors.containerGray)
  }
  
  var listHeader: some View {
    HStack {
      // 左侧：事件计数信息
      HStack(spacing: 4) {
        Text(String(format: NSLocalizedString("detected_events", comment: ""), displayEvents.count))
          .font(DesignSystem.Typography.eventCount)
          .foregroundColor(DesignSystem.Colors.secondaryText)
        
        if hasSelectedEvents {
          Text("·").foregroundColor(DesignSystem.Colors.secondaryText)
          Text(String(format: NSLocalizedString("selected_events", comment: ""), selectedEventIds.count))
            .font(DesignSystem.Typography.eventCount)
            .foregroundColor(DesignSystem.Colors.secondaryText)
        }
      }
      
      Spacer()
      
      // 右侧：全选/全不选按钮
      HStack(spacing: 12) {
        // 全选按钮
        Button(action: selectAllEvents) {
          Text(NSLocalizedString("select_all", comment: ""))
            .font(DesignSystem.Typography.eventCount)
            .foregroundColor(allEventsSelected ? DesignSystem.Colors.secondaryText : DesignSystem.Colors.primary)
        }
        .buttonStyle(.plain)
        .disabled(allEventsSelected || displayEvents.isEmpty)
        
        // 全不选按钮
        Button(action: deselectAllEvents) {
          Text(NSLocalizedString("deselect_all", comment: ""))
            .font(DesignSystem.Typography.eventCount)
            .foregroundColor(hasSelectedEvents ? DesignSystem.Colors.primary : DesignSystem.Colors.secondaryText)
        }
        .buttonStyle(.plain)
        .disabled(!hasSelectedEvents)
      }
    }
    .frame(height: DesignSystem.Dimensions.listHeaderHeight)
    .padding(.horizontal, DesignSystem.Spacing.listContentPadding)
  }
  
  var eventListView: some View {
    ScrollView {
      LazyVStack(spacing: DesignSystem.Dimensions.eventCardSpacing) {
        ForEach(displayEvents) { event in
          EventCard(
            calendarEvent: event,
            isSelected: selectedEventIds.contains(event.eventIdentifier),
            onSelect: { toggleSelection(for: event) },
            onDelete: { deleteEvent(event) },
            onUpdate: onUpdate
          )
        }
      }
      .padding(.bottom, DesignSystem.Spacing.vertical)
    }
  }
  
  var importButton: some View {
    Button(action: handleImport) {
      Text(NSLocalizedString("import_calendar", comment: ""))
        .font(DesignSystem.Typography.buttonLabel)
        .foregroundColor(DesignSystem.Colors.background)
        .frame(
          maxWidth: .infinity,
          minHeight: DesignSystem.Dimensions.buttonHeight
        )
        .background(buttonBackground)
        .cornerRadius(DesignSystem.Dimensions.buttonCornerRadius)
    }
    .buttonStyle(.plain)
    .withHoverEffect(
      scale: hasSelectedEvents ? 1.02 : 1.0,
      brightness: hasSelectedEvents ? 0.05 : 0
    )
    .disabled(!hasSelectedEvents)
    .padding(DesignSystem.Layout.containerPadding)
  }
  
  var buttonBackground: some View {
    DesignSystem.Colors.primary
      .opacity(hasSelectedEvents ? 1 : 0.5)
  }
  
  // MARK: - Selection Actions
  
  /// 全选所有事件
  func selectAllEvents() {
    for event in displayEvents {
      selectedEventIds.insert(event.eventIdentifier)
    }
  }
  
  /// 取消选择所有事件
  func deselectAllEvents() {
    selectedEventIds.removeAll()
  }
}

// MARK: - Actions
private extension EventListView {
  private func handleImport() {
    guard hasSelectedEvents else { return }
    
    onImport(selectedEventIds)
  }
  
  func toggleSelection(for event: CalendarEvent) {
    if selectedEventIds.contains(event.eventIdentifier) {
      selectedEventIds.remove(event.eventIdentifier)
    } else {
      selectedEventIds.insert(event.eventIdentifier)
    }
  }
  
  func deleteEvent(_ eventToDelete: CalendarEvent) {
    withAnimation(.easeInOut(duration: 0.3)) {
      displayEvents.removeAll { existingEvent in
        existingEvent.eventIdentifier == eventToDelete.eventIdentifier
      }
      selectedEventIds.remove(eventToDelete.eventIdentifier)
      
      toastType = .success
      toastMessage = NSLocalizedString("delete_success", comment: "")
      showToast = true
      
      if displayEvents.isEmpty {
        Task {
          try? await Task.sleep(nanoseconds: 1_000_000_000)
          await MainActor.run {
            onBack()
          }
        }
      }
    }
  }
}

// MARK: - Preview
#if DEBUG
struct EventListView_Previews: PreviewProvider {
  // 创建一个预览专用的 mock AddScheduleViewModel
  private class MockAddScheduleViewModel: AddScheduleViewModel {
    override init() {
      // 使用空实现避免依赖问题
      super.init()
    }
  }
  
  static var previews: some View {
    Group {
      // 亮色模式预览
      EventListView(
        events: PreviewData.mockCalendarEvents,
        onAdd: {},
        onImport: { _ in },
        onBack: {},
        onUpdate: { _ in },
        viewModel: MockAddScheduleViewModel()
      )
      .previewDisplayName("Light Mode")
      
      // 暗色模式预览
      EventListView(
        events: PreviewData.mockCalendarEvents,
        onAdd: {},
        onImport: { _ in },
        onBack: {},
        onUpdate: { _ in },
        viewModel: MockAddScheduleViewModel()
      )
      .preferredColorScheme(.dark)
      .previewDisplayName("Dark Mode")
      
      // 空列表预览
      EventListView(
        events: [],
        onAdd: {},
        onImport: { _ in },
        onBack: {},
        onUpdate: { _ in },
        viewModel: MockAddScheduleViewModel()
      )
      .previewDisplayName("Empty State")
    }
    .frame(width: 500, height: 700)
    .background(Color.gray.opacity(0.1))
    .padding()
  }
}
#endif
