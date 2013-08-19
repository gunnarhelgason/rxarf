require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs = ["lib"]
  t.warning = true
  t.test_files = FileList['test/test_*.rb']
end

desc "Run tests"
task :default => :test
