# 双模式平台固定版本示例（0014 §6）

[English](./lock-examples.md) | **中文**

# 离线（气隙）：将 tarball 放到 `artifacts/`，使用相对路径。
# 在线：固定公开 findesk-std Release URL（相同字节 + integrity）。

## 离线 — findesk.lock.json

```json
{
  "schemaVersion": 1,
  "findesk": {
    "package": "findesk-desktop-sdk",
    "version": "2.1.16",
    "artifact": "artifacts/findesk-desktop-sdk-2.1.16.tar.gz",
    "integrity": "sha256-REPLACE_WITH_DIGEST"
  }
}
```

## 在线 — findesk.lock.json

```json
{
  "schemaVersion": 1,
  "findesk": {
    "package": "findesk-desktop-sdk",
    "version": "2.1.16",
    "artifact": "https://github.com/finogeeks/findesk-std/releases/download/v2.1.16/findesk-desktop-sdk-2.1.16.tar.gz",
    "integrity": "sha256-REPLACE_WITH_DIGEST"
  }
}
```

从对应 Release 上的 `.lock.snippet.json` 或 `.sha256` 资产复制 `integrity`。
