# -*- coding: utf-8 -*-
"""重建 MainActivity.smali 中 assetList() 方法为当前 assets 的真实清单

修复记录：
  - 旧版硬编码 C:\\Users\\...\\TeleAgent\\...\\apk-ui\\decoded\\smali\\...（早已不是源码目录），
    改成本脚本所在目录下的 smali/...。
  - 旧版把 36 个文件名硬编码在脚本里 + assert N == 36：资产一升级就要手改两处，
    实际已经漂移过（旧版清单里还是 Aazycbl-...-218 之流的旧名）。现在直接从
    assets/ 目录扫描生成，不再有第二份清单。
  - 旧版用 open(...,"w") 在 Windows 上会把换行写成 CRLF，把原本 LF 的 smali 弄成混合行尾；
    现在显式 newline="\\n"。

用法：python rebuild_assetlist.py [--check]
      --check 只报告差异，不写文件
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ASSETS = os.path.join(HERE, "assets")
SMALI = os.path.join(HERE, "smali", "com", "yazi", "toolbox", "MainActivity.smali")

DIRS = ["scripts", "bin", "components", "components_Perfect"]


def collect():
    files = []
    for d in DIRS:
        root = os.path.join(ASSETS, d)
        if not os.path.isdir(root):
            print("警告：目录不存在，已跳过 %s" % root)
            continue
        for name in sorted(os.listdir(root)):
            p = os.path.join(root, name)
            if os.path.isfile(p):
                files.append("%s/%s" % (d, name))
    return files


def build_method(files):
    n = len(files)
    lines = [".method private assetList()[Ljava/lang/String;",
             "    .locals 3",
             "",
             "    .prologue",
             "    const/16 v0, 0x%x" % n,
             "",
             "    new-array v0, v0, [Ljava/lang/String;",
             ""]
    for i, f in enumerate(files):
        lines.append("    const/4 v1, 0x%x" % i if i <= 7 else "    const/16 v1, 0x%x" % i)
        lines.append("")
        lines.append('    const-string v2, "%s"' % f)
        lines.append("")
        lines.append("    aput-object v2, v0, v1")
        lines.append("")
    lines += ["    return-object v0", ".end method"]
    return "\n".join(lines)


def main():
    check_only = "--check" in sys.argv
    if not os.path.isfile(SMALI):
        print("找不到 smali 文件：%s" % SMALI)
        return 1
    files = collect()
    print("assets 实际清单：%d 项" % len(files))
    if len(files) > 32767:
        print("项目过多，const/16 放不下 array size")
        return 1

    with open(SMALI, "r", encoding="utf-8", newline="") as f:
        src = f.read()
    pat = re.compile(r"\.method private assetList\(\)\[Ljava/lang/String;.*?\.end method", re.S)
    m = pat.search(src)
    if not m:
        print("assetList 方法未找到")
        return 1

    old = m.group(0)
    nl = "\r\n" if "\r\n" in src else "\n"
    new = build_method(files)
    if nl != "\n":
        new = new.replace("\n", nl)

    def names(block):
        return re.findall(r'const-string v2, "([^"]+)"', block)

    old_names, new_names = names(old), names(new)
    added = [x for x in new_names if x not in old_names]
    removed = [x for x in old_names if x not in new_names]
    print("旧清单 %d 项 / 新清单 %d 项" % (len(old_names), len(new_names)))
    for x in added:
        print("  + %s" % x)
    for x in removed:
        print("  - %s" % x)
    if old_names == new_names:
        print("assetList 内容一致（顺序也相同），无需修改")
        return 0
    if check_only:
        print("（--check 模式，未写文件）")
        return 2
    with open(SMALI, "w", encoding="utf-8", newline="") as f:
        f.write(src[:m.start()] + new + src[m.end():])
    print("assetList 已重建：%d 项（0x%x），行尾保持 %s" % (len(files), len(files), "CRLF" if nl == "\r\n" else "LF"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
