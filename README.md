# 鸭子工具箱

这是一个面向 Android APK 反编译 / 修补 / 打包的工程脚本仓库，目标是把“散乱的根目录脚本”升级为真正的 APK 工程目录结构。

当前工程结构

```text
.
├── README.md
├── AndroidManifest.xml
├── apktool.yml
├── apktool.jar
├── .gitignore
├── app/
│   ├── README.md
│   ├── assets/
│   │   ├── README.md
│   │   ├── components/
│   │   └── components_Perfect/
│   ├── res/
│   │   └── README.md
│   ├── smali/
│   │   └── com/
│   │       └── yazi/
│   │           └── toolbox/
│   └── java/
│       └── README.md
├── scripts/
│   ├── _common.ps1
│   ├── build/
│   │   ├── build_java.bat
│   │   ├── build_java.ps1
│   │   └── README.md
│   ├── quality/
│   │   ├── check_js.py
│   │   └── check_sh.py
│   └── packaging/
│       ├── gen_baseline.ps1
│       ├── rebuild_assetlist.py
│       └── README.md
├── tools/
│   └── integrity/
│       ├── RegenIntegrity.java
│       └── VerifyIntegrity.java
├── packaging/
│   └── 一键打包.bat
├── docs/
│   └── PROJECT_STRUCTURE.md
├── legacy/
│   └── README.md
├── build_java.bat
├── gen_baseline.ps1
└── 一键打包.bat
```

工程规则

- `app/` 是实际 APK 工程区域，包含资产、资源、Smali 及 Java 模块。
- `scripts/` 专门用于构建、质量检查和资源处理。
- `tools/integrity/` 负责完整性校验与重算。
- `packaging/` 是正式打包入口，统一做 release 流程。
- `legacy/` 保留历史脚本兼容入口，便于平滑迁移。

建议使用流程

1. 在 `app/java/` 中放置新 Java 逻辑。
2. 执行 `scripts/build/build_java.bat`，生成 Smali 并回填到 `app/smali/`。
3. 执行 `python scripts/quality/check_js.py` 与 `python scripts/quality/check_sh.py`。
4. 执行 `packaging/一键打包.bat`，输出签名 APK。
5. 如需校验完整性，执行 `java tools/integrity/VerifyIntegrity.java <apk>`。

说明

- 本仓库已从“根目录散装状态”逐步演化为真正的 APK 工程结构。
- 旧入口脚本已保留为兼容层，确保历史脚本调用不立刻失效。
- 后续新增真实 APK 资源时，优先写入 `app/` 目录，而非继续堆到根目录。
