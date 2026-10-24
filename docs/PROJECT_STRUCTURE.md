# 项目结构说明

本仓库已经按真实 APK 工程结构进行组织，核心思想是：

- `app/` 作为实际工程目录
- `scripts/` 作为构建/检查/修补脚本目录
- `tools/` 作为辅助工具目录
- `packaging/` 作为发布与打包入口
- `legacy/` 作为兼容层，保留历史脚本引用

目录分工

```text
app/
├── assets/       # APK 资源目录，包含 components / scripts 等
├── res/          # 资源文件目录
├── smali/        # 反编译后的 smali 代码
├── java/         # 维护 Java 代码的主目录

scripts/
├── build/        # Java -> dex -> smali 回填
├── quality/      # JS / shell 自检
├── packaging/    # 组件清单与资源更新脚本

tools/
└── integrity/    # APK 签名/校验完整性工具

packaging/
└── 一键打包.bat  # 正式打包入口
```

迁移说明

- 旧脚本入口仍存在，但转发到新目录。
- 新增功能和后续维护应优先放在 `app/` 与 `scripts/` 中。
- 不再建议继续把文件堆积在根目录中。
