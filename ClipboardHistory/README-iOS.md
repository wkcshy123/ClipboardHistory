# iOS 版本编译说明

## 📋 功能特性
✅ 剪贴板历史记录（支持文本、图片、文件URL）
✅ 全文搜索功能
✅ 点击条目一键复制
✅ 滑动删除单条记录
✅ 长按菜单操作
✅ 震动反馈
✅ 批量清空历史确认
✅ 最大历史条数自定义
✅ 纯原生SwiftUI实现，无第三方依赖

## 🚀 编译步骤

### 前置要求
- Xcode 14.0+
- iOS 16.0+ 部署目标（可根据需要调整到iOS 15+）
- Apple Developer 账号（可选，用于真机调试）

### 编译步骤
1. 用Xcode打开 `ClipboardHistory.xcodeproj`
2. 点击项目根节点，在Targets列表点击"+"添加新Target
3. 选择 "iOS > App" 模板，点击Next
4. 填写Target信息：
   - Product Name: Clipboard History iOS
   - Interface: SwiftUI
   - Language: Swift
   - 取消勾选 "Use Core Data"、"Include Tests"
   - 点击Finish
5. 配置新Target的General设置：
   - Deployment Info: 选择 iOS 16.0 或更高版本
   - Bundle Identifier: 改为你自己的ID（如 com.yourname.ClipboardHistory）
6. 配置Info.plist：
   - 将 `iOS-Info.plist` 中的内容复制到新Target的Info.plist中
   - 或直接将 `iOS-Info.plist` 设置为新Target的Info.plist文件
7. 添加源文件到新Target：
   - 选择以下文件，在右侧Target Membership中勾选新创建的iOS Target：
     - Models/ClipboardItem.swift
     - Models/ClipboardManager.swift
     - Controllers/StorageManager.swift
     - iOSApp.swift
     - iOSHistoryView.swift
     - iOSSettingsView.swift
8. 配置Build Settings：
   - 在 "Other Swift Flags" 中添加 `-D os(iOS)` 确保平台条件编译生效
9. 选择iOS模拟器或真机设备，点击Run即可运行

## 📱 使用说明
1. 首次启动App时，会请求剪贴板访问权限，请点击允许
2. 每次复制内容后，打开App即可看到历史记录
3. 点击任意历史条目即可自动复制到剪贴板
4. 向左滑动条目可以删除单条记录
5. 长按条目可以调出操作菜单
6. 顶部搜索框可以搜索所有历史内容
7. 点击右上角垃圾桶按钮可以清空所有历史

## 🔮 后续功能规划
- [ ] 剪贴板扩展：在任何App的粘贴菜单中直接显示历史记录
- [ ] 锁屏/主屏幕小组件：快速访问最近剪贴板内容
- [ ] iCloud多端同步：在iPhone、iPad、Mac之间同步剪贴板历史
- [ ] 快捷指令支持：自动化操作剪贴板历史
- [ ] 内容分类筛选：按文本、图片、文件分类查看
- [ ] 收藏夹功能：收藏常用的剪贴板内容
