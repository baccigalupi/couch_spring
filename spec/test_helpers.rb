require 'pp'

module TestHelpers
  # suppressing warnings -----------------------------------------
  # see http://www.justskins.com/forums/closing-stderr-105096.html
  def capturing(stream, &block)
    if stream == :stdout
      capturing_stdout &block
    else
      capturing_stderr &block
    end
  end
  
  def capturing_stdout
    output = StringIO.new
    $stdout = output
    yield
    output.string
  ensure
    $stdout = STDOUT
  end
  
  def capturing_stderr
    output = StringIO.new
    $stderr = output
    yield
    output.string
  ensure
    $stderr = STDERR
  end
  
  def hr message=nil
    str = "<hr>#{message}"
    str << "<hr>" if message
    puts str
  end
end