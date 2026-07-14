# FolderManifest App Store 发布资料

本目录用于保存提交 Mac App Store 所需的产品页文案、审核说明、隐私政策、技术支持内容和截图清单，不存放 Debug App 或 Archive。

## 文件说明

- `AppStoreMetadata.md`：App Store 产品页字段和建议文案。
- `AppReviewNotes.md`：提供给 Apple 审核人员的操作说明。
- `PrivacyPolicy.md`：FolderManifest 隐私政策正文。
- `Support.md`：系统要求、使用方法和常见问题。
- `screenshots/README.md`：已有截图的用途、画面说明和提交检查清单。

## 提交前待办

- [ ] 在 Apple Developer 与 App Store Connect 中注册最终 Bundle ID。
- [ ] 将 Xcode 工程中的临时 Bundle ID `com.foldermanifest.app` 改为最终发布标识。
- [ ] 确认首发版本号与构建号；工程当前为 `0.1.0 (1)`。
- [ ] 在 Xcode 中选择正式开发者团队，并启用 App Sandbox。
- [ ] 只申请实际需要的“用户选择的文件”读写权限，完成沙盒环境测试。
- [ ] 确认 App 名称、SKU、类别、价格、版权和审核联系方式。
- [ ] 确认技术支持与隐私政策网址可以在未登录状态下访问。
- [x] 已加入两张 `2560×1600` 的 16:10 App Store 展示图和一张实际软件截图。
- [ ] 提交前使用最终 Release 版本逐张复核界面、示例路径、隐私信息和 App Store Connect 当前尺寸要求。
- [ ] 核对 App Store Connect 中的 App 隐私回答与最终构建行为完全一致。
- [ ] 在 Xcode 中通过 `Product → Archive` 创建、验证并上传正式构建。

## 计划使用的网址

- 产品主页：https://github.com/liziligit/FolderManifest
- 问题反馈：https://github.com/liziligit/FolderManifest/issues
- 技术支持：待发布公开页面；正文见 `Support.md`
- 隐私政策：待发布公开页面；正文见 `PrivacyPolicy.md`

App Store Connect 要求填写网址时，应使用无需登录即可访问的公开网页。正式提交前请将 `Support.md` 和 `PrivacyPolicy.md` 发布到稳定网址，并更新本目录中的链接。
