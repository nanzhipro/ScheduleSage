import SwiftUI
import AppKit

struct PopoverView: View {
    @State private var remainingUses: Int = 12
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部状态栏
            HStack {
                // Pro 状态
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color(NSColor.systemGray))
                            .frame(width: 24, height: 24)
                        Image(systemName: "crown")
                            .foregroundColor(.secondary)
                    }
                    Text(String(format: NSLocalizedString("remaining_uses", comment: ""), remainingUses))
                        .foregroundColor(.secondary)
                    Text(NSLocalizedString("separator", comment: ""))
                        .foregroundColor(.secondary)
                    Text(NSLocalizedString("upgrade_prompt", comment: ""))
                        .foregroundColor(.blue)
                }
                .padding(.leading)
                
                Spacer()
                
                // 添加按钮
                Button(action: {}) {
                    Image(systemName: "plus")
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(.trailing)
            }
            .frame(height: 44)
            .background(Color(NSColor.windowBackgroundColor))
            
            // 主要内容区域
            VStack(spacing: 20) {
                // 日历图标
                ZStack {
                    Circle()
                        .fill(Color(NSColor.systemGray))
                        .frame(width: 80, height: 80)
                    Image(systemName: "calendar")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                Text(NSLocalizedString("add_schedule_title", comment: ""))
                    .font(.headline)
                
                // 三种添加方式
                HStack(spacing: 40) {
                    AddMethodButton(
                        icon: "doc.on.clipboard",
                        text: NSLocalizedString("clipboard_import", comment: "")
                    )
                    AddMethodButton(
                        icon: "plus",
                        text: NSLocalizedString("manual_input", comment: "")
                    )
                    AddMethodButton(
                        icon: "square.and.arrow.down",
                        text: NSLocalizedString("drag_image", comment: "")
                    )
                }
                .padding(.horizontal)
                
                Spacer()
                
                // 导入按钮
                Button(action: {}) {
                    Text(NSLocalizedString("import_calendar", comment: ""))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.blue.opacity(0.5))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .padding()
            }
            .frame(maxWidth: .infinity)
            .background(Color(NSColor.systemGray))
        }
    }
}

struct AddMethodButton: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(Color(NSColor.systemGray))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .foregroundColor(.secondary)
            }
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
} 
