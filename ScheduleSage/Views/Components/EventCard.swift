//
//  EventCard.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import SwiftUI

// MARK: - Design Constants
private enum Design {
  enum Card {
    static let height: CGFloat = 154
    static let padding = EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
    static let cornerRadius: CGFloat = 12
  }
  
  enum Layout {
    static let iconSpacing: CGFloat = 16
    static let titleSpacing: CGFloat = 8
    static let timeSectionSpacing: CGFloat = 12
    static let timeIconWidth: CGFloat = 24
    static let timeIconSize: CGFloat = 14
    static let iconSize: CGFloat = 32
    static let selectionSize: CGFloat = 16
    static let selectionInnerSize: CGFloat = 8
  }
  
  enum Time {
    static let separatorWidth: CGFloat = 1
    static let separatorHeight: CGFloat = 24
    static let separatorPadding: CGFloat = 4
  }
}

// MARK: - Event Card
struct EventCard: View {
  // MARK: - Properties
  let title: String
  let startDate: Date
  let endDate: Date
  let location: String?
  let calendar: String?
  let isSelected: Bool
  let onSelect: () -> Void
  let onMoreAction: () -> Void
  let onDelete: () -> Void
  
  private var event: CalendarEvent {
    CalendarEvent(
      title: title,
      location: location ?? "",
      notes: "",
      startDate: DateFormatters.standard.string(from: startDate),
      endDate: DateFormatters.standard.string(from: endDate),
      url: "",
      calendar: calendar ?? "",
      status: "normal",
      eventIdentifier: UUID().uuidString,
      remarks: ""
    )
  }
  
  // MARK: - Body
  var body: some View {
    HStack(alignment: .center, spacing: Design.Layout.iconSpacing) {
      CardContent(
        title: title,
        startDate: startDate,
        endDate: endDate,
        location: location,
        calendar: calendar
      )
      
      Spacer(minLength: Design.Layout.iconSpacing)
      
      RightControls(
        isSelected: isSelected,
        onSelect: onSelect,
        onDelete: onDelete,
        event: event
      )
    }
    .padding(Design.Card.padding)
    .frame(height: Design.Card.height)
    .cardStyle()
  }
}

// MARK: - Card Content
private struct CardContent: View {
  let title: String
  let startDate: Date
  let endDate: Date
  let location: String?
  let calendar: String?
  
  var body: some View {
    VStack(alignment: .leading, spacing: Design.Layout.titleSpacing) {
      titleView
      timeSection
      iconLabels
    }
  }
  
  private var titleView: some View {
    Text(title)
      .font(.system(size: 17, weight: .medium))
      .foregroundColor(DesignSystem.Colors.primaryText)
      .lineLimit(1)
  }
  
  private var timeSection: some View {
    TimeSection(startDate: startDate, endDate: endDate)
      .padding(.bottom, Design.Layout.timeSectionSpacing)
  }
  
  private var iconLabels: some View {
    HStack(spacing: Design.Layout.iconSpacing) {
      if let location {
        EventIconLabel(icon: "location.fill", text: location)
      }
      if let calendar {
        EventIconLabel(icon: "calendar", text: calendar)
      }
    }
  }
}

// MARK: - Time Section
private struct TimeSection: View {
  let startDate: Date
  let endDate: Date
  
  var body: some View {
    HStack(alignment: .top, spacing: 0) {
      timeSeparator
      timeLabels
    }
  }
  
  private var timeSeparator: some View {
    VStack {
      Rectangle()
        .fill(DesignSystem.Colors.borderGray)
        .frame(width: Design.Time.separatorWidth, height: Design.Time.separatorHeight)
        .padding(.vertical, Design.Time.separatorPadding)
    }
    .padding(.leading, 4)
  }
  
  private var timeLabels: some View {
    VStack(alignment: .leading, spacing: Design.Layout.titleSpacing) {
      ForEach([startDate, endDate], id: \.self) { date in
        Text(DateFormatters.display.string(from: date))
          .font(DesignSystem.Typography.bodyRegular)
          .foregroundColor(DesignSystem.Colors.primaryText)
      }
    }
    .padding(.leading, Design.Layout.iconSpacing)
  }
}

// MARK: - Icon Label
private struct EventIconLabel: View {
  let icon: String
  let text: String
  
  var body: some View {
    HStack(spacing: Design.Layout.iconSpacing) {
      iconView
      labelText
    }
    .padding(.vertical, 4)
    .background(Color.clear)
    .contentShape(Rectangle())
    .help(text)
  }
  
  private var iconView: some View {
    ZStack {
      Circle()
        .fill(DesignSystem.Colors.lightGray)
        .frame(width: Design.Layout.iconSize, height: Design.Layout.iconSize)
      
      Image(systemName: icon)
        .foregroundColor(DesignSystem.Colors.iconGray)
    }
  }
  
  private var labelText: some View {
    Text(text)
      .font(DesignSystem.Typography.bodyRegular)
      .foregroundColor(DesignSystem.Colors.secondaryText)
      .lineLimit(1)
      .truncationMode(.tail)
  }
}

// MARK: - Right Controls
private struct RightControls: View {
  let isSelected: Bool
  let onSelect: () -> Void
  let onDelete: () -> Void
  let event: CalendarEvent
  
  @State private var isHovering = false
  @State private var showingEditSheet = false
  @State private var currentEvent: CalendarEvent
  
  init(isSelected: Bool, onSelect: @escaping () -> Void, onDelete: @escaping () -> Void, event: CalendarEvent) {
    self.isSelected = isSelected
    self.onSelect = onSelect
    self.onDelete = onDelete
    self.event = event
    _currentEvent = State(initialValue: event)
  }
  
  var body: some View {
    VStack(alignment: .center) {
      Spacer()
      selectionIndicator
      Spacer()
      moreButton
    }
    .sheet(isPresented: $showingEditSheet) {
      EventEditView(
        event: currentEvent,
        onSave: handleEventUpdate,
        onCancel: { showingEditSheet = false }
      )
    }
  }
  
  private var selectionIndicator: some View {
    SelectionIndicator(isSelected: isSelected)
      .onTapGesture(perform: onSelect)
  }
  
  private var moreButton: some View {
    Menu {
      Button(action: { showingEditSheet = true }) {
        Label(NSLocalizedString("edit_event", comment: ""), systemImage: "pencil")
      }
      
      Button(role: .destructive, action: onDelete) {
        Label(NSLocalizedString("delete_event", comment: ""), systemImage: "trash")
      }
    } label: {
      Image(systemName: "ellipsis")
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(DesignSystem.Colors.secondaryText)
        .frame(width: Design.Layout.selectionSize, height: Design.Layout.selectionSize)
        .background(
          Circle()
            .fill(DesignSystem.Colors.secondaryText.opacity(isHovering ? 0.1 : 0))
            .frame(width: Design.Layout.selectionSize + 8, height: Design.Layout.selectionSize + 8)
        )
        .animation(.easeInOut(duration: 0.2), value: isHovering)
    }
    .menuStyle(.borderlessButton)
    .menuIndicator(.hidden)
    .fixedSize()
    .onHover { hovering in
      isHovering = hovering
    }
  }
  
  private func handleEventUpdate(_ updatedEvent: CalendarEvent) {
    currentEvent = updatedEvent
    NotificationCenter.default.post(
      name: .eventDidUpdate,
      object: nil,
      userInfo: ["event": updatedEvent]
    )
    showingEditSheet = false
  }
}

// MARK: - Selection Indicator
private struct SelectionIndicator: View {
  let isSelected: Bool
  
  var body: some View {
    ZStack {
      Circle()
        .fill(DesignSystem.Colors.primary.opacity(0.1))
        .frame(width: Design.Layout.selectionSize, height: Design.Layout.selectionSize)
      
      if isSelected {
        Circle()
          .fill(DesignSystem.Colors.primary)
          .frame(width: Design.Layout.selectionInnerSize, height: Design.Layout.selectionInnerSize)
      }
    }
  }
}

// MARK: - Style Extensions
private extension View {
  func cardStyle() -> some View {
    self
      .background(DesignSystem.Colors.background)
      .cornerRadius(Design.Card.cornerRadius)
      .scheduleCardStyle()
  }
}

// MARK: - Preview
#if DEBUG
struct EventCard_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      makePreview()
        .previewDisplayName("Light Mode")
      
      makePreview()
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark Mode")
    }
    .padding()
    .previewLayout(.sizeThatFits)
  }
  
  private static func makePreview() -> some View {
    EventCard(
      title: "南知读书会第一期",
      startDate: Date(timeIntervalSince1970: 1679725200),
      endDate: Date(timeIntervalSince1970: 1679732400),
      location: "知识星球",
      calendar: "工作",
      isSelected: true,
      onSelect: {},
      onMoreAction: {},
      onDelete: {}
    )
  }
}
#endif
