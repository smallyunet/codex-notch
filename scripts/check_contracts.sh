#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONTRACT_FILE="$ROOT_DIR/docs/contracts/behavior-contracts.yaml"

command -v ruby >/dev/null || {
    echo "error: Ruby is required to validate behavior contracts" >&2
    exit 1
}

ruby -ryaml - "$CONTRACT_FILE" <<'RUBY'
path = ARGV.fetch(0)
contracts = YAML.load_file(path).fetch("contracts")
required = %w[
  id title status statement rationale source owner risk scope examples guards
  supersedes superseded_by last_verified_commit
]
valid_statuses = %w[active superseded]

abort "no behavior contracts found" if contracts.empty?

contracts.each do |contract|
  id = contract.fetch("id", "<missing id>")
  missing = required.reject { |key| contract.key?(key) }
  abort "#{id}: missing #{missing.join(", ")}" unless missing.empty?
  abort "#{id}: invalid status" unless valid_statuses.include?(contract.fetch("status"))
  abort "#{id}: guards must be a non-empty string list" unless contract.fetch("guards").is_a?(Array) &&
    !contract.fetch("guards").empty? && contract.fetch("guards").all? { |guard| guard.is_a?(String) }
end

puts "Validated #{contracts.length} behavior contracts"
RUBY
