//
//  ContentView.swift
//  WindowGroup
//
//  Created by cyberserval on 2025/2/18.
//

import SwiftUI

// 主视图结构体
struct ContentView: View {
  var body: some View {
    VStack {
      // 顶部工具栏
      HStack {
        Spacer()
        Button(action: {
          NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }) {
          Image(systemName: "gear")
            .imageScale(.large)
            .foregroundColor(DesignSystem.Colors.primary)
        }
        .buttonStyle(.plain)
        .padding(.trailing, 8)
        .withHoverEffect(scale: 1.1, brightness: 0)
        .help("设置")
      }

      // 主要内容
      VStack {
        Image(systemName: "globe")
          .imageScale(.large)
          .foregroundColor(.accentColor)
        Text("Hello, world!")
      }
    }
    .frame(width: 400, height: 600)
    .background(WindowBackground())
  }
}

// 私有结构体：窗口背景视图
private struct WindowBackground: View {
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    ZStack {
      // 使用WindowBackgroundView保持一致的视觉效果
      WindowBackgroundView()

      // 磨砂玻璃效果层
      Rectangle()
        .withVibrancy(
          materialType: .thin,
          cornerRadius: 0,
          addBorder: false,
          opacity: 0.85
        )
    }
    .ignoresSafeArea()
  }
}

// 使用传统的预览结构体
struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      ContentView()
        .preferredColorScheme(.light)
      ContentView()
        .preferredColorScheme(.dark)
    }
  }
}
