# -*- coding: utf-8 -*-
"""前端 index.html 检查：JS 语法 + 桥接/DOM 交叉引用 + 下发命令串的拆分关键字反模式

修复记录（2026-10 审计）：
  - 旧版硬编码 C:\\Users\\...\\TeleAgent\\...\\apk-ui\\decoded\\assets\\index.html（早已不是源码目录），
    改成本脚本所在目录下的 assets/index.html。
  - 语法检查不再强制依赖 esprima：优先用 node --check（更准），不行再退回 esprima。
  - 新增：DOM id 交叉引用、bridge.* 与 Java 侧 @JavascriptInterface 方法名比对、
    「shell 关键字被拆成独立数组元素」的反模式检查
    （这类写法 join("; ") 后会生成 `do;` / `then;`，是真实的 shell 语法错误，
      曾导致 权限扫描 / 大文件 TOP20 / 模块恢复 三个功能整串解析失败而完全无效）。
"""
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
HTML = os.path.join(HERE, "assets", "index.html")
SMALI_BRIDGE = os.path.join(
    HERE, "smali", "com", "yazi", "toolbox", "MainActivity$Bridge.smali"
)

try:
    sys.stdout.reconfigure(errors="replace")
except Exception:
    pass

KEYWORDS = {"do", "then", "fi", "done", "else", "elif", "esac", "in", "do;", "then;"}


def read(path):
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        return f.read()


def js_syntax_check(js):
    node = None
    for cand in ("node", "node.exe"):
        try:
            subprocess.run([cand, "--version"], capture_output=True, check=True)
            node = cand
            break
        except Exception:
            pass
    if node:
        with tempfile.NamedTemporaryFile("w", suffix=".js", encoding="utf-8", delete=False) as t:
            t.write(js)
            tmp = t.name
        try:
            r = subprocess.run([node, "--check", tmp], capture_output=True, text=True)
            ok = (r.returncode == 0)
            print("JS 语法检查(node --check): %s (%d chars)" % ("OK" if ok else "FAIL", len(js)))
            if not ok:
                print(r.stderr.strip()[:2000])
            return ok
        finally:
            os.unlink(tmp)
    try:
        import esprima  # type: ignore
        esprima.parseScript(js)
        print("JS 语法检查(esprima): OK (%d chars)" % len(js))
        return True
    except ImportError:
        print("JS 语法检查: 跳过（未找到 node，也未安装 esprima）")
        return None
    except Exception as e:
        print("JS 语法错误:", e)
        return False


def check_keywords(html):
    problems = []
    blocks = re.findall(
        r"var\s+([A-Z_][A-Z0-9_]*)\s*=\s*\[(.*?)\]\s*\.join\(\s*\"; \"\s*\)",
        html, re.S)
    for name, body in blocks:
        elements = re.findall(r"^\s*'((?:[^'\\]|\\.)*)'\s*,?\s*$", body, re.M)
        for el in elements:
            s = el.strip()
            if s in KEYWORDS:
                problems.append("%s: 独立元素 '%s'（join 后会变成 `%s;` 语法错误）" % (name, el, s))
            elif s.endswith(" do") or s.endswith(" then"):
                problems.append("%s: 元素 '...%s' 以 %s 结尾，循环/条件体被拆到了下一个元素" % (name, s[-24:], s.split()[-1]))
    return len(blocks), problems


def main():
    if not os.path.isfile(HTML):
        print("找不到 index.html: %s" % HTML)
        return 1
    html = read(HTML)
    bad = 0

    scripts = re.findall(r"<script>(.*?)</script>", html, re.S)
    print("内联 <script> 块: %d" % len(scripts))
    for js in scripts:
        if js_syntax_check(js) is False:
            bad += 1

    checks = ["function vTool()", "function runTool(", "ENV_CMD", "DEV_CMD",
              "SYSCLEAN_CMD", "ZYG_CMD", "data-sec=", "cmdRun", "bEnv",
              "bDev", "bZyg", "bSysClean", "cmdInput", "function vNb(",
              "labRedteamRender", "labPerfRender", "labTeeRender", "labCrRender",
              "function safeIn(", "function exitBad(", "CB_TIMEOUT",
              'addEventListener("popstate"', "function runGClean("]
    print("\n--- 关键点 ---")
    miss_keys = []
    for name in checks:
        hit = name in html
        if not hit:
            miss_keys.append(name)
        print("  %s %s" % ("[OK]" if hit else "[X]", name))
    if miss_keys:
        bad += len(miss_keys)

    defined = set(re.findall(r"\bid\s*=\s*[\"']([A-Za-z0-9_\-]+)[\"']", html))
    for m in re.finditer(r"inputBox\(\s*[\"']([A-Za-z0-9_\-]+)[\"']", html):
        defined.add(m.group(1))
    used = set(re.findall(r"\$\(\s*[\"']([A-Za-z0-9_\-]+)[\"']\s*\)", html))
    used |= set(re.findall(r"getElementById\(\s*[\"']([A-Za-z0-9_\-]+)[\"']\s*\)", html))
    used -= {"null"}
    literals = set(re.findall(r"[\"']([A-Za-z0-9_\-]+)[\"']", html))
    miss = sorted(x for x in (used - defined) if x not in literals)
    print("\n--- DOM id ---")
    print("  HTML 定义 %d 个 / 引用 %d 个 / 疑似未定义 %d 个" % (len(defined), len(used), len(miss)))
    if miss:
        bad += 1
        print("  [X] %s" % ", ".join(miss))
    else:
        print("  [OK] 引用的 id 都能对上")

    print("\n--- bridge 桥接 ---")
    called = set(re.findall(r"bridge\.([A-Za-z_$][\w$]*)\s*\(", html))
    called |= set(re.findall(r"prom\(\s*[\"']([A-Za-z_$][\w$]*)[\"']", html))
    impl = set()
    if os.path.isfile(SMALI_BRIDGE):
        prev = None
        for line in read(SMALI_BRIDGE).splitlines():
            line = line.strip()
            m = re.match(r"\.method public ([A-Za-z_$][\w$]*)", line)
            if m:
                prev = m.group(1)
            if "JavascriptInterface" in line and prev:
                impl.add(prev)
    print("  JS 调用  : %s" % ", ".join(sorted(called)))
    print("  Java 实现: %s" % ", ".join(sorted(impl)))
    unknown = sorted(called - impl)
    if impl and unknown:
        bad += 1
        print("  [X] JS 调用了 Java 未实现的方法: %s" % ", ".join(unknown))
    elif impl:
        print("  [OK] 方法名一致")
    else:
        print("  [X] 未找到 Bridge.smali")

    print("\n--- 下发命令串结构 ---")
    n_blocks, problems = check_keywords(html)
    print("  扫描 %d 个 join(\"; \") 数组" % n_blocks)
    if problems:
        bad += len(problems)
        for p in problems:
            print("  [X] %s" % p)
    else:
        print("  [OK] 没有把 do/then/fi/done 拆成独立元素")

    print("\nRESULT: %s" % ("PASS" if bad == 0 else "FAIL (%d)" % bad))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
