# 完整性工具说明

此目录负责 APK 完整性校验和重算。

```text
tools/integrity/
├── README.md
├── RegenIntegrity.java
└── VerifyIntegrity.java
```

说明：
- `RegenIntegrity.java`：根据当前包重算 `integrity.bin`
- `VerifyIntegrity.java`：校验当前 APK 是否被篡改或失配
