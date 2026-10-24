# 鸭子工具箱

这是一个 Android APK 反编译 / 修补 / 打包工程仓库，目标是把原来散乱的根目录脚本整理为稳定的工程结构，并保持兼容入口，以便长期维护和扩展。

目录总览

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
│   │   ├── components_Perfect/
│   │   ├── scripts/
│   │   └── bin/
│   ├── res/
│   │   └── README.md
│   ├── smali/
│   │   └── README.md
│   └── java/
│       └── README.md
├── scripts/
│   ├── _common.ps1
│   ├── build/
│   │   ├── README.md
│   │   ├── build_java.bat
│   │   └── build_java.ps1
│   ├── quality/
│   │   ├── README.md
│   │   ├── check_js.py
│   │   └── check_sh.py
│   └── packaging/
│       ├── README.md
│       ├── gen_baseline.ps1
│       └── rebuild_assetlist.py
├── tools/
│   └── integrity/
│       ├── README.md
│       ├── RegenIntegrity.java
│       └── VerifyIntegrity.java
├── packaging/
│   └── 一键打包.bat
├── docs/
│   ├── PROJECT_STRUCTURE.md
│   ├── DEVELOPMENT_WORKFLOW.md
│   └── COMMAND_REFERENCE.md
├── legacy/
│   ├── README.md
│   └── MIGRATION_GUIDE.md
├── build_java.bat
├── gen_baseline.ps1
├── check_js.py
├── check_sh.py
├── rebuild_assetlist.py
├── RegenIntegrity.java
├── VerifyIntegrity.java
├── 一键打包.bat
└── build_java.ps1
```

核心目标

- 真实工程代码放到 `app/`：`java/`、`smali/`、`res/`、`assets/`
- 自动化脚本放到 `scripts/`：构建、质量检查、打包前验证
- 统一工具放到 `tools/`：完整性验证、签名与修复
- 根目录保留兼容入口，允许旧脚本调用不立即失效
- 后续开发统一遵循新目录结构，避免继续堆放脏脚本在 root

快速开始

1. 新增/修改 Java 源码
   进入 `app/java/`，按照包路径维护代码。

2. 编译 Java 为 Smali
   运行：
   - `scripts/build/build_java.bat`
   - 或 `powershell -File scripts/build/build_java.ps1`

3. 质量自检
   运行：
   - `python scripts/quality/check_js.py`
   - `python scripts/quality/check_sh.py`

4. 重新打包
   运行：
   - `packaging/一键打包.bat`
   - 或直接执行根目录兼容入口 `一键打包.bat`

5. 重算完整性校验
   运行：
   - `java tools/integrity/RegenIntegrity.java <apk>`
   - `java tools/integrity/VerifyIntegrity.java <apk>`

开发流程建议

- 先在 `app/java/` 中维护 Java 逻辑
- 再执行构建脚本生成 `smali/` 和 `classes.dex`
- 使用 `check_js.py` / `check_sh.py` 做早期验证
- 更新 `app/assets` 中相关资源或脚本文件
- 最后以 `packaging/一键打包.bat` 完成打包

兼容性说明

- 旧入口文件保留在根目录，但它们已经是兼容分发层，不再是主工作区。
- 新功能和新增脚本优先写入 `app/` 与 `scripts/`，避免继续在 root 落地。
- 旧脚本不会被立刻删除，便于平滑迁移，直到所有调用都切到新结构。

维护原则

- 使用相对路径，不依赖硬编码用户目录
- 将脚本按职责归档到 `scripts/build`、`scripts/quality`、`scripts/packaging`
- 资源分类放入 `app/assets` 与 `app/res`
- `smali/` 作为自动生成结果而非手写工作区
