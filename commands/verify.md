---
description: Detect mobile stack rồi chạy analyze + test liên quan, dán output
allowed-tools: Bash(sh:*), Bash(flutter:*), Bash(./gradlew:*), Bash(xcodebuild:*), Bash(npx:*), Bash(git diff:*)
---

Verify code mobile hiện tại, dir tuỳ chọn: `$ARGUMENTS` (mặc định `.`).

1. Chạy `sh ${CLAUDE_PLUGIN_ROOT}/scripts/detect-stack.sh $ARGUMENTS`.
2. Chạy đúng lệnh ở dòng `analyze:` output bước 1.
3. Chạy test cho file liên quan `git diff --name-only`, không chạy full suite trừ khi user yêu cầu rõ.
4. Dán output rút gọn: dòng lỗi đầu tiên (nếu có) + tổng số pass/fail.
5. Không build release, không cài package mới. Nếu fail, báo lại và dừng — không tự sửa khi chưa được yêu cầu.
