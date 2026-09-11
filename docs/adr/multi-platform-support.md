# ADR — Đa nền tảng: tái dùng pattern team-plugin, thêm scope user/project

## Context

`mobile-plugin` cần chạy được trên nhiều host giống `team-plugin` (repo chị em cùng `self-project/core`), thay vì chỉ Claude Code. Không muốn nghĩ lại từ đầu 1 pattern đã kiểm chứng.

## Decision

Tái dùng nguyên pattern **core + overlay** của team-plugin: 3 host — Claude Code/Desktop, Antigravity IDE + `agy`, DeepSeek Harness `dsh`. Core (`agents/ skills/ rules/`) không chứa manifest host nào; phần riêng host ở `.claude-plugin/` (Claude) và `.agents/` (Antigravity + dsh). Cài bằng **copy**, không symlink.

Khác biệt so với team-plugin:
1. **Không có hook** — bỏ hẳn `hooks.json`, `overlay_agy_hooks`, node prereq check trong `install.sh`.
2. **Thêm chọn scope user/project** — team-plugin chỉ cài user scope (global: `~/.claude`, `~/.gemini/config/plugins`, `~/.agents`). `mobile-plugin/install.sh` hỏi thêm scope trước khi cài:
   - `user` — giống team-plugin, cài vào thư mục global của host.
   - `project` — cài vào đúng project đang đứng (`$PWD` lúc gọi `./install.sh`). Với Claude: `claude plugin marketplace add <path> --scope project` rồi `claude plugin install mobile-dev@mobile --scope project` (CLI `claude` hỗ trợ sẵn `-s/--scope user|project|local`). Với agy/dsh: copy core vào `$PWD/.agents` thay vì thư mục global của host.

## Why

Nhiều project mobile riêng biệt (khác team/khách hàng) không phải lúc nào cũng muốn cài skill này global — project scope cho phép bật/tắt theo từng repo mà không ảnh hưởng cấu hình user-level dùng cho project khác.

## Trade-offs

Sửa `mobile-plugin` xong, các bản đã cài theo project scope ở project khác phải chạy lại `./install.sh --scope project` riêng từng nơi — không tự động đồng bộ như user scope (chỉ 1 chỗ).

## Constraints

- Không hook nào trong plugin này.
- `agents/*.md` KHÔNG khai `tools:` trong frontmatter (Antigravity strict tên tool lạ).
- Không thêm host thứ 4 ngoài Claude/agy/dsh.
- `install.sh` là POSIX shell, không dependency ngoài coreutils/git; cho project scope, `claude plugin marketplace add` phải chạy với `source` là đường dẫn tuyệt đối tới thư mục `mobile-plugin` (không phải symlink) để tránh lỗi resolve khi cwd của lệnh khác cwd của plugin gốc.
