# Read-only: checks that a build number has never been used on either store.
#
#   ruby scripts/check_build_number.rb          # pubspec.yaml build number
#   ruby scripts/check_build_number.rb 7        # a proposed build number
#
# Prints one JSON line:
#   {"status":"OK","build":7,"android_max":6,"ios_max":6,
#    "store_max":6,"next_build":7}
#
# status: OK      -> build is higher than every build on both stores
#         TOO_LOW -> build was used or is not higher; use next_build
#         ERROR   -> a store query failed; release must stop
# Exit codes: 0 OK, 2 TOO_LOW, 1 ERROR.

require "json"
require "open3"

ROOT_DIR = File.expand_path("..", __dir__)

pubspec = File.read(File.join(ROOT_DIR, "pubspec.yaml"))
match = pubspec.match(/^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$/)
abort "ERROR: Invalid version in pubspec.yaml" unless match

build = Integer(ARGV.fetch(0, match[2]), exception: false)
abort "ERROR: Invalid build number: #{ARGV[0]}" unless build&.positive?

def store_max(dir, platform, lane)
  output, status = Open3.capture2e(
    "bundle", "exec", "fastlane", platform, lane,
    chdir: File.join(ROOT_DIR, dir)
  )
  plain = output.gsub(/\e\[[0-9;]*m/, "")
  value = plain[/ALGOBOT_MAX_BUILD=(\d+)/, 1]
  return value.to_i if status.success? && value

  warn plain.lines.last(15).join
  nil
end

android_max = store_max("android", "android", "max_version_code")
ios_max = store_max("ios", "ios", "max_build_number")

if android_max.nil? || ios_max.nil?
  puts JSON.generate(
    status: "ERROR",
    build: build,
    android_max: android_max,
    ios_max: ios_max
  )
  exit 1
end

highest = [android_max, ios_max].max
status = build > highest ? "OK" : "TOO_LOW"

puts JSON.generate(
  status: status,
  build: build,
  android_max: android_max,
  ios_max: ios_max,
  store_max: highest,
  next_build: highest + 1
)

exit(status == "OK" ? 0 : 2)
