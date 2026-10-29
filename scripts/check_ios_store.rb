
require "json"
require "open3"

ROOT_DIR = File.expand_path("..", __dir__)
IOS_DIR = File.join(ROOT_DIR, "ios")

pubspec = File.read(File.join(ROOT_DIR, "pubspec.yaml"))
match = pubspec.match(/^version:\s*(\d+\.\d+\.\d+\+\d+)\s*$/)

abort "ERROR: Invalid version in pubspec.yaml" unless match

version = match[1]

command = [
  "bundle",
  "exec",
  "fastlane",
  "ios",
  "check_store_version"
]

output, status = Open3.capture2e(
  *command,
  chdir: IOS_DIR
)

duplicate_message =
  "Build #{version} already exists on App Store Connect. Upload blocked!"

if status.success?
  puts JSON.generate(
    status: "AVAILABLE",
    platform: "ios",
    version: version
  )
elsif output.include?(duplicate_message)
  puts JSON.generate(
    status: "EXISTS",
    platform: "ios",
    version: version
  )
else
  warn output

  puts JSON.generate(
    status: "ERROR",
    platform: "ios",
    version: version
  )

  exit 1
end

