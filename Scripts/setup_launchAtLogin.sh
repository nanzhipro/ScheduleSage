#!/bin/bash
#
# 设置LaunchAtLogin-Modern库的脚本
#
# 此脚本记录了设置LaunchAtLogin-Modern库需要的手动步骤
# 这些步骤需要在Xcode UI中完成，不能通过命令行完成
#

echo "=========================================="
echo "LaunchAtLogin-Modern 设置步骤"
echo "=========================================="
echo
echo "步骤1: 在Xcode中，选择ScheduleSage项目"
echo "步骤2: 选择ScheduleSage target"
echo "步骤3: 选择'Build Settings'选项卡"
echo "步骤4: 搜索'User Script Sandboxing'"
echo "步骤5: 将其设置为'NO'"
echo
echo "这些步骤是必须的，否则LaunchAtLogin-Modern将无法正常工作。"
echo "原因: LaunchAtLogin-Modern需要执行一个脚本来设置启动项，而该脚本在沙盒环境中无法运行。"
echo
echo "参考链接: https://github.com/sindresorhus/LaunchAtLogin-Modern"
echo

# 检查Info.plist中是否已设置LSUIElement键
if grep -q "LSUIElement" ../ScheduleSage/Info.plist; then
    echo "✅ Info.plist中已包含LSUIElement键，无需修改"
else
    echo "❌ Info.plist中缺少LSUIElement键，请添加以下内容:"
    echo "    <key>LSUIElement</key>"
    echo "    <false/>"
fi
