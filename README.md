# 鸭子工具箱

这是一个面向 Android APK 反编译/修补/打包脚本工程的维护仓库。它用于：
- 以 Java 方式扩展 APK 原生逻辑
- 通过 Smali/DEX 回填链路保持工程可维护性
- 自动校验 JS / Shell / 资产完整性
- 一键打包并签名输出 APK

目录说明

```text
.
├── README.md
├── .gitignore
├── AndroidManifest.xml                  # 兼容保留：根目录清单
├── docs/
│   └── PROJECT_STRUCTURE.md
├── app/
│   ├── README.md
│   ├── assets/
│   ├── res/
│   └── smali/
├── scripts/
│   ├── _common.ps1                     # 公共工具函数（SDK / 路径解析）
│   ├── build/
│   │   ├── build_java.bat
│   │   └── build_java.ps1
│   ├── quality/
│   │   ├── check_js.py
│   │   └── check_sh.py
│   └── packaging/
│       ├── gen_baseline.ps1
│       └── rebuild_assetlist.py
├── tools/
│   └── integrity/
│       ├── RegenIntegrity.java
│       └── VerifyIntegrity.java
├── packaging/
│   └── 一键打包.bat
├── legacy/
│   └── README.md
└── build_java.bat                     # 兼容入口，转到 scripts/build/build_java.bat
```

工作流建议

1. 先编辑 Java 代码放入 `app/java/` 或对应模块目录。
2. 执行 `scripts/build/build_java.bat` 生成 Smali 并回填到 `smali/`。
3. 执行脚本检查：
   - `python scripts/quality/check_js.py`
   - `python scripts/quality/check_sh.py`
4. 重新打包：
   - `packaging/一键打包.bat`
5. 如需重算完整性：
   - `java tools/integrity/RegenIntegrity.java <apk_path>`

维护原则

- 统一使用相对路径，不再依赖硬编码 Windows 用户目录。
- 兼容旧脚本入口保留，避免历史调用中断。
- 新增脚本优先放到 `scripts/`、`tools/`、`app/` 等结构目录。
- 避免把所有内容混在根目录，易于后续扩展和 CI 接入。

当前状态

- 仓库已从“根目录杂乱型”整理为“脚本 + 工具 + 打包 + app 结构型”。
- 保留兼容层，便于历史脚本仍可继续调用。
- 若后续正式接入完整 APK 源码，可继续将 `app/assets`、`app/res`、`app/smali` 逐步补齐。
