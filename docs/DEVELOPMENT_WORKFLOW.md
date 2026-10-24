# 开发流程文档

本文档用于说明工程的正常开发、验证和打包流程，适合从已有 APK 反编译工程继续维护。

## 1. 目录职责

- `app/java/`：正式 Java 源码目录
- `app/smali/`：编译回填后的 smali 代码
- `app/res/`：Android 资源目录
- `app/assets/`：包内资源和脚本目录
- `scripts/build/`：Java -> dex -> smali 编译链路
- `scripts/quality/`：JS 与 Shell 结构检查
- `scripts/packaging/`：组件基线、assetList、打包前校验
- `tools/integrity/`：完整性修复和校验
- `packaging/`：正式打包入口

## 2. 标准开发循环

### 2.1 编写 Java 功能

在 `app/java/` 中创建或编辑 Java 文件，保持包路径与实际 APK 包名一致。
例如：

```text
app/java/com/yazi/toolbox/
```

### 2.2 编译并回填 Smali

执行：

```bat
scripts\build\build_java.bat
```

或：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build\build_java.ps1
```

此过程会：
- 编译 Java 为 classes
- 生成 classes.dex
- 用 apktool 反编译替换包中的 Smali
- 将结果写到 `app/smali/`

### 2.3 进行自检

执行：

```bash
python scripts/quality/check_js.py
python scripts/quality/check_sh.py
```

检查内容：
- JS 语法有效性
- DOM / bridge 交叉引用
- Shell 块结构是否闭合
- 是否存在旧包名或危险命令

### 2.4 更新资源

如果新增资源，优先放入：

- `app/assets/components/`
- `app/assets/components_Perfect/`
- `app/assets/scripts/`
- `app/assets/bin/`

并同步更新 `scripts/packaging/gen_baseline.ps1` 或相关脚本逻辑。

### 2.5 重建 assetList / 完整性

执行：

```bash
python scripts/packaging/rebuild_assetlist.py
```

或：

```bash
java tools/integrity/RegenIntegrity.java <apk_path>
```

## 3. 打包流程

正式打包入口：

```bat
packaging\一键打包.bat
```

兼容入口：

```bat
一键打包.bat
```

打包时应保证：
- Java 已回填 Smali
- 资源清单已同步
- 整体性校验密文已重算
- 签名工具可用

## 4. 维护原则

- 不要继续把所有文件堆在根目录
- 只在根目录保留兼容入口，不保留真正的业务代码
- 每类脚本必须有明确职责
- 新增功能必须更新对应 README / 文档

## 5. 迁移说明

老脚本和旧目录入口仍保留为兼容层，目的是避免历史脚本在迁移期间失效。迁移完成后，可逐步减少 root 目录的文件数，最终仅保留最小入口和文档。
