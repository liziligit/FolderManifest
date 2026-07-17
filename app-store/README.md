# FolderManifest App Store 发布资料

本目录用于保存提交 Mac App Store 所需的产品页文案、审核说明、隐私政策、技术支持内容和截图清单，不存放 Debug App 或 Archive。

## 文件说明

- `AppStoreMetadata.md`：App Store 产品页字段和建议文案。
- `AppReviewNotes.md`：提供给 Apple 审核人员的操作说明。
- `PrivacyPolicy.md`：FolderManifest 隐私政策正文。
- `Support.md`：系统要求、使用方法和常见问题。
- `screenshots/README.md`：已有截图的用途、画面说明和提交检查清单。

## 提交前待办

- [x] 已在 Apple Developer 与 App Store Connect 中注册最终 Bundle ID `com.liziligit.foldermanifest`。
- [x] Xcode 工程已使用最终发布标识 `com.liziligit.foldermanifest`。
- [x] 本次提交版本号与构建号为 `0.1.0 (2)`。
- [x] Xcode 已选择开发者团队并启用 App Sandbox。
- [x] 已配置“用户选择的文件”Read/Write 权限，其他无关资源权限均关闭。
- [x] 已确认 App 名称、SKU、类别和版权；价格及审核联系方式以 App Store Connect 当前设置为准。
- [x] 技术支持与隐私政策使用无需登录即可访问的公开 GitHub 页面。
- [x] 已加入 `PrivacyInfo.xcprivacy`，声明不跟踪、不收集数据以及文件时间和 UserDefaults 的使用理由。
- [x] 已加入两张 `2560×1600` 的 16:10 App Store 展示图和一张实际软件截图。
- [ ] 提交前使用最终 Release 版本逐张复核界面、示例路径、隐私信息和 App Store Connect 当前尺寸要求。
- [ ] 核对 App Store Connect 中的 App 隐私回答与最终构建行为完全一致。
- [ ] 在 Xcode 中通过 `Product → Archive` 创建、验证并上传正式构建。

## 计划使用的网址

- 产品主页：https://github.com/liziligit/FolderManifest
- 问题反馈：https://github.com/liziligit/FolderManifest/issues
- 技术支持：https://github.com/liziligit/FolderManifest/issues
- 隐私政策：https://github.com/liziligit/FolderManifest/blob/main/app-store/PrivacyPolicy.md

App Store Connect 要求填写网址时，应使用无需登录即可访问的公开网页。正式提交前请将 `Support.md` 和 `PrivacyPolicy.md` 发布到稳定网址，并更新本目录中的链接。
