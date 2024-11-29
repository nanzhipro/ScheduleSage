import SwiftUI

// MARK: - Constants
private enum EventCardConstants {
    static let cardHeight: CGFloat = 134
    static let cardPadding: EdgeInsets = .init(top: 20, leading: 20, bottom: 20, trailing: 20)
    static let titleSpacing: CGFloat = 8
    static let iconSpacing: CGFloat = 16
    static let iconSize: CGFloat = 32
    static let selectionIndicatorSize: CGFloat = 16
    static let selectionIndicatorInnerSize: CGFloat = 8
    static let selectionIndicatorOuterOpacity: Double = 0.1
}

struct EventCard: View {
    // MARK: - Properties
    let title: String
    let time: String
    let location: String?
    let isRecurring: Bool
    let calendar: String?
    let isSelected: Bool
    let onSelect: () -> Void
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: EventCardConstants.titleSpacing) {
            // 标题
            Text(title)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.black)
                .lineLimit(1)
            
            // 时间
            Text(time)
                .font(.system(size: 15))
                .foregroundColor(Color(hex: "86868B"))
                .padding(.bottom, 12)
            
            // 图标行
            HStack(spacing: EventCardConstants.iconSpacing) {
                if let location = location {
                    EventIconLabel(icon: "location.fill", text: location)
                }
                
                if isRecurring {
                    EventIconLabel(icon: "arrow.2.circlepath", text: NSLocalizedString("recurring", comment: ""))
                }
                
                if let calendar = calendar {
                    EventIconLabel(icon: "calendar", text: calendar)
                }
                
                Spacer()
                
                // 选择指示器
                SelectionIndicator(isSelected: isSelected)
                    .onTapGesture(perform: onSelect)
            }
        }
        .padding(EventCardConstants.cardPadding)
        .frame(height: EventCardConstants.cardHeight)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(
            color: Color.black.opacity(0.05),
            radius: 2,
            x: 0,
            y: 1
        )
    }
}

// MARK: - Supporting Views
private struct EventIconLabel: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color(hex: "F2F2F7"))
                    .frame(width: EventCardConstants.iconSize,
                           height: EventCardConstants.iconSize)
                Image(systemName: icon)
                    .foregroundColor(Color(hex: "666666"))
            }
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "86868B"))
        }
    }
}

private struct SelectionIndicator: View {
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "34C759").opacity(EventCardConstants.selectionIndicatorOuterOpacity))
                .frame(
                    width: EventCardConstants.selectionIndicatorSize,
                    height: EventCardConstants.selectionIndicatorSize
                )
            
            if isSelected {
                Circle()
                    .fill(Color(hex: "34C759"))
                    .frame(
                        width: EventCardConstants.selectionIndicatorInnerSize,
                        height: EventCardConstants.selectionIndicatorInnerSize
                    )
            }
        }
    }
}

// MARK: - Preview
#if DEBUG
struct EventCard_Previews: PreviewProvider {
    static var previews: some View {
        EventCard(
            title: "南知读书会第一期",
            time: "3月25日 周一 14:00-16:00",
            location: "知识星球",
            isRecurring: true,
            calendar: "工作",
            isSelected: true,
            onSelect: {}
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif 