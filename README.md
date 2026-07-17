# FolderManifest

FolderManifest 是一款原生 macOS 文件夹目录清单工具。它以只读方式扫描用户选择的文件夹，将文件和子文件夹整理成清晰的 Tree 结构，并支持快速搜索、定位、复制和 TXT 导出。扫描和整理均在当前 Mac 本地完成。

## 软件界面

FolderManifest 采用适合桌面工作的三栏布局：左侧设置扫描与排序选项，中间保存最近打开和固定的常用文件夹，右侧展示完整 Tree；上方显示扫描状态和项目统计。用户可以将文件夹拖入窗口，也可通过系统选择器导入。

![FolderManifest 导入文件夹与离线扫描界面](app-store/screenshots/FolderManifest%201.jpg)

*FolderManifest 支持拖入文件夹、完全离线的只读扫描、多语言界面和 TXT 导出。*

![FolderManifest Tree 目录、正则搜索与匹配定位](app-store/screenshots/FolderManifest%202.jpg)

*Tree 结构保留完整目录层级；支持正则表达式搜索、匹配高亮、前后跳转、Finder 定位和多种排序方式。*

更多截图资料和提交检查见 [Mac App Store 截图清单](app-store/screenshots/README.md)。

## 支持与隐私

- [技术支持](app-store/Support.md)
- [隐私政策](app-store/PrivacyPolicy.md)
- [App Store 发布资料](app-store/README.md)
- [GitHub Issues](https://github.com/liziligit/FolderManifest/issues)

FolderManifest 不要求注册账号，不包含广告，也不使用第三方分析或跟踪服务。当前版本不会把文件、文件名、目录结构或导出结果上传到服务器。

## 项目来源

FolderManifest 由开发者独立设计和实现，没有参考、复制或改编其他项目的代码。项目使用 Apple 提供的 Swift、SwiftUI、AppKit 与系统框架开发。

## 推广文本

快速看清复杂文件夹：一次扫描生成清晰的 Tree 目录，支持正则搜索、Finder 定位、内存排序和 TXT 导出。所有处理都在 Mac 本地完成。

## 关键词

```text
目录结构,正则表达式,路径定位,TXT导出,离线扫描,硬盘整理,Finder
```

上述文本可直接填入 App Store Connect 的简体中文“关键词”字段。关键词使用英文逗号分隔，逗号后不加空格，不重复 App 名称 `FolderManifest`。

## 描述

FolderManifest 帮助用户快速了解文件夹中包含哪些文件，以及它们之间的层级关系。选择或拖入一个文件夹后，App 会进行只读扫描，并以清晰的 Tree 结构展示目录。

主要功能：

- 选择或拖入文件夹，按需包含子文件夹和隐藏文件；
- 单次遍历目录，扫描时实时显示已经发现的项目数量；
- 以 Tree 结构展示文件和文件夹的自然层级；
- 保存最近打开的文件夹及 Tree 快照，再次点击时无需重新扫描；
- 支持固定最多 25 个常用文件夹，并调整固定项目的顺序；
- 支持单独移除记录、清理无效记录和清除全部未固定历史，固定文件夹不受批量清理影响；
- 支持按名称、类型、修改时间或大小排序，切换排序时直接重排内存数据；
- 使用不区分大小写的正则表达式搜索完整路径；
- 在原 Tree 中高亮匹配名称，并通过“上一个”“下一个”循环定位；
- 双击文件名在 Finder 中显示文件，双击文件夹名称直接打开文件夹；
- 选择 Tree 中的文字后，可通过右键菜单搜索或复制；
- 显示文件大小、修改时间和文件夹内文件数量；
- 复制完整 Tree，或将目录清单导出为 UTF-8 编码的 TXT 文件；
- 支持简体中文、繁体中文、英语、日语、韩语、西班牙语、法语、德语和葡萄牙语（巴西）；
- 主窗口关闭后，可通过“窗口”菜单或点击 Dock 图标重新打开。

FolderManifest 只读取用户主动选择的文件夹。扫描、搜索、排序和导出均在本地完成，不需要网络连接。

## 此版本的新增内容

FolderManifest 0.1.0 (2) 包含只读文件夹扫描、Tree 目录展示、实时项目计数、最近打开与固定文件夹、正则搜索、Finder 定位、内存排序、TXT 导出和 9 种界面语言，并支持在关闭主窗口后通过“窗口”菜单或 Dock 图标重新打开。

## 开发与构建

开发环境：

- macOS 14.0 或更高版本；
- Xcode 16 或更高版本；
- Swift 6。

使用 Xcode：

1. 双击 `FolderManifest.xcodeproj`；
2. 选择 `FolderManifest` Scheme 和“我的 Mac”；
3. 按 `Command-R` 构建并运行；
4. 使用 `Product → Test` 运行测试；
5. 准备发布时使用 `Product → Archive` 创建归档。

也可以在项目根目录运行：

```bash
swift test
chmod +x build_app.sh
./build_app.sh
```

`build_app.sh` 完成后会在项目根目录生成 `FolderManifest.app`。提交 Mac App Store 前，还需要在 Xcode 中配置正式的开发者团队、App Sandbox、签名和发布标识。

## 使用方法

1. 启动 FolderManifest，点击“选择文件夹”，或将文件夹拖入窗口。
2. 在左侧选择是否包含子文件夹、隐藏文件，以及需要显示的信息。
3. 等待状态由“正在扫描”变为“扫描结束”。
4. 在 Tree 中浏览目录，或输入正则表达式后点击“搜索”。
5. 使用“上一个”“下一个”在匹配项之间循环跳转。
6. 双击文件或文件夹名称，在 Finder 中定位或打开对应项目。
7. 点击“复制”复制完整 Tree，或点击“导出 .TXT”保存目录清单。
8. 通过“最近打开”恢复之前保存的 Tree；如需读取磁盘上的最新内容，请点击“重新扫描”。
9. 使用“最近打开”右侧的 `…` 菜单管理记录，或从“文件”菜单清除未固定的历史记录。

## 项目结构

```text
FolderManifest/
├── AppResources/                 图标、资源目录与 Info.plist
├── Sources/FolderManifest/       App 源代码
├── Tests/FolderManifestTests/    自动化测试
├── app-store/                    App Store 文案、审核说明与截图清单
├── FolderManifest.xcodeproj/     Xcode 工程
├── Package.swift                 Swift Package 配置
├── build_app.sh                  本地 App 构建脚本
├── LICENSE                       MIT License
└── README.md                     项目说明
```

## 开源说明

FolderManifest 是独立开发的开源项目，采用 [MIT License](LICENSE)。

Copyright © 2026 李自立。
