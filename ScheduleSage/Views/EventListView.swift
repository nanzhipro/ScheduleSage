//
//  EventListView.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import SwiftUI

struct EventListView: View {
  // MARK: - Properties
  let proStatus: ProStatus
  let events: [CalendarEvent]
  let onUpgrade: () -> Void
  let onAdd: () -> Void
  let onImport: () -> Void
  let onBack: () -> Void

  @State private var selectedEventIds: Set<String> = []
  @State private var showToast = false
  @State private var toastType: ToastType = .success
  @State private var toastMessage: String = ""

  private var hasSelectedEvents: Bool { !selectedEventIds.isEmpty }

  // MARK: - Body
  var body: some View {
    VStack(spacing: 0) {
      navigationBar
      contentArea
      importButton
    }
    .frame(
      width: ScheduleDesignSystem.Dimensions.containerWidth,
      height: ScheduleDesignSystem.Dimensions.containerHeight
    )
    .background(ScheduleDesignSystem.Colors.background)
    .toast(
      isPresented: $showToast,
      type: toastType,
      message: toastMessage,
      duration: 2.0
    )
    .onAppear {
      // 如果有日程，默认选中第一个
      if let firstEvent = events.first {
        selectedEventIds.insert(firstEvent.eventIdentifier)
      }
    }
  }
}

// MARK: - View Components
private extension EventListView {
  var navigationBar: some View {
    HStack {
      backButton
      Spacer()
      proStatusView
    }
    .frame(height: ScheduleDesignSystem.Dimensions.headerHeight)
    .padding(.horizontal, ScheduleDesignSystem.Layout.statusBarPadding.leading)
    .padding(.vertical, ScheduleDesignSystem.Layout.statusBarPadding.top)
    .background(ScheduleDesignSystem.Colors.background)
  }
  
  var backButton: some View {
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
  }
  
  var proStatusView: some View {
    ProStatusView(
      status: proStatus,
      onUpgrade: onUpgrade,
      style: .compact
    )
  }
  
  var contentArea: some View {
    VStack(spacing: ScheduleDesignSystem.Dimensions.listContentSpacing) {
      listHeader
      eventList
    }
    .padding(.horizontal, ScheduleDesignSystem.Spacing.listContentPadding)
    .padding(.vertical, ScheduleDesignSystem.Dimensions.listVerticalPadding)
    .background(ScheduleDesignSystem.Colors.containerGray)
  }
  
  var listHeader: some View {
    HStack {
      Text(String(format: NSLocalizedString("detected_events", comment: ""), events.count))
        .font(ScheduleDesignSystem.Typography.eventCount)
        .foregroundColor(ScheduleDesignSystem.Colors.secondaryText)
      
      if hasSelectedEvents {
        Text("·").foregroundColor(ScheduleDesignSystem.Colors.secondaryText)
        Text(String(format: NSLocalizedString("selected_events", comment: ""), selectedEventIds.count))
          .font(ScheduleDesignSystem.Typography.eventCount)
          .foregroundColor(ScheduleDesignSystem.Colors.secondaryText)
      }
    }
    .frame(height: ScheduleDesignSystem.Dimensions.listHeaderHeight)
  }
  
  var eventList: some View {
    ScrollView {
      LazyVStack(spacing: ScheduleDesignSystem.Dimensions.eventCardSpacing) {
        ForEach(events) { event in
          EventCard(
            title: event.title,
            time: event.time,
            location: event.location,
            calendar: event.calendar,
            isSelected: selectedEventIds.contains(event.eventIdentifier)
          ) {
            toggleEventSelection(event.eventIdentifier)
          }
        }
      }
      .padding(.bottom, ScheduleDesignSystem.Spacing.vertical)
    }
  }
  
  var importButton: some View {
    Button(action: handleImport) {
      Text(NSLocalizedString("import_calendar", comment: ""))
        .font(ScheduleDesignSystem.Typography.buttonLabel)
        .foregroundColor(ScheduleDesignSystem.Colors.background)
        .frame(
          maxWidth: .infinity,
          minHeight: ScheduleDesignSystem.Dimensions.buttonHeight
        )
        .background(buttonBackground)
        .cornerRadius(ScheduleDesignSystem.Dimensions.buttonCornerRadius)
    }
    .buttonStyle(.plain)
    .withHoverEffect(
      scale: hasSelectedEvents ? 1.02 : 1.0,
      brightness: hasSelectedEvents ? 0.05 : 0
    )
    .disabled(!hasSelectedEvents)
    .padding(ScheduleDesignSystem.Layout.containerPadding)
  }
  
  var buttonBackground: some View {
    ScheduleDesignSystem.Colors.primary
      .opacity(hasSelectedEvents ? 1 : 0.5)
  }
}

// MARK: - Actions
private extension EventListView {
  func handleImport() {
    guard hasSelectedEvents else { return }
    showImportStartedToast()
    onImport()
  }
  
  func toggleEventSelection(_ eventIdentifier: String) {
    if selectedEventIds.contains(eventIdentifier) {
      selectedEventIds.remove(eventIdentifier)
    } else {
      selectedEventIds.insert(eventIdentifier)
    }
  }
  
  func showImportStartedToast() {
    showToast = false
    DispatchQueue.main.async {
      toastType = .success
      toastMessage = NSLocalizedString("import_success", comment: "")
      showToast = true
      
      // 2秒后显示导入成功提示
      DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
        toastType = .success
        toastMessage = NSLocalizedString("import_success", comment: "")
        showToast = true
      }
    }
  }
}

// MARK: - Preview
#if DEBUG
struct EventListView_Previews: PreviewProvider {
  static var previews: some View {
    EventListView(
      proStatus: .free(remainingUses: 12),
      events: [],
      onUpgrade: {},
      onAdd: {},
      onImport: {},
      onBack: {}
    )
  }
}
#endif
