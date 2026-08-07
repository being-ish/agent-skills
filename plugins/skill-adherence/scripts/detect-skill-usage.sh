#!/bin/sh
# Stop 時に marketplace の Skill を使った形跡を検知し、
# skill-adherence スキルによるチェックを main-agent に指示する
# 使用 Skill と成果物の対応付けはセッションの文脈を持つ main-agent に任せる
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

# checker を起動済みならこの hook は何もしない
# この hook は各 Skill の手順内でチェックが走らなかった場合のフォールバックとして働く
if grep -q "skill-adherence-checker" "$transcript_path" 2>/dev/null; then
  exit 0
fi

# transcript に Skill 名が現れるかだけを見る
# tool_use の構造に依存しないため、呼び出し形態が変わっても壊れにくい
used_skills=""
old_ifs=$IFS
IFS='
'
for name in $skill_names; do
  if grep -qF "$name" "$transcript_path" 2>/dev/null; then
    used_skills="$used_skills$name
"
  fi
done
IFS=$old_ifs

if [ -z "$used_skills" ]; then
  exit 0
fi

reason="このセッションでは marketplace の Skill を使った形跡がある。skill-adherence スキルの手順に従い、使ったそれぞれの Skill とその Skill で作成、変更したファイルの対応を自分で判断したうえで、Skill 遵守チェックを実施すること。チェックが不要と判断した場合はその理由を述べて終了してよい。
transcript に現れた Skill 名の候補:
$used_skills"

jq -n --arg reason "$reason" '{decision: "block", reason: $reason}'
