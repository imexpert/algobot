
require "json"
require "open3"

ROOT_DIR = File.expand_path("..", __dir__)
ANDROID_DIR = File.join(ROOT_DIR, "android")
VERSION = File.read(File.join(ROOT_DIR, "pubspec.yaml"))
              .match(/^version:\s*(\d+\.\d+\.\d+\+\d+)/)[1]

command = [
  "bundle", "exec", "fastlane", "android", "check_store_version"
]

output, status = Open3.capture2e(
  *command,
  chdir: ANDROID_DIR
)

build_number = VERSION.split("+").last

if status.success?
  puts JSON.generate(
    status: "AVAILABLE",
    platform: "android",
    version: VERSION
  )
elsif output.include?("Build #{build_number} already exists on Google Play track")
  puts JSON.generate(
    status: "EXISTS",
    platform: "android",
    version: VERSION
  )
else
  warn output
  puts JSON.generate(
    status: "ERROR",
    platform: "android",
    version: VERSION
  )
  exit 1
end

