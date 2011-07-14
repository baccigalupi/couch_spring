module TestHelpers
  # see http://www.justskins.com/forums/closing-stderr-105096.html
  def capturing(stream)
    if stream == :stdout
      capturing_stdout
    else
      capturing_stderr
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
  
  def read_binary file
    contents = open(file, "rb") {|io| io.read }
  end
end