# ScheduleSage Chrome扩展配置指南

由于macOS沙盒限制，ScheduleSage应用无法直接配置Chrome扩展的本地通信功能。请按照以下步骤手动完成配置：

## 配置步骤

### 方法一：使用配置脚本（推荐）

1. 打开终端（在"应用程序/实用工具"中或使用Spotlight搜索"终端"）
2. 复制下面的命令并粘贴到终端中，然后按回车执行：

```bash
#!/bin/bash

# ScheduleSage Chrome扩展配置脚本
MANIFEST_DIR="$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts"
mkdir -p "$MANIFEST_DIR"

# 创建清单文件
MANIFEST_FILE="$MANIFEST_DIR/com.tiwenlab.schedulesage.json"
cat > "$MANIFEST_FILE" << 'MANIFEST'
{
    "name": "com.tiwenlab.schedulesage",
    "description": "ScheduleSage Native Host",
    "path": "/Applications/ScheduleSage.app/Contents/MacOS/SSChromeExtensionsCLI",
    "type": "stdio",
    "allowed_origins": [
        "chrome-extension://jphemoehpamhbkpmkpbflfdghobchnhk/"
    ]
}
MANIFEST

# 检查结果
if [ -f "$MANIFEST_FILE" ]; then
    echo "✅ 安装成功: Chrome扩展配置已完成"
    echo "文件已创建: $MANIFEST_FILE"
else
    echo "❌ 安装失败: 请检查权限或手动运行"
fi
```

3. 如果看到"✅ 安装成功"的消息，表示配置已完成

### 方法二：手动配置

如果脚本执行失败，您可以按照以下步骤手动配置：

1. 打开访达（Finder）
2. 按下 `Command+Shift+G` 组合键
3. 输入以下路径并点击"前往"：

   ```
   ~/Library/Application Support/Google/Chrome/NativeMessagingHosts
   ```

4. 如果该目录不存在，请依次创建各个目录
5. 使用文本编辑器（如TextEdit）创建一个名为 `com.tiwenlab.schedulesage.json` 的文件
6. 将以下内容复制到该文件中：

   ```json
   {
       "name": "com.tiwenlab.schedulesage",
       "description": "ScheduleSage Native Host",
       "path": "/Applications/ScheduleSage.app/Contents/MacOS/SSChromeExtensionsCLI",
       "type": "stdio",
       "allowed_origins": [
           "chrome-extension://jphemoehpamhbkpmkpbflfdghobchnhk/"
       ]
   }
   ```

7. 保存文件

## 验证配置

1. 打开Chrome浏览器
2. 安装 ScheduleSage 扩展（如果尚未安装）
3. 点击扩展图标测试功能是否正常工作

## 疑难解答

如果遇到问题：

- 确保 ScheduleSage 应用已安装在应用程序文件夹中
- 检查Chrome扩展是否正确安装
- 重启Chrome浏览器
- 重启计算机后再次尝试

如需更多帮助，请联系我们的技术支持。
