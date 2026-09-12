# ADR — Agent mỏng, không xoá

## Context

4 file `agents/*-expert.md` lặp 80-90% nội dung `skills/*/SKILL.md` (danh sách references + nguyên tắc). Sửa 1 rule phải sửa 2 chỗ. Trên Claude Code, link tương đối `../skills/...` trong subagent không resolve được.

## Decision

Giữ 4 agent, thân ≤80 từ: 1 dòng gọi skill theo tên plugin-qualified (`mobile-dev:<skill>`) + 3-4 dòng scope-stop riêng của vai. Không liệt kê references, không lặp nguyên tắc.

## Why

Antigravity/dsh spawn subagent theo `agents/<role>.md`; xoá agent là mất `invoke_subagent` theo vai trên 2 host đó.

## Trade-offs

Agent không tự đủ; phải load skill mới có kiến thức. Chấp nhận vì skill là nguồn sự thật duy nhất.

## Constraints

- Agent body ≤80 từ, không có mục "Nguồn skill" liệt kê references.
- Frontmatter giữ 5 key hiện có, KHÔNG `tools:` (theo [multi-platform-support](../multi-platform-support.md)).
- Trỏ skill bằng tên `mobile-dev:<skill>`, không đường dẫn tương đối.
