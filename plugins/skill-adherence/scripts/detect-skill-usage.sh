#!/bin/sh
# Stop 時に marketplace の Skill を使った形跡を検知して skill-adherence スキルによるチェックを main-agent に指示する
# 使用 Skill と成果物の対応付けはセッションの文脈を持つ main-agent に任せる
set -u

# この plugin を配布している marketplace 名
MARKETPLACE="being-ish"

# テストで差し替えられるよう環境変数を優先する
INSTALLED_PLUGINS="${SKILL_ADHERENCE_INSTALLED_PLUGINS:-$HOME/.claude/plugins/installed_plugins.json}"
LOG_DIR="${SKILL_ADHERENCE_LOG_DIR:-$HOME/.claude/plugins/data/skill-adherence-$MARKETPLACE}"

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

# checker を起動済みならこの hook は何もしない
# この hook は各 Skill の手順内でチェックが走らなかった場合のフォールバックであり、一度 checker が走ったセッションではその後さらに作業しても発火しない
# 主経路は各 Skill 内のチェック手順なので、この取りこぼしは許容する
# 判定は tool_use の subagent_type に限る
# 単純な文字列 grep では、agent 一覧を載せた system-reminder に checker 名が常に含まれるため全セッションで真になる
checked=$(jq -r '
  select(.type == "assistant")
  | .message.content[]?
  | select(.type == "tool_use")
  | .input.subagent_type // empty
' "$transcript_path" 2>/dev/null | grep -c "skill-adherence-checker")
if [ "$checked" -gt 0 ]; then
  exit 0
fi

if [ ! -f "$INSTALLED_PLUGINS" ]; then
  exit 0
fi

# インストール済み plugin から marketplace 配布の Skill 名を集める
# installPath 配下の skills ディレクトリ名が Skill 名になる
skill_names=""
plugin_entries=$(jq -r --arg mp "@${MARKETPLACE}" '
  .plugins
  | to_entries[]
  | select(.key | endswith($mp))
  | (.key | rtrimstr($mp)) + "\t" + (.value[0].installPath // "")
' "$INSTALLED_PLUGINS" 2>/dev/null)

tab=$(printf '\t')
while IFS="$tab" read -r plugin install_path; do
  [ -z "$plugin" ] && continue
  [ -z "$install_path" ] && continue
  for skill_dir in "$install_path"/skills/*/; do
    [ -d "$skill_dir" ] || continue
    skill=$(basename "$skill_dir")
    skill_names="$skill_names$plugin:$skill
"
  done
done <<EOF
$plugin_entries
EOF

if [ -z "$skill_names" ]; then
  exit 0
fi

# Skill ツールの呼び出し記録から使用 Skill 名を集める
# 単純な文字列 grep では、利用可能な Skill 一覧を載せた system-reminder に全 Skill 名が含まれるため常に全件ヒットする
invoked=$(jq -r '
  select(.type == "assistant")
  | .message.content[]?
  | select(.type == "tool_use" and .name == "Skill")
  | .input.skill // empty
' "$transcript_path" 2>/dev/null | sort -u)

if [ -z "$invoked" ]; then
  exit 0
fi

# marketplace 配布の Skill だけ残す
used_skills=""
old_ifs=$IFS
IFS='
'
for name in $skill_names; do
  for used in $invoked; do
    if [ "$name" = "$used" ]; then
      used_skills="$used_skills$name
"
      break
    fi
  done
done
IFS=$old_ifs

if [ -z "$used_skills" ]; then
  exit 0
fi

# 発火履歴を残し、この hook が必要かを頻度で判断できるようにする
# 発火は取りこぼしの上限を示す信号でしかない
# 成果物の有無までは見ないため、チェックが実際に必要だったかは transcript を見て人が判断する
# ログの書き込みに失敗しても block 処理は続ける
session_id=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
if mkdir -p "$LOG_DIR" 2>/dev/null; then
  jq -cn \
    --arg ts "$(date '+%Y-%m-%dT%H:%M:%S%z')" \
    --arg sid "$session_id" \
    --arg cwd "$cwd" \
    --arg skills "$used_skills" \
    '{
      timestamp: $ts,
      session_id: $sid,
      cwd: $cwd,
      skills: ($skills | split("\n") | map(select(. != "")))
    }' >> "$LOG_DIR/fallback.log" 2>/dev/null
fi

reason="このセッションでは marketplace の Skill を使った形跡がある。skill-adherence スキルの手順に従い、使ったそれぞれの Skill とその Skill で作成、変更したファイルの対応を自分で判断したうえで、Skill 遵守チェックを実施すること。チェックが不要と判断した場合はその理由を述べて終了してよい。
transcript に現れた Skill 名の候補:
$used_skills"

jq -n --arg reason "$reason" '{decision: "block", reason: $reason}'
