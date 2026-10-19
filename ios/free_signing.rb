# Removes everything a free Apple ID cannot sign from the Runner target:
# the Live Activity and Notification Service extensions and the Crashlytics
# symbol upload phase. Applied by `pod install` when Flutter/Local.xcconfig sets
# MOBILERAKER_FREE_SIGNING = YES. To undo: remove the flag and run
# `git checkout ios/Runner.xcodeproj`.
require 'xcodeproj'

module MobilerakerFreeSigning
  EXTENSIONS = %w[MobilrakerLiveActivityExtension MobilerakerNotificationExtention].freeze
  CRASHLYTICS_PHASE = 'FlutterFire: "flutterfire upload-crashlytics-symbols"'.freeze

  def self.enabled?(ios_dir)
    local = File.join(ios_dir, 'Flutter', 'Local.xcconfig')
    File.exist?(local) && File.read(local).match?(/^\s*MOBILERAKER_FREE_SIGNING\s*=\s*YES\s*$/)
  end

  def self.apply(project_path)
    project = Xcodeproj::Project.open(project_path)
    runner = project.targets.find { |t| t.name == 'Runner' }
    return unless runner

    runner.dependencies.select { |d| d.target && EXTENSIONS.include?(d.target.name) }
          .each(&:remove_from_project)
    runner.copy_files_build_phases.each do |phase|
      phase.files.select { |f| f.file_ref && EXTENSIONS.map { |e| "#{e}.appex" }.include?(f.file_ref.path) }
           .each(&:remove_from_project)
    end
    runner.shell_script_build_phases.select { |p| p.name == CRASHLYTICS_PHASE }
          .each(&:remove_from_project)
    project.save
    puts '[mobileraker] Free signing mode: extensions and Crashlytics upload phase removed from Runner.'
  end
end
