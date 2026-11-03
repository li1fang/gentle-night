# Gentle Night

[English](README.md)

原生 macOS 菜单栏渐黑原型：保持当前桌面运行，用透明遮罩实现整屏渐暗、柔和收拢和概率消隐。默认空闲 10 分钟开始、60 分钟全黑，活动后按进度在最多 0.8 秒内恢复。

## 构建与使用

需要 Xcode 16+（Swift 6）、macOS 14+；测试脚本还需要 Python 3。

```sh
bash scripts/build-app.sh
open "dist/Gentle Night.app"
```

菜单栏出现 ☾。自动模式初始关闭；可先点击 8 秒预览，再开启自动渐黑。设置可调整时间与恢复速度。音频保持仅判断输出流是否活跃，静音视频可能仍被视为活跃；macOS 14.2 以下或查询失败时保守保持可见。无需录屏、录音或辅助功能权限。

鼠标隐藏为实验选项，默认关闭，因此默认全黑画面仍可能留有系统指针。不会修改系统屏保或锁屏设置；需单独配置自动屏保。开启自动模式会临时防止空闲显示器休眠，退出时释放。

## 加速测试

```sh
bash scripts/test.sh --with-display
# 可选：真实全屏测试，3 秒开始、12 秒全黑、45 秒自动退出
bash scripts/run-accelerated.sh
```

完整测试包括虚拟一小时、9 项 Swift 测试、CLI、音频状态、126 次真实 GPU 渲染、局部窗口与打包签名检查。详见 [测试说明](docs/TESTING.md) 和 [执行计划](docs/IMPLEMENTATION.md)。截图/OCR 兼容、实际电视黑位、HDR、光标与长期保护收益仍需单独验收。

概率模式使用固定哈希阈值，尚未使用蓝噪声。GPU 二值遮罩不等于已验证 OLED 物理像素逐点熄灭，显示缩放可能将其混合。

[设计文档](docs/DESIGN.md) · [贡献指南](CONTRIBUTING.md) · [MIT 许可](LICENSE)
