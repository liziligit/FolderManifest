# FolderManifest

一款完全离线、只读扫描的 macOS 文件夹目录清单生成器。

使用 Xcode 开发时，双击 `FolderManifest.xcodeproj`，选择 `FolderManifest` Scheme 后点击运行按钮。

## 当前功能

- 选择或拖入文件夹
- 扫描子文件夹并忽略常见系统文件
- 单次遍历时实时显示已发现项目数，并以动态状态提示扫描进度
- 固定使用清晰的树状目录展示
- 按名称、类型、修改时间或大小排序
- 点击搜索按钮或按回车后，在现有 Tree 中使用正则表达式高亮文件夹和文件路径
- 使用“上一个”“下一个”循环定位匹配项
- 双击 Tree 中的路径文字，在 Finder 中打开文件夹或定位文件
- 选择 Tree 中的文字后，可通过右键菜单直接搜索或复制
- 显示文件大小、修改时间和文件数量
- 复制完整 Tree 或导出为 TXT
- 支持简体中文、繁体中文、英语、日语、韩语、西班牙语、法语、德语和葡萄牙语（巴西）

## 构建

需要 macOS 14 或更高版本，以及 Xcode 16 或更高版本。

```bash
chmod +x build_app.sh
./build_app.sh
```

完成后，可在项目根目录找到 `FolderManifest.app`。

## 测试

```bash
swift test
```
