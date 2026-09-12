# ADR — Verify bằng script + command, không chỉ prose

## Context

Chỉ Android (qua `android-cli`) đóng được vòng edit → build → run. Android/iOS SKILL.md không có checklist lệnh verify. Mỗi session agent tự grep pubspec/package.json/build.gradle để đoán stack, tốn token.

## Decision

Thêm `scripts/detect-stack.sh` (POSIX, in ≤6 dòng: platform, lib chính, test runner, lệnh analyze/test/build) và `commands/verify.md` (`/mobile-dev:verify`: chạy detect-stack rồi analyze + test đúng platform). Mỗi SKILL.md kết bằng mục "Verify" 3-5 lệnh cụ thể.

## Why

Lệnh chạy được là bằng chứng; prose "nhớ chạy test" bị model nhỏ bỏ qua. Script 1 lần thay grep lặp mỗi session.

## Trade-offs

Thêm 2 file phải bảo trì khi stack đổi. Không hook nên vẫn cần agent chủ động gọi.

## Constraints

- Script POSIX sh, không dependency ngoài coreutils/grep; không có stack → in `unknown`, exit 0.
- Command chỉ chạy lệnh read-only/test, không build release, không cài package.
- Mục Verify trong SKILL.md: lệnh cụ thể, mỗi dòng 1 lệnh + expected.
