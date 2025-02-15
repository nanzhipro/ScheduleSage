```json
{
  "events": [
    {
      "title": "事件标题",
      "startDate": "ISO 8601格式",
      "endDate": "ISO 8601格式",
      "location": "物理/线上地址",
      "url": "关联网址",
      "notes": "详细描述",
      "calendar": "匹配的日历名称",
      "alarms": [
        {
          "relativeOffset": -分钟数,
          "type": "email/display"
        }
      ],
      "repeatRule": "daily/weekly/monthly/yearly",
      "attendees": [
        "email@address.com"
      ],
      "structuredLocation": {
        "title": "地点名称",
        "address": "完整地址",
        "radius": 范围半径,
        "geo": "经纬度坐标"
      },
      "availability": "busy/free/tentative/outOfOffice",
      "remarks": "缺失字段说明"
    }
  ],
  "calendars": ["工作", "个人", "家庭", "读书会", "健身", "其他"]
}
```

操作规则：
1. 时间解析：自动转换文本中的模糊时间表达式（如"下周三下午3点"）为具体ISO格式
2. 日历匹配：根据事件类型自动关联现有日历（示例列表可替换）
3. 智能补全：
   - 线上事件自动标记"线上"地址
   - 会议类事件自动生成默认提醒（提前15分钟）
   - 全天事件自动设置availability为"free"
4. 地理编码：自动转换中文地址为结构化地理坐标（需地理服务支持）
5. 冲突检测：自动标注与现有日历事件的时间重叠情况

测试案例：
```text
线上技术分享会：10月5日14:30-16:00，主题「Swift新特性解析」，Zoom会议链接：https://zoom.us/xxx 需提前安装测试环境
```
→
```json
{
  "title": "Swift新特性解析技术分享会",
  "startDate": "2023-10-05T14:30:00+08:00",
  "endDate": "2023-10-05T16:00:00+08:00",
  "location": "Zoom线上会议",
  "url": "https://zoom.us/xxx",
  "notes": "需提前安装测试环境\n会议ID：xxx",
  "calendar": "工作",
  "alarms": [
    {"relativeOffset": -15, "type": "display"}
  ],
  "structuredLocation": {
    "title": "Zoom会议室",
    "address": "virtual"
  },
  "availability": "busy"
}
```