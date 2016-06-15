RUBY = /\.(rb)|(rake)$/
JS = /\.jsx?$/
RUBY_PASS = %w(no\ offenses files\ found).freeze
JS_PASS = %w(true files\ found).freeze

desc 'Style checks files that differ from master'
task :check_style do
  puts diff_output
  puts check_ruby
  puts check_js
  exit evaluate
end

def diff_output
  "Files found in the diff\n#{diff}\n"
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
  "rubocop -D #{files}"
end

def eslint(files)
  "npm run lint #{files}"
end

def diff
  @diff ||= `git diff master --name-only`
end

def files_that_match(regex)
  diff.split("\n").grep(regex).join(' ')
end
