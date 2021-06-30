require "yast/rake"

task_path = File.expand_path("lib/tasks", __dir__)
Dir.glob(File.join(task_path, "*.rake")).each { |f| load f }

Yast::Tasks.configuration do |conf|
  #lets ignore license check for now
  conf.skip_license_check << /.*/
  conf.package_name = "autoyast2-schemas"
end
