#!/bin/sh
# Stop 時に transcript を走査し、being-ish の Skill 使用と成果物編集があれば
# skill-adherence-checker sub-agent によるチェックを main-agent に指示する
set -u

# この plugin を配布している marketplace 名
MARKETPLACE="being-ish"

# テストで差し替えられるよう環境変数を優先する
INSTALLED_PLUGINS="${SKILL_ADHERENCE_INSTALLED_PLUGINS:-$HOME/.claude/plugins/installed_plugins.json}"

input=$(cat)

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

# 無限ループ防止
stop_hook_active=$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null)
if [ "$stop_hook_active" = "true" ]; then
  exit 0
fi

transcript_path=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
if [ -z "$transcript_path" ] || [ ! -f "$transcript_path" ]; then
  exit 0
fi

# インストール情報から marketplace 配布の plugin 名を集める
# transcript より小さく走査が軽いため先に判定する
if [ ! -f "$INSTALLED_PLUGINS" ]; then
  exit 0
fi
marketplace_plugins=$(jq -r '.plugins | keys[]' "$INSTALLED_PLUGINS" 2>/dev/null \
  | sed -n "s/@${MARKETPLACE}\$//p")
if [ -z "$marketplace_plugins" ]; then
  exit 0
fi

# 各 Skill の手順内で checker を起動済みならこの hook は何もしない
# この hook はチェックが走らなかった場合のフォールバックとして働く
checked=$(jq -r '
  select(.type == "assistant")
  | .message.content[]?
  | select(.type == "tool_use" and .name == "Task")
  | .input.subagent_type // empty
' "$transcript_path" 2>/dev/null | grep -c "skill-adherence-checker")
if [ "$checked" -gt 0 ]; then
  exit 0
fi

# Skill ツール呼び出しから使用 Skill 名を集める
all_skills=$(jq -r '
  select(.type == "assistant")
  | .message.content[]?
  | select(.type == "tool_use" and .name == "Skill")
  | .input.skill // empty
' "$transcript_path" 2>/dev/null | sort -u)

if [ -z "$all_skills" ]; then
  exit 0
fi

# marketplace の plugin に属する Skill だけ残す
skills=""
for skill in $all_skills; do
  plugin_name=${skill%%:*}
  # 一覧と plugin 名の両方を改行で挟み、行全体の一致だけを拾う
  # 単純な *"$plugin_name"* では dev が dev-docs に部分一致してしまう
  case "
$marketplace_plugins
" in
    *"
$plugin_name
"*)
      skills="$skills $skill"
      ;;
  esac
done
skills=${skills# }

if [ -z "$skills" ]; then
  exit 0
fi

# Write / Edit / NotebookEdit の対象ファイルを成果物として集める
files=$(jq -r '
  select(.type == "assistant")
  | .message.content[]?
  | select(.type == "tool_use" and (.name == "Write" or .name == "Edit" or .name == "NotebookEdit"))
  | .input.file_path // .input.notebook_path // empty
' "$transcript_path" 2>/dev/null | sort -u)

# 現存するファイルだけ残す
existing_files=""
old_ifs=$IFS
IFS='
'
for f in $files; do
  if [ -f "$f" ]; then
    existing_files="$existing_files$f
"
  fi
done
IFS=$old_ifs

if [ -z "$existing_files" ]; then
  exit 0
fi

reason="このセッションでは Skill を使って成果物を作成した。Task ツールで skill-adherence:skill-adherence-checker sub-agent を起動し、次の使用 Skill と成果物を伝えて Skill 違反を検査させること。この識別子が見つからないときは skill-adherence-checker という名前の sub-agent を探すこと。違反が報告されたら成果物を修正すること。違反がなければ何もせず終了してよい。
使用 Skill: $skills
成果物:
$existing_files"

jq -n --arg reason "$reason" '{decision: "block", reason: $reason}'
