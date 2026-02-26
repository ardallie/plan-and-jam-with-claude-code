# Claude Code status line

`.claude/statusline.sh` displays the active model, context window usage,
and current git branch in the Claude Code status line.

To install:

1. Copy the script to your home `.claude` directory:

```bash
mkdir -p ~/.claude
cp .claude/statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

2. Merge the following into `~/.claude/settings.json` (global config, not committed to the repo). If the file already exists, add only the `statusLine` key — do not overwrite existing keys.

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline.sh",
    "padding": 0
  }
}
```
