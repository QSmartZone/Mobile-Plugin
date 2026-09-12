# ADR — Dart MCP server, không chỉ Bash

## Context

`rules/hot_reload.md` gọi tool `dtd`/`hot_reload` nhưng plugin không khai MCP server nào → trên Claude Code rule trỏ vào tool không tồn tại, model nhỏ dễ bịa tool.

## Decision

Thêm `.mcp.json` ở root plugin khai `dart mcp-server` (stdio, có sẵn trong Dart SDK ≥3.9, không package ngoài). Rule hot_reload gọi đúng tên tool MCP và có fallback "không có tool/app → bỏ qua, báo 1 dòng".

## Why

Đóng vòng analyze/test/hot_reload/runtime error bằng tool thay vì Bash parse output. Plugin cài project scope vẫn load `.mcp.json` root plugin; `install.sh` copy dotfile nên agy/dsh nhận file.

## Trade-offs

Máy không có `dart` trong PATH → server fail khởi động, Claude báo lỗi MCP 1 lần mỗi session. Chấp nhận: plugin mobile mặc định có Flutter SDK.

## Constraints

- `.mcp.json` chỉ 1 server `dart`, command `dart`, args `["mcp-server"]`, không path tuyệt đối.
- Không thêm hook (giữ constraint [multi-platform-support](../multi-platform-support.md)).
- Rule hot_reload: frontmatter có cả `paths:` (Claude) và `globs:` (Antigravity); luôn có bước fallback khi thiếu tool.
