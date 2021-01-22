#!/bin/zsh
LOCAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
cd "$LOCAL_DIR" || exit 1
EXAMPLES_DIR="$LOCAL_DIR/Examples"

swift build
# shellcheck disable=SC2181
if [[ $? -ne 0 ]]; then
  echo "Failed to build"
  exit 1
fi

echo "Standard test"
swift run json-csv json-to-csv "$EXAMPLES_DIR/statusEffects.json" "$EXAMPLES_DIR/statusEffects.csv"
swift run json-csv csv-to-json "$EXAMPLES_DIR/statusEffects.csv" "$EXAMPLES_DIR/statusEffects-roundabout.json"
diff <(jq -S . "$EXAMPLES_DIR/statusEffects.json") <(jq -S . "$EXAMPLES_DIR/statusEffects-roundabout.json")

echo "Standard test 2"
swift run json-csv json-to-csv --column-format standard "$EXAMPLES_DIR/rounds.json" "$EXAMPLES_DIR/rounds.csv"
swift run json-csv csv-to-json --column-format standard "$EXAMPLES_DIR/rounds.csv" "$EXAMPLES_DIR/rounds-roundabout.json"
diff <(jq -S . "$EXAMPLES_DIR/rounds.json") <(jq -S . "$EXAMPLES_DIR/rounds-roundabout.json")

echo "Array test"
swift run json-csv json-to-csvs --column-format array "$EXAMPLES_DIR/buildings.json" "$EXAMPLES_DIR/buildings"
swift run json-csv csvs-to-json --column-format array "$EXAMPLES_DIR/buildings" "$EXAMPLES_DIR/buildings-roundabout.json"
diff <(jq -S . "$EXAMPLES_DIR/buildings.json") <(jq -S . "$EXAMPLES_DIR/buildings-roundabout.json")

echo "Tests passed iff there is no diff"
