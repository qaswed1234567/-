# app/ 目录说明

本目录作为真实 APK 工程目录的主入口。

建议目录结构：

```text
app/
├── assets/
├── res/
├── smali/
├── java/
└── README.md
```

说明：
- `assets/` 用于存放 APK 资源与脚本任务目录
- `res/` 存放 Android 资源 XML 和图片资源
- `smali/` 存放回填后的 smali 代码
- `java/` 存放 Java 源码，供 `build_java.ps1` 编译

当前仓库中，目录已保留占位，后续可以直接填充真实 APK 源码。
