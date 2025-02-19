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
            .foregroundColor(.secondary)
        }
        .buttonStyle(.plain)
        .padding(.trailing, 8)
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
    Color(nsColor: .windowBackgroundColor)
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
