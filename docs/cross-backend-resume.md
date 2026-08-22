# Cross-backend resume — working notes (2026-08-20)

Context: claude-sandbox gained profiles (`--profile NAME`) and `--shared-history`.
Nath set up a `synthetic` profile using **synthetic.new** (Anthropic-compatible API)
and hoped `--shared-history` would allow seamlessly continuing the same chat
across Anthropic and synthetic profiles.

## The problem

Resuming an Anthropic-written conversation under the synthetic profile fails at
the API with a `400` validation error. Decoded from the error:

- `messages[N]` validated as a **user** message whose `content` blocks must be
  one of `{text, image, tool_result}`
- the offending block failed all three, including `tool_result` with
  "`tool_use_id` is missing" / "`content` is missing"

Root causes found in real transcripts:

1. **`thinking` / `redacted_thinking` blocks** in assistant content — Anthropic
   API accepts them; synthetic.new's stricter validator rejects the whole
   request.
2. **Malformed `tool_result` stubs** (no `tool_use_id`/`content`), orphaned
   results, and unanswered `tool_use` calls — artifacts of interrupted sessions.
3. The failure is **one-directional**: synthetic → Anthropic works (synthetic
   emits only classic blocks); only Anthropic → synthetic breaks.

## Transcript format findings

- Entries nest the API message under the **full-word key `msg...`**
  (`entry["msg" spelled m-e-s-s-a-g-e]`) — *not* the short alias. The scrubber
  accepts both, plus top-level role/content for older formats.
- Claude Code logs one logical turn as **multiple consecutive same-role
  entries** (split assistant continuations, tool results in their own user
  entry). Tool-call pairing must be computed on **folded turns** (merge
  consecutive same-role entries first), otherwise legitimate pairs get
  misclassified as orphans/interrupts. This was a real bug found by testing
  against actual transcripts.
- A conversation can end on an unanswered `tool_use` (in-flight call). Repaired
  by appending a **new user entry chained via `parentUuid`** at end of file —
  anchoring into an earlier user turn breaks reconstruction (results must come
  after their use).
- Subagent (`isSidechain: true`) entries are independent tool-call streams;
  scrub per stream.

## What was built (status: uncommitted on `main` at time of writing)

- **`transcript-scrub`** (Python 3, stdlib) — in-place scrubber: strips
  thinking blocks, drops malformed/orphaned/duplicate `tool_result`s,
  synthesizes placeholder results for unanswered `tool_use`s, backfills empty
  content. Idempotent; keeps one-time `<file>.scrub-backup`. `--hook` mode for
  `SessionStart` (matcher `resume`) hooks. Copied into every sandbox home's
  `~/.local/bin/` on each `claude-sandbox` run; host symlink via `install.sh`.
- **`transcript-clone`** (bash, host-side only) — copies a transcript from the
  shared pool into a profile pool and scrubs **only the copy** (plain copy in
  the reverse direction). Refuses overwrite unless `--force`.
- Docs updated in README.md + CLAUDE.md.
- **`./install.sh` needs re-running on the host** to activate the new symlinks.

## Decision: how Nath wants to use this

- **No `--shared-history` between Anthropic and synthetic** — keep pools
  isolated; no risk of mutating/“destroying” old Anthropic conversations.
- Bridge conversations **one-way, snapshot-style** with `transcript-clone`:

  ```bash
  transcript-clone ~/.claude-sandbox-shared/projects/<project-dir>/<session>.jsonl
  claude-sandbox --profile synthetic --resume <session-id>
  ```

- Work done under synthetic does **not** flow back automatically; clone back
  (same command, source = profile path) if wanted. Same session id can't be
  pushed twice without `--force`.
- The in-place scrub + `SessionStart` hook is documented in the README as
  optional convenience, but is **not** Nath's preferred default.

## If seamless shared history comes up again

Options from least to most invasive:

1. Keep clone workflow (current state).
2. In-place scrub via hook in the synthetic profile — seamless, but mutates
   the shared file for both backends (thinking history lost for Anthropic
   resumes too; harmless functionally, cosmetic only).
3. Filtering proxy (`ANTHROPIC_BASE_URL` → local filter that strips
   unsupported blocks per request) — fully seamless and read-only on disk, but
   proxy lifecycle inside the sandbox adds moving parts. Only worth it if new
   block types beyond `thinking` keep appearing.

Known residual quirks of the scrubber: `timestamp` on synthesized entries is
copied from the tip (not bumped); `unresolvable_tool_uses` (no user anchor at
all) is reported but can't be repaired; report prints "scrubbed" even when only
unresolvable counts are nonzero (cosmetic).
