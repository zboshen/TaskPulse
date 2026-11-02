# 开发

macOS 15+，安装 Apple Command Line Tools：`xcode-select --install`。

```sh
./scripts/build.sh
./dist/TaskPulse.app/Contents/MacOS/TaskPulse --self-test
./scripts/package.sh
```

构建同时编译 arm64 和 x86_64，再用 lipo 合并为 Universal app。本地临时签名，无第三方 Swift 包依赖。Intel 产物完成交叉编译，尚未在 Intel 实机验证。

`--self-test` 检查任务优先级、已读过滤、账户/主机隔离、日期倒序、尺寸计算、位置移动和边界限制，使用 precondition，优化构建下仍会执行。真实状态验证可运行 `--dump`，仅在本机查看，勿将输出提交到仓库。

```sh
./dist/TaskPulse.app/Contents/MacOS/TaskPulse --preview --size medium /tmp/taskpulse-demo.png
```

截图模式只使用虚构任务；不会输出真实会话。`--demo` 启动演示模式，可在菜单退出。

## 来源

复用 [CodeNotch](https://github.com/vinzdg/codenotch) commit `6522e9f3ee0fe35d46e428b441e6e80b586eacbb` 的 `SideNotchShape.swift` 与 `NotchMotion.swift`，保留原 MIT 声明于 `LICENSE-Codenotch`。其余任务筛选、桌面布局、状态适配和偏好管理属于 TaskPulse。
