# -*- coding: utf-8 -*-
"""assets/scripts/*.sh 结构自检：if/fi、do/done、case/esac 配对 + 常见硬伤

修复记录：
  - 旧版硬编码 C:\\Users\\...\\TeleAgent\\...\\apk-ui\\decoded\\assets\\scripts（早已不是源码目录），
    改成本脚本所在目录下的 assets/scripts/。
  - 旧版用 "括号数量是否相等" 判断配对，字符串里的括号会误报；现改为
    先剥离字符串与注释，再按关键字计数与栈式配对，能定位未闭合块的行号。
  - 新增：旧包名 com.heci.toolbox、危险 rm -rf 备份目录、无 shebang 等回归检查。
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SCRIPTS = os.path.join(HERE, "assets", "scripts")

# Windows 控制台默认可能是 GBK，避免打印非 GBK 字符时崩掉
try:
    sys.stdout.reconfigure(errors="replace")
except Exception:
    pass

FORBIDDEN = [
    (r"com\.heci\.toolbox", "残留旧包名（真实包名 com.yazi.toolbox）"),
    (r"rm -rf /sdcard/(TWRP|OrangeFox|Fox)\b", "删除第三方 Recovery 备份目录"),
    (r"rm -rf /sdcard/\.twrps", "删除 TWRP 设置目录"),
    (r'case\s+"\$name"\s+in\s+\*sh\*', "用子串 *sh* 匹配文件名（会命中 Screenshots 等目录）"),
    (r'elif \[ -x "\$BASE/bin/busybox-arm64-v8a" \]', "硬编码 arm64 busybox 作兜底"),
]


def mask_heredocs(src):
    """把 heredoc（<<EOF / <<'EOF' / <<-EOF）的正文替换成空行。

    为什么需要：脚本里会内嵌 awk/python 程序，里面的 if/while/for 不是 shell 关键字，
    不屏蔽会被误判成"未闭合的 shell 块"。保留换行以便行号不变。
    """
    lines = src.split("\n")
    out = []
    i = 0
    pend = []
    while i < len(lines):
        line = lines[i]
        out.append(line)
        for m in re.finditer(r"<<(-?)\s*(['\"]?)([A-Za-z_][A-Za-z0-9_]*)\2", line):
            pend.append((m.group(3), m.group(1) == "-"))
        i += 1
        while pend and i < len(lines):
            delim, dash = pend[0]
            while i < len(lines):
                cur = lines[i]
                cmp_line = cur.lstrip("\t") if dash else cur
                if cmp_line.strip("\r") == delim:
                    break
                out.append("")
                i += 1
            if i < len(lines):
                out.append(lines[i])
                i += 1
            pend.pop(0)
    return "\n".join(out)


def strip_code(src):
    """剥离单/双引号字符串与 # 注释，保留换行，便于按行号定位。"""
    out = []
    quote = None
    i = 0
    n = len(src)
    while i < n:
        c = src[i]
        if quote:
            if quote == '"' and c == "\\":
                out.append(" ")
                i += 1
                out.append("\n" if i < n and src[i] == "\n" else " ")
                i += 1
                continue
            if c == quote:
                quote = None
            out.append("\n" if c == "\n" else " ")
            i += 1
            continue
        if c in "'\"":
            quote = c
            out.append(" ")
            i += 1
            continue
        if c == "\\":
            out.append(" ")
            i += 1
            out.append("\n" if i < n and src[i] == "\n" else " ")
            i += 1
            continue
        if c == "#":
            while i < n and src[i] != "\n":
                out.append(" ")
                i += 1
            if i < n:
                out.append("\n")
            continue
        out.append(c)
        i += 1
    return "".join(out)


def strip_comments(src):
    """只剥离 # 注释，保留字符串内容（路径类规则写在引号里，不能连字符串一起剥）。"""
    out = []
    i = 0
    n = len(src)
    quote = None
    while i < n:
        c = src[i]
        if quote:
            out.append(c)
            if quote == '"' and c == "\\":
                i += 1
                if i < n:
                    out.append(src[i])
            elif c == quote:
                quote = None
            i += 1
            continue
        if c in "'\"":
            quote = c
            out.append(c)
            i += 1
            continue
        if c == "#":
            while i < n and src[i] != "\n":
                out.append(" ")
                i += 1
            continue
        out.append(c)
        i += 1
    return "".join(out)


def check_structure(name, code):
    """栈式配对，返回 (未闭合列表, 错误列表)"""
    opens = {"if": "if", "while": "loop", "until": "loop", "for": "loop", "case": "case"}
    errs = []
    stack = []
    for m in re.finditer(r"(?<![A-Za-z0-9_])(if|fi|while|until|for|do|done|case|esac)"
                         r"(?![A-Za-z0-9_=])", code):
        kw = m.group(1)
        line = code.count("\n", 0, m.end()) + 1
        if kw in opens:
            stack.append((opens[kw], kw, line))
        elif kw in ("fi", "done", "esac"):
            want = {"fi": "if", "done": "loop", "esac": "case"}[kw]
            if not stack:
                errs.append("第 %d 行 %s 无匹配开块" % (line, kw))
            else:
                kind, o, ol = stack.pop()
                if kind != want:
                    errs.append("第 %d 行 %s 与 第 %d 行 %s 类型不符" % (line, kw, ol, o))
    return stack, errs


def main():
    if not os.path.isdir(SCRIPTS):
        print("找不到脚本目录: %s" % SCRIPTS)
        return 1
    files = sorted(f for f in os.listdir(SCRIPTS) if f.endswith(".sh"))
    print("检查 %d 个脚本：%s\n" % (len(files), SCRIPTS))
    bad = 0
    for name in files:
        path = os.path.join(SCRIPTS, name)
        with open(path, "r", encoding="utf-8", errors="replace") as f:
            raw = mask_heredocs(f.read())
        code = strip_code(raw)
        issues = []

        stack, errs = check_structure(name, code)
        issues.extend(errs)
        for kind, kw, line in stack:
            issues.append("第 %d 行 %s 未闭合" % (line, kw))

        counts = {}
        for kw in ("do", "done", "if", "fi", "case", "esac"):
            counts[kw] = len(re.findall(
                r"(?<![A-Za-z0-9_])%s(?![A-Za-z0-9_=])" % kw, code))
        if counts["do"] != counts["done"]:
            issues.append("do=%d done=%d 数量不等" % (counts["do"], counts["done"]))
        if counts["if"] != counts["fi"]:
            issues.append("if=%d fi=%d 数量不等" % (counts["if"], counts["fi"]))
        if counts["case"] != counts["esac"]:
            issues.append("case=%d esac=%d 数量不等" % (counts["case"], counts["esac"]))

        if not raw.startswith("#!"):
            issues.append("缺少 shebang（非 `sh <file>` 调用时会 ENOEXEC）")
        if raw.startswith("\ufeff"):
            issues.append("含 UTF-8 BOM")
        if "\r\n" in raw:
            issues.append("含 CRLF 行尾")

        for pat, desc in FORBIDDEN:
            nc = strip_comments(raw)      # 注释里引用的“反面示例”不算问题
            for m in re.finditer(pat, nc):
                line = nc.count("\n", 0, m.start()) + 1
                issues.append("第 %d 行 %s" % (line, desc))

        if issues:
            bad += 1
            print("[X] %s" % name)
            for it in issues:
                print("    - %s" % it)
        else:
            print("[OK] %s" % name)

    print("\nRESULT: %s" % ("PASS" if bad == 0 else "FAIL (%d 个脚本有问题)" % bad))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
