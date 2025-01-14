//
//  EventListView.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import SwiftUI

/**
 日程列表页
 */
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

  // MARK: - Initialization
  init(
    proStatus: ProStatus,
    events: [CalendarEvent],
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
    .toast(
      isPresented: $showToast,
      type: toastType,
      message: toastMessage,
      duration: 2.0
    )
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

  private var listHeaderView: some View {
    HStack {
      Text(String(format: NSLocalizedString("detected_events", comment: ""), events.count))
        .font(ScheduleDesignSystem.Typography.eventCount)
        .foregroundColor(ScheduleDesignSystem.Colors.secondaryText)
    }
    .frame(height: ScheduleDesignSystem.Dimensions.listHeaderHeight)
  }

  private var importButton: some View {
    Button(action: {
      showImportToast()
      onImport()
    }) {
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
  private func toggleEventSelection(_ eventIdentifier: String) {
    if selectedEventIds.contains(eventIdentifier) {
      selectedEventIds.remove(eventIdentifier)
    } else {
      selectedEventIds.insert(eventIdentifier)
    }
  }

  private func showImportToast() {
    // 先隐藏之前的 Toast（如果有）
    showToast = false
    
    // 延迟一帧后显示新的 Toast，确保动画正确
    DispatchQueue.main.async {
      toastType = .success
      toastMessage = NSLocalizedString("import_started", comment: "")
      showToast = true
    }
  }

  private func updateToastForImportStatus(_ status: PopoverViewModel.ImportStatus) {
    showToast = false
    
    DispatchQueue.main.async {
      switch status {
      case .success:
        toastType = .success
        toastMessage = NSLocalizedString("import_success", comment: "")
      case .failure(let error):
        toastType = .error
        toastMessage = error.localizedDescription
      case .importing:
        toastType = .success
        toastMessage = NSLocalizedString("import_in_progress", comment: "")
      case .none:
        return
      }
      showToast = true
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
