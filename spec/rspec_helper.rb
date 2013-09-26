require_relative '../lib/sixword'
require_relative 'test_vectors'

# TODO: use a real logger
$debug = ENV['DEBUG']
def debug_puts(*args, &blk)
  if $debug
    puts(*args, &blk)
  end
end
