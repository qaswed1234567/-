# 构建脚本说明

此目录包含 Java 编译和 Smali 回填相关脚本。

```text
scripts/build/
├── README.md
├── build_java.bat
├── build_java.ps1
```

工作流：
1. 维护 `app/java/` 中 Java 源码
2. 执行 `build_java.bat`
3. 自动生成类文件和 dex
4. 回填至 `app/smali/`
