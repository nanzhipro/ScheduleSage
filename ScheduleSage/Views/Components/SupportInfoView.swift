//
//  SupportInfoView.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-04-07.
//

import SwiftUI

/// 支持信息视图
/// 显示用户支持ID和基本设备信息，便于用户在需要支持时提供
struct SupportInfoView: View {
  @State private var isCopied = false
  private let supportID = DeviceInfoService.getSupportID()
  @Environment(\.openURL) private var openURL

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(NSLocalizedString("support_info.title", comment: ""))
        .font(.headline)
        .padding(.bottom, 4)

      VStack(alignment: .leading, spacing: 8) {
        HStack {
          Text(NSLocalizedString("support_info.support_id", comment: ""))
            .font(.subheadline)
            .foregroundColor(.secondary)

          Text(supportID)
            .font(.system(.subheadline, design: .monospaced))

          Spacer()

          Button(action: {
            copyToClipboard(supportID)
            withAnimation {
              isCopied = true
            }

            // 2秒后重置状态
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
              withAnimation {
                isCopied = false
              }
            }
          }) {
            Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
              .foregroundColor(isCopied ? .green : .accentColor)
          }
          .buttonStyle(BorderlessButtonStyle())
          .help(NSLocalizedString("support_info.copy_tooltip", comment: ""))
        }
      }
      .padding()
      .background(Color(NSColor.controlBackgroundColor))
      .cornerRadius(8)

      Text(LocalizedStringKey("support_info.help_text"))
        .font(.caption)
        .foregroundColor(.secondary)
        .tint(.accentColor)
    }
    .padding()
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func deviceInfoRow(title: String, value: String) -> some View {
    HStack {
      Text(title)
        .font(.subheadline)
        .foregroundColor(.secondary)
      Text(value)
        .font(.subheadline)
      Spacer()
    }
    .padding(.vertical, 2)
  }

  private func copyToClipboard(_ text: String) {
    #if os(macOS)
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(text, forType: .string)
    #endif
  }
}

#Preview {
  SupportInfoView()
    .frame(width: 400)
}
