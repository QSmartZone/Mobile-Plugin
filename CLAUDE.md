# mobile-plugin — quy tắc khi sửa chính plugin này

Áp dụng cho agent chỉnh sửa repo này. Không áp cho project cài plugin (project đích đọc `.agents/AGENTS.md` + `rules/`).

- Path cross-folder (`skills/` ↔ `rules/`, `agents/` ↔ `skills/`): luôn `${CLAUDE_PLUGIN_ROOT}/<path>`, không `../`.
- Thêm section markdown = giữ section cũ. Verify: `grep -c "## <heading cũ>" <file>` = 1.
- Lệnh CLI ghi vào skill/script: chạy thử `<tool> --help` hoặc `-list` trước, không viết theo trí nhớ.
- Fact có version (API level, RN/Flutter/iOS/Dart): ghi kèm mốc version.
- `SKILL.md` ≤300 từ; `description` ≤40 từ theo mẫu "làm gì / dùng khi / không dùng khi"; reference mở đầu bằng mục "Bẫy".
- Đổi skill/agent/rule → bump `version` trong `.claude-plugin/plugin.json`.
- Tiếng Việt cho nội dung; code, lệnh, tên tool giữ nguyên.
