# Java 源码目录

这里用于保留真实 Java 源码，供 `build_java.ps1` 编译成 dex 并回填到 smali。

建议结构：

```text
app/java/
├── com/
│   └── yazi/
│       └── toolbox/
```

后续新增 Java 功能时，优先在这里维护，避免散落在 root 目录。
