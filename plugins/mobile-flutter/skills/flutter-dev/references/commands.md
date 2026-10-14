# Flutter commands — when to run what

## Pitfalls

- `flutter analyze` / `flutter build` started in the background and awaited by notification: looks hung for minutes. Run short checks in the foreground with a Bash `timeout` and read the tail.
- `dart format` on a whole package rewrites unrelated lines when the repo mixes 80- and 120-column styles. Format only the files you changed.
- `flutter build apk|appbundle` to "check" a change: slow and verifies nothing a live run does not. Release artifacts only.
- Hand-editing generated files (`app_localizations*.dart`, `*.g.dart`): overwritten on the next run. Regenerate instead.
- Analyzing after every small edit in a multi-task feature: noise from half-finished work. Analyze once when the last task is done.

## When to run what

| Moment | Run | Do not run |
| --- | --- | --- |
| After editing a file / finishing one task | `dart format <changed files>` | `flutter analyze`, `flutter build` |
| All coding done (every task finished) | `flutter analyze --fatal-infos` in each touched package once, then live preview | — |
| Single-task change, or the user asks for a check now | analyze at the end of that task | — |

When delegating to a subagent, put this in its brief: format only the files it changed, no `flutter analyze` (the main session analyzes once after the last task), foreground verify commands only.

## Commands by usecase

| Usecase | Command / Action | Note |
| --- | --- | --- |
| Static analysis / lint | `flutter analyze --fatal-infos` (or `analyze_files` Dart MCP) | Stop at the first error |
| Format | `dart format <files>` | Changed files only |
| Live preview / debug UI and logic | `flutter run -d <device> --dart-define-from-file=<env>` | Hot reload enabled; flow in `references/dart-mcp.md` |
| Hot reload / restart, widget tree, runtime errors | Dart MCP tools | `references/dart-mcp.md` |
| End-to-end verify | `/mobile-flutter:verify` | analyze → live app → errors → widget tree |
| Dependency sync | `flutter pub get` | `--offline` when the network hangs |
| Clean stale build cache | `flutter clean && flutter pub get` | Also the first fix for dependency resolution errors |
| Localization update | `flutter gen-l10n` | After editing `.arb` |
| Code generation (retrofit, json_serializable) | `dart run build_runner build --delete-conflicting-outputs` | Fresh clone or after changing a client, DTO or `build.yaml`; skip if the repo has its own generate script |
| Release APK / bundle | `flutter build apk` / `flutter build appbundle` | Artifact delivery only, never verify/dev |

## Foreground, bounded, read the tail

```bash
cd <package> && flutter analyze --fatal-infos 2>&1 | tail -20
```

- One foreground Bash call, explicit `timeout: 300000`.
- Pass or fail = the last line plus the exit status. Fail → read the `error •` / `info •` lines in the tail, fix, rerun in the foreground.
- Background is for real long-running work only: `flutter run`, an emulator session.

## Recovery

### Orphan pub process holds the lock (>3 min, no output)

```bash
ps -eo pid,etime,command | grep -E "dart pub (get|outdated)" | grep -v grep
lsof -p <pid> -a -d cwd -Fn   # cwd in ~/.Trash or days-old etime = orphan
kill <pid>
```

### Network hang on analytics / pub (>2 min)

```bash
dart --suppress-analytics analyze --fatal-infos
```

or `flutter pub get --offline` when the cache is complete.
