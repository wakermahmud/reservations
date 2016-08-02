RUBY = /\.(rb)|(rake)$/
JS = /\.jsx?$/
RUBY_PASS = %w(no\ offenses files\ found).freeze
JS_PASS = %w(true files\ found).freeze

EXISTING_FILES = /^[^D].*/
FILE = /^[A-Z]\t(.*)$/

desc 'Style checks files that differ from master'
task :check_style do
  puts diff_output
  puts "\nRunning rubocop..."
  puts check_ruby
  puts "\nRunning eslint..."
  puts check_js
  exit evaluate
end

def diff_output
  "Files found in the diff\n#{diff.join("\n")}\n"
end

def check_ruby
  files = files_that_match RUBY
  return 'No ruby files found!' if files.empty?
  @ruby_results ||= "#{rubocop(files)}\n#{system rubocop(files)}\n"
end

def check_js
  files = files_that_match JS
  return 'No javascript files found!' if files.empty?
  @js_results ||= "#{eslint(files)}\n#{system eslint(files)}\n"
end

def evaluate
  return 0 if passed?
  1
end

def passed?
  RUBY_PASS.any? { |m| check_ruby.include? m } &&
    JS_PASS.any? { |m| check_js.include? m }
end

def rubocop(files)
  "rubocop -D --force-exclusion #{files}"
end

def eslint(files)
  "npm run lint #{files}"
end

def diff
  @diff ||= process_diff
end

def process_diff
  all = `git diff master --name-status`
  existing_files = all.split("\n").grep(EXISTING_FILES)
  existing_files.map { |f| FILE.match(f)[1] }
end

def files_that_match(regex)
  diff.grep(regex).join(' ')
end
