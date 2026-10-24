# app/ 目录模板

这是真实 APK 工程的目录模板，后续所有业务代码、资源和 Smali 都应落在这里。

```text
app/
├── README.md
├── assets/
│   ├── README.md
│   ├── components/
│   │   └── README.md
│   ├── components_Perfect/
│   │   └── README.md
│   ├── scripts/
│   │   └── README.md
│   └── bin/
│       └── README.md
├── res/
│   ├── README.md
│   ├── values/
│   ├── layout/
│   └── drawable/
├── smali/
│   ├── README.md
│   └── com/
│       └── yazi/
│           └── toolbox/
└── java/
    ├── README.md
    └── com/
        └── yazi/
            └── toolbox/
```

说明：
- `assets/`：存放 APK 内资源，如 scripts、components、bin
- `res/`：Android 资源 XML / drawable / layout 等
- `smali/`：apktool 生成或回填的 smali 代码
- `java/`：开发中的 Java 源码，供构建脚本编译

后续新增功能时，优先在这些目录中落地，而不是继续堆在根目录。
