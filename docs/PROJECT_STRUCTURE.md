# 项目结构说明

为了降低根目录混乱，本仓库已按用途拆分到以下目录：

```text
scripts/
├── build/        # Java -> Smali / dex 生成
├── quality/      # JS / shell 自检
├── packaging/    # 组件基线、assetList 重建

tools/
└── integrity/    # APK 完整性校验与重算

packaging/
└── 一键打包.bat  # 统一打包入口

app/
├── manifest/
├── res/
├── smali/
└── assets/
```

兼容说明：
- 根目录中的历史脚本未立即删除，以避免旧脚本引用失效。
- 若后续正式接入完整 APK 工程，可把 `assets/`、`smali/`、`res/` 等目录移动到 `app/` 下，统一组织。
- 本结构适合脚本型 APK 修补工程和构建自动化流程。
