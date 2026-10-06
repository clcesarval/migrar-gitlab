#!/usr/bin/env bash
# verify-migration.sh — read-only reconciliation between a source and a target GitLab group.
#
# For every project under SOURCE_GROUP (recursively), the script checks that a project
# with the same relative path exists under TARGET_GROUP, and compares:
#   - number of branches
#   - number of tags
#   - the commit each tag points to (tags are not rewritten by the migration)
# Default-branch commits are reported but not treated as mismatches, because
# CI files rewritten during migration (replace_gitlab-ci.sh) change them on purpose.
#
# Nothing is created, changed or deleted. Output: a CSV report and a summary.
#
# Requirements: bash, curl, jq. Tokens need read_api scope.

set -uo pipefail

SOURCE_URL="https://gitlab.SOURCE.com"
SOURCE_TOKEN="YOUR_SOURCE_TOKEN"
SOURCE_GROUP="old-group"                         # full path of the source root group

TARGET_URL="https://gitlab.TARGET.com"
TARGET_TOKEN="YOUR_TARGET_TOKEN"
TARGET_GROUP="new-root-group/subgroup/legacy"    # full path where the source tree was recreated

REPORT="verification_report.csv"

urlencode() { jq -rn --arg v "$1" '$v|@uri'; }

# GET every page of a paginated API endpoint and print one JSON array.
# Usage: api_all <base_url> <token> <path-with-query>
api_all() {
  local base="$1" token="$2" path="$3" page=1 out="[]" chunk sep="?"
  [[ "$path" == *"?"* ]] && sep="&"
  while :; do
    chunk=$(curl -sf --header "PRIVATE-TOKEN: $token" \
      "$base/api/v4/${path}${sep}per_page=100&page=$page") || { echo "__ERROR__"; return 1; }
    [[ "$(jq 'length' <<<"$chunk")" -eq 0 ]] && break
    out=$(jq -s 'add' <(echo "$out") <(echo "$chunk"))
    [[ "$(jq 'length' <<<"$chunk")" -lt 100 ]] && break
    page=$((page + 1))
  done
  echo "$out"
}

echo "project,status,src_branches,dst_branches,src_tags,dst_tags,tag_mismatches,default_branch_head" > "$REPORT"

src_projects=$(api_all "$SOURCE_URL" "$SOURCE_TOKEN" \
  "groups/$(urlencode "$SOURCE_GROUP")/projects?include_subgroups=true&with_shared=false&simple=true")
if [[ "$src_projects" == "__ERROR__" ]]; then
  echo "❌ Could not list source projects. Check SOURCE_URL, SOURCE_TOKEN and SOURCE_GROUP." >&2
  exit 1
fi

total=$(jq 'length' <<<"$src_projects")
ok=0; missing=0; mismatch=0; errors=0
echo "🔎 Checking $total source projects..."

while read -r src_path; do
  rel="${src_path#"$SOURCE_GROUP"/}"
  dst_path="$TARGET_GROUP/$rel"
  src_enc=$(urlencode "$src_path"); dst_enc=$(urlencode "$dst_path")

  if ! curl -sf -o /dev/null --header "PRIVATE-TOKEN: $TARGET_TOKEN" \
      "$TARGET_URL/api/v4/projects/$dst_enc"; then
    echo "$rel,MISSING,,,,,," >> "$REPORT"; missing=$((missing + 1)); continue
  fi

  sb=$(api_all "$SOURCE_URL" "$SOURCE_TOKEN" "projects/$src_enc/repository/branches")
  db=$(api_all "$TARGET_URL" "$TARGET_TOKEN" "projects/$dst_enc/repository/branches")
  st=$(api_all "$SOURCE_URL" "$SOURCE_TOKEN" "projects/$src_enc/repository/tags")
  dt=$(api_all "$TARGET_URL" "$TARGET_TOKEN" "projects/$dst_enc/repository/tags")
  if [[ "$sb$db$st$dt" == *"__ERROR__"* ]]; then
    echo "$rel,ERROR,,,,,," >> "$REPORT"; errors=$((errors + 1)); continue
  fi

  nsb=$(jq 'length' <<<"$sb"); ndb=$(jq 'length' <<<"$db")
  nst=$(jq 'length' <<<"$st"); ndt=$(jq 'length' <<<"$dt")

  # tags present in source whose name or target commit differs in the destination
  tag_diff=$(jq -n --argjson s "$st" --argjson d "$dt" \
    '[$s[] | {name, id: .commit.id}] - [$d[] | {name, id: .commit.id}] | length')

  src_def=$(curl -s --header "PRIVATE-TOKEN: $SOURCE_TOKEN" "$SOURCE_URL/api/v4/projects/$src_enc" | jq -r '.default_branch // empty')
  head_state="n/a"
  if [[ -n "$src_def" ]]; then
    sh=$(jq -r --arg b "$src_def" '.[] | select(.name==$b) | .commit.id' <<<"$sb")
    dh=$(jq -r --arg b "$src_def" '.[] | select(.name==$b) | .commit.id' <<<"$db")
    if [[ -z "$dh" ]]; then head_state="branch-missing"
    elif [[ "$sh" == "$dh" ]]; then head_state="same"
    else head_state="different"; fi       # expected when .gitlab-ci.yml was rewritten
  fi

  if [[ "$nsb" -eq "$ndb" && "$nst" -eq "$ndt" && "$tag_diff" -eq 0 && "$head_state" != "branch-missing" ]]; then
    status="OK"; ok=$((ok + 1))
  else
    status="MISMATCH"; mismatch=$((mismatch + 1))
  fi
  echo "$rel,$status,$nsb,$ndb,$nst,$ndt,$tag_diff,$head_state" >> "$REPORT"
done < <(jq -r '.[].path_with_namespace' <<<"$src_projects")

echo
echo "===== Summary ====="
echo "Source projects : $total"
echo "OK              : $ok"
echo "Mismatch        : $mismatch"
echo "Missing         : $missing"
echo "API errors      : $errors"
echo "Report          : $REPORT"
[[ $((mismatch + missing + errors)) -eq 0 ]]
