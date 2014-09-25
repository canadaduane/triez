require "mkmf"

$CFLAGS << ' -Ihat-trie'
$CPPFLAGS << ' -Ihat-trie'
$LDFLAGS << ' -Lbuild -ltries'
create_makefile 'wordtriez'

# respect header changes
headers = Dir.glob('*.{hpp,h}').join ' '
File.open 'Makefile', 'a' do |f|
  f.puts "\n$(OBJS): #{headers}"
end

# build vendor lib
def sh *xs
  puts xs.join(' ')
  system *xs
end

require "fileutils"
include FileUtils
build_dir = File.dirname(__FILE__) + '/build'
mkdir_p build_dir
cd build_dir
unless File.exist?('libtries.a')
  cc = [ENV['CC'] || RbConfig::CONFIG['CC']]
  if enable_config('debug')
    CONFIG['debugflags'] << ' -ggdb3 -O0'
    cc += ['-O0', '-ggdb3']
  else
    cc += ['-O3']
  end
  cc += ['-std=c99', '-Wall', '-pedantic', '-fPIC', '-c']
  ar = RbConfig::CONFIG['AR']
  ar = 'ar' unless File.exist?(ar)
  sh *cc, '-I..', *Dir.glob("../hat-trie/*.c")
  sh ar, '-r', 'libtries.a', *Dir.glob("*.o")
end
