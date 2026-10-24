# assets 目录

`app/assets/` 是 APK 内资源存储区，用于存放组件、脚本和二进制资源。

推荐结构：

```text
app/assets/
├── README.md
├── components/
│   └── README.md
├── components_Perfect/
│   └── README.md
├── scripts/
│   └── README.md
├── bin/
│   └── README.md
├── index.html
├── avatar.png
└── integrity.bin
```

说明：
- `components/`：普通组件目录
- `components_Perfect/`：优先级更高/修正后的组件目录
- `scripts/`：运行于 APK 内部的脚本
- `bin/`：可执行文件与辅助二进制
