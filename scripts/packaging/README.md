# 打包前脚本说明

此目录处理组件基线和 asset 清单。

```text
scripts/packaging/
├── README.md
├── gen_baseline.ps1
└── rebuild_assetlist.py
```

用途：
- 生成 `components.sha256` 基线
- 重建 `assetList()` 清单
- 在打包前校验资源和文件一致性
