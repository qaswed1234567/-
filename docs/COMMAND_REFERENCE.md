# 命令参考

本文档示例所有常用命令，按新结构统一组织。

## 构建命令

```bat
scripts\build\build_java.bat
```

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build\build_java.ps1
```

## 质量检查

```bash
python scripts/quality/check_js.py
python scripts/quality/check_sh.py
```

## 资源归档和基线

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\packaging\gen_baseline.ps1
python scripts/packaging/rebuild_assetlist.py
```

## 打包

```bat
packaging\一键打包.bat
```

兼容入口：

```bat
一键打包.bat
```

## 完整性校验

```bash
java tools/integrity/VerifyIntegrity.java <apk_path>
java tools/integrity/RegenIntegrity.java <apk_path>
```

## 常用目录

```text
app/java/
app/smali/
app/res/
app/assets/

scripts/build/
scripts/quality/
scripts/packaging/

tools/integrity/
```
