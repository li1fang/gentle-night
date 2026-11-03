# Gentle Night

[English](README.md)

Gentle Night 是一个刚开始开发的 macOS 小工具：屏幕空闲时逐渐变黑，恢复活动时快速、柔和地重新显示当前桌面。目标是不锁屏、不关闭显示输出，维持原有会话与任务运行。

主要探索的效果是**概率消隐**：每个位置要么透明，显示下方原画面的颜色，要么变为不透明纯黑。外围先消失，中心保留更久，最后少量光点也完全消失。同一轮使用固定像素阈值，避免每帧重新随机造成闪烁。

## 当前进度

目前是**设计与核心模型的初始仓库，尚不是可以安装使用的调暗应用**。

| 部分 | 状态 |
| --- | --- |
| 可配置时间轴、确定性掩膜、恢复模型 | Swift 核心模型 |
| `gentle-night-preview` | 只输出 JSON 的模型预览，不控制屏幕 |
| 菜单栏应用、桌面遮罩、空闲与音频检测 | 待开发 |
| 指针隐藏、全屏兼容、HDR 与 OLED 实测 | 未验证 |

核心模型没有第三方依赖，不申请权限，不采集屏幕或音频，不修改系统设置。

## 计划中的使用体验

- 累计无活动满 **10 分钟**开始渐黑，满 **60 分钟**达到全黑；时间可调。这是最新设计的默认值。
- 可比较整屏渐暗、柔和收拢、概率消隐三种方式。
- 恢复沿同一组掩膜逆向进行，用时为 `0.8 × 当前渐黑进度` 秒：半程约 0.4 秒，全黑约 0.8 秒。
- 下方桌面继续更新，不使用冻结截图；目标是不改变原应用焦点，也不拦截恢复时的第一下输入。
- 音频与视频分开考虑。有音频输出流不一定代表实际有声音；轻量状态检测和准确静音判断之间的权限、兼容性取舍仍待原型验证。

以上是产品目标，尚未完成桌面遮罩与实机验收。Gentle Night 不保证避免烧屏，也不替代显示器自身的像素清理等维护功能。依赖截图、OCR 或像素取色的自动化可能受遮罩影响，需要单独验证。

## 运行核心模型

测试建议使用 Xcode 16 或更新版本及 Swift 6 工具链。仅安装 Command Line Tools 不保证测试库可用。初始 macOS 部署目标为 macOS 14 或更新版本。

```sh
swift test --disable-xctest
swift run gentle-night-preview --idle-minutes 35 --seed 42
swift run gentle-night-preview --mode probabilistic --idle-minutes 50 --width 96 --height 54 --seed 42
```

如果当前选择的是 Command Line Tools，可以只为本次测试选择 Xcode，不修改全局开发者设置：

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift test --disable-xctest
```

预览支持 `uniform`、`iris`、`probabilistic` 三种模式，只输出 JSON。采样网格不是已经验证的 OLED 物理像素映射。

## 下一步

1. 先做可恢复的单屏遮罩，验证输入、焦点、指针与全屏行为。
2. 在真实 OLED 上比较三种效果，检查 SDR/HDR、显示缩放及资源开销。
3. 验证轻量音频检测，再补充菜单栏控制与可调参数。

详细模型与验收条件见 [设计说明](docs/DESIGN.md)，开发约定见 [贡献指南](CONTRIBUTING.md)。项目采用 [MIT 许可](LICENSE)。
