# 鸭子工具箱

这是一个 Android APK 工程脚本与打包工具集合，包含：
- 构建/补丁脚本
- Java/Smali 生成工具
- 资产完整性校验工具
- Web/脚本质量检查脚本
- 一键打包入口

项目结构说明：

```text
.
├── README.md
├── AndroidManifest.xml                  # 兼容层：保留原始 Android 清单
├── docs/
│   └── PROJECT_STRUCTURE.md            # 结构说明
├── app/                                # 业务应用目录（占位，后续放 APK 资源 / smali / res）
│   ├── manifest/
│   ├── res/
│   └── smali/
├── packaging/
│   └── 一键打包.bat                    # 一键打包入口（推荐使用）
├── scripts/
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
├── legacy/                             # 兼容层：保留原根目录脚本，避免历史脚本失效
│   └── README.md
└── .gitignore
```

说明：
- 目前仓库中保留少量原有根目录脚本，以兼容历史流程。
- 建议后续统一把实际业务代码放入 `app/`、`scripts/`、`tools/` 三大目录下，避免根目录散乱。
- 相关脚本默认使用 `smali/` 与 `assets/` 目录结构，后续可继续补齐真实 APK 源码目录。
