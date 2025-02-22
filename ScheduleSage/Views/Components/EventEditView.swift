//
//  EventEditView.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import SwiftUI

// MARK: - Event Edit View
struct EventEditView: View {
  // MARK: - Properties
  let event: CalendarEvent
  let onSave: (CalendarEvent) -> Void
  let onCancel: () -> Void
  
  @State private var editedEvent: CalendarEvent
  @Environment(\.dismiss) private var dismiss
  @State private var title: String
  @State private var startDate: Date
  @State private var endDate: Date
  @State private var location: String
  @State private var calendar: String
  @State private var isEditing = false
  
  // MARK: - Initialization
  init(event: CalendarEvent, onSave: @escaping (CalendarEvent) -> Void, onCancel: @escaping () -> Void) {
    self.event = event
    self.onSave = onSave
    self.onCancel = onCancel
    _editedEvent = State(initialValue: event)
    _title = State(initialValue: event.title)
    _location = State(initialValue: event.location)
    _calendar = State(initialValue: event.calendar)
    _startDate = State(initialValue: event.parsedStartDate ?? Date())
    _endDate = State(initialValue: event.parsedEndDate ?? Date())
  }
  
  // MARK: - Body
  var body: some View {
    VStack(spacing: 0) {
      headerView
      
      ScrollView {
        formContent
      }
      
      footerView
    }
    .frame(
      width: DesignSystem.Dimensions.mainViewWidth * 0.8,
      height: DesignSystem.Dimensions.mainViewHeight * 0.8
    )
    .background(DesignSystem.Colors.background)
    .cornerRadius(DesignSystem.Dimensions.containerCornerRadius)
    .onAppear {
      isEditing = true
    }
    .onDisappear {
      isEditing = false
    }
  }
  
  // MARK: - Header View
  private var headerView: some View {
    VStack(alignment: .leading, spacing: DesignSystem.Spacing.largeHeaderSpacing) {
      HStack {
        Text(NSLocalizedString("edit_event_title", comment: ""))
          .font(DesignSystem.Typography.largeHeaderTitle)
          .foregroundColor(DesignSystem.Colors.primaryText)
        
        Spacer()
        
        SageCloseButton(action: onCancel)
      }
      
      Text(NSLocalizedString("edit_event_subtitle", comment: ""))
        .font(DesignSystem.Typography.largeHeaderSubtitle)
        .foregroundColor(DesignSystem.Colors.secondaryText)
        .lineLimit(2)
    }
    .padding(.horizontal, DesignSystem.Layout.largeContainerPadding.leading)
    .padding(.top, DesignSystem.Layout.largeContainerPadding.top)
    .padding(.bottom, DesignSystem.Spacing.sectionSpacing)
  }
  
  // MARK: - Form Content
  private var formContent: some View {
    Form {
      Section {
        titleField
        dateFields
        locationField
        calendarField
      }
    }
    .formStyle(.grouped)
    .scrollContentBackground(.hidden)
  }
  
  private var titleField: some View {
    TextField(NSLocalizedString("event_field_title", comment: ""), text: $title)
      .textFieldStyle(.plain)
      .font(DesignSystem.Typography.bodyMedium)
  }
  
  private var dateFields: some View {
    Group {
      makeDatePicker(
        title: "event_field_start_date",
        selection: $startDate
      )
      
      makeDatePicker(
        title: "event_field_end_date",
        selection: $endDate
      )
    }
  }
  
  private var locationField: some View {
    makeTextField(
      title: "event_field_location",
      text: $location
    )
  }
  
  private var calendarField: some View {
    makeTextField(
      title: "event_field_calendar",
      text: $calendar
    )
  }
  
  // MARK: - Footer View
  private var footerView: some View {
    HStack(spacing: DesignSystem.Spacing.elementSpacing) {
      ActionButton(
        title: "cancel",
        style: .cancel,
        action: handleCancel
      )
      
      ActionButton(
        title: "save",
        style: .primary,
        action: handleSave
      )
    }
    .padding(DesignSystem.Layout.containerPadding)
  }
  
  // MARK: - Helper Views
  private func makeDatePicker(title: String, selection: Binding<Date>) -> some View {
    DatePicker(
      NSLocalizedString(title, comment: ""),
      selection: selection,
      displayedComponents: [.date, .hourAndMinute]
    )
    .foregroundColor(DesignSystem.Colors.primaryText)
  }
  
  private func makeTextField(title: String, text: Binding<String>) -> some View {
    HStack {
      Text(NSLocalizedString(title, comment: ""))
        .foregroundColor(DesignSystem.Colors.primaryText)
      
      TextField("", text: text)
        .textFieldStyle(.plain)
    }
  }
  
  // MARK: - Actions
  private func handleSave() {
    guard isEditing else { return }
    
    let updatedEvent = CalendarEvent(
      title: title,
      location: location,
      notes: event.notes,
      startDate: DateFormatters.standard.string(from: startDate),
      endDate: DateFormatters.standard.string(from: endDate),
      url: event.url,
      calendar: calendar,
      status: event.status,
      eventIdentifier: event.eventIdentifier,
      remarks: event.remarks
    )
    
    isEditing = false
    onSave(updatedEvent)
    
    DispatchQueue.main.async {
      dismiss()
    }
  }
  
  private func handleCancel() {
    isEditing = false
    DispatchQueue.main.async {
      onCancel()
      dismiss()
    }
  }
}

// MARK: - Supporting Views
private struct ActionButton: View {
  let title: String
  let style: ButtonStyle
  let action: () -> Void
  
  @State private var isHovering = false
  @State private var isPressed = false
  @Environment(\.colorScheme) private var colorScheme
  
  enum ButtonStyle {
    case primary
    case cancel
    
    var backgroundColor: Color {
      switch self {
      case .primary:
        return DesignSystem.Colors.primary
      case .cancel:
        return DesignSystem.Colors.cancelButtonBackground
      }
    }
    
    func foregroundColor(in colorScheme: ColorScheme) -> Color {
      switch self {
      case .primary:
        return DesignSystem.Colors.background
      case .cancel:
        return colorScheme == .dark ? DesignSystem.Colors.background : DesignSystem.Colors.primaryText
      }
    }
    
    func backgroundColor(in colorScheme: ColorScheme, isHovering: Bool) -> Color {
      switch self {
      case .primary:
        return DesignSystem.Colors.primary.opacity(isHovering ? 0.8 : 1.0)
      case .cancel:
        if colorScheme == .dark {
          return DesignSystem.Colors.secondaryText.opacity(isHovering ? 0.8 : 0.6)
        } else {
          return DesignSystem.Colors.cancelButtonBackground.opacity(isHovering ? 0.8 : 1.0)
        }
      }
    }
  }
  
  var body: some View {
    Button(action: {
      withAnimation(.easeOut(duration: 0.2)) {
        isPressed = true
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
        isPressed = false
        action()
      }
    }) {
      Text(NSLocalizedString(title, comment: ""))
        .font(DesignSystem.Typography.buttonLabel)
        .foregroundColor(style.foregroundColor(in: colorScheme))
        .frame(maxWidth: .infinity)
        .frame(height: DesignSystem.Dimensions.buttonHeight)
        .background(
          style.backgroundColor(in: colorScheme, isHovering: isHovering)
        )
        .cornerRadius(DesignSystem.Dimensions.buttonCornerRadius)
        .scaleEffect(isPressed ? 0.98 : 1.0)
    }
    .buttonStyle(.plain)
    .onHover { hovering in
      withAnimation(.easeInOut(duration: 0.2)) {
        isHovering = hovering
      }
    }
  }
}

// MARK: - Preview
#if DEBUG
struct EventEditView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      makePreview()
        .previewDisplayName("Light Mode")
      
      makePreview()
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark Mode")
    }
    .frame(width: 500, height: 700)
    .background(Color.gray.opacity(0.1))
    .padding()
  }
  
  private static func makePreview() -> some View {
    EventEditView(
      event: PreviewData.mockCalendarEvents[0],
      onSave: { _ in },
      onCancel: {}
    )
  }
}
#endif 