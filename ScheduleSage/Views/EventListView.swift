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

  @State private var selectedEventIds: Set<String> = []
  @State private var showToast = false
  @State private var toastType: ToastType = .success
  @State private var toastMessage: String = ""
  @State private var displayEvents: [CalendarEvent]
  @State private var needsRefresh = false

  private var hasSelectedEvents: Bool { !selectedEventIds.isEmpty }

  init(events: [CalendarEvent], onAdd: @escaping () -> Void, onImport: @escaping (Set<String>) -> Void, onBack: @escaping () -> Void, onUpdate: @escaping (CalendarEvent) -> Void) {
    self.events = events
    self.onAdd = onAdd
    self.onImport = onImport
    self.onBack = onBack
    self.onUpdate = onUpdate
    _displayEvents = State(initialValue: events)
  }

  // MARK: - Body
  var body: some View {
    VStack(spacing: 0) {
      HeaderView(onBack: onBack)
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
      if let firstEvent = events.first {
        selectedEventIds.insert(firstEvent.eventIdentifier)
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: .eventDidUpdate)) { notification in
      if let updatedEvent = notification.userInfo?["event"] as? CalendarEvent {
        handleEventUpdate(updatedEvent)
      }
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
}

// MARK: - Header View
private struct HeaderView: View {
  let onBack: () -> Void
  
  var body: some View {
    VStack(alignment: .leading, spacing: DesignSystem.Spacing.largeHeaderSpacing) {
      HStack(spacing: DesignSystem.Spacing.iconSpacing) {
        Text(NSLocalizedString("event_list_title", comment: ""))
          .font(DesignSystem.Typography.largeHeaderTitle)
          .foregroundColor(DesignSystem.Colors.primaryText)
        Spacer()
        SageCloseButton(action: onBack)
      }
      
      Text(NSLocalizedString("event_list_subtitle", comment: ""))
        .font(DesignSystem.Typography.largeHeaderSubtitle)
        .foregroundColor(DesignSystem.Colors.secondaryText)
        .lineLimit(2)
    }
    .padding(.horizontal, DesignSystem.Layout.largeContainerPadding.leading)
    .padding(.top, DesignSystem.Layout.largeContainerPadding.top)
    .padding(.bottom, DesignSystem.Spacing.sectionSpacing)
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
}

// MARK: - Actions
private extension EventListView {
  private func handleImport() {
    guard hasSelectedEvents else { return }
    
    // 传递选中的事件ID
    onImport(selectedEventIds)
    
    // 显示成功提示
    toastType = .success
    toastMessage = NSLocalizedString("import_success", comment: "")
    showToast = true
    
    // 2秒后关闭视图
    Task {
      try? await Task.sleep(nanoseconds: 2_000_000_000)
      await MainActor.run {
        onBack()  // 关闭视图
      }
    }
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
      
      // 显示删除成功提示
      toastType = .success
      toastMessage = NSLocalizedString("delete_success", comment: "")
      showToast = true
      
      // 如果删除后列表为空，则返回到主界面
      if displayEvents.isEmpty {
        // 延迟一小段时间以便用户看到删除成功的提示
        Task {
          try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
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
  static var previews: some View {
    Group {
      // 亮色模式预览
      EventListView(
        events: PreviewData.mockCalendarEvents,
        onAdd: {},
        onImport: { _ in },
        onBack: {},
        onUpdate: { _ in }
      )
      .previewDisplayName("Light Mode")
      
      // 暗色模式预览
      EventListView(
        events: PreviewData.mockCalendarEvents,
        onAdd: {},
        onImport: { _ in },
        onBack: {},
        onUpdate: { _ in }
      )
      .preferredColorScheme(.dark)
      .previewDisplayName("Dark Mode")
      
      // 空列表预览
      EventListView(
        events: [],
        onAdd: {},
        onImport: { _ in },
        onBack: {},
        onUpdate: { _ in }
      )
      .previewDisplayName("Empty State")
    }
    .frame(width: 500, height: 700)
    .background(Color.gray.opacity(0.1))
    .padding()
  }
}
#endif
