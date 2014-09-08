require 'test/unit'
require './lib/rservicebus/Monitor/DirNotifier.rb'
require 'mocha/test_unit'
require 'pathname'

class Test_Monitor_DirNotifier<RServiceBus::Monitor_DirNotifier

  attr_accessor :filelist

  def initialize
    @filelist = []
    super()
  end

  def file_writable? path
    return true
  end

  def open_folder path; end

  def move_file src, dest
    filename = Pathname.new(src).basename
    @filelist.delete src
    @filelist << Pathname.new(dest).join(filename)
    return Pathname.new(dest).join(filename)
  end

  def get_files
    return @filelist
  end

  def send payload, uri; end

end

class DirNotifierTest<Test::Unit::TestCase

  def test_DirDoesNotExist

    directory = 'foo'

    dirNotifier = Test_Monitor_DirNotifier.new
    dirNotifier.expects(:open_folder).with(directory).raises(Errno::ENOENT)
    dirNotifier.expects(:puts).with("***** Directory does not exist, #{directory}.")
    dirNotifier.expects(:puts).with("***** Create the directory, #{directory}, and try again.")
    dirNotifier.expects(:puts).with("***** eg, mkdir #{directory}")

    assert_raise SystemExit do
      dirNotifier.connect(URI(directory))
    end

  end

  def test_DirNotDirectory

    filename = '/tmp/test_dir_notifier.txt'

    dirNotifier = Test_Monitor_DirNotifier.new
    dirNotifier.expects(:open_folder).with(filename).raises(Errno::ENOTDIR)
    dirNotifier.expects(:puts).with("***** The specified path does not point to a directory, #{filename}.")
    dirNotifier.expects(:puts).with("***** Either repoint path to a directory, or remove, #{filename}, and create it as a directory.")
    dirNotifier.expects(:puts).with("***** eg, rm #{filename} && mkdir #{filename}")

    assert_raise SystemExit do
      dirNotifier.connect(URI(filename))
    end

  end

  def test_DirNotWritable

    directory = '/'

    dirNotifier = Test_Monitor_DirNotifier.new
    dirNotifier.expects(:file_writable?).with(directory).returns(false)
    dirNotifier.expects(:puts).with("***** Directory is not writable, #{directory}.")
    dirNotifier.expects(:puts).with("***** Make the directory, #{directory}, writable and try again.")

    assert_raise SystemExit do
      dirNotifier.connect(URI(directory))
    end

  end

  def test_ProcessingDirNotSpecified

    directory = '/tmp/'

    dirNotifier = Test_Monitor_DirNotifier.new

    dirNotifier.expects(:puts).with('***** Processing Directory is not specified.')
    dirNotifier.expects(:puts).with('***** Specify the Processing Directory as a query string in the Path URI')
    dirNotifier.expects(:puts).with("***** eg, '/#{directory}?processing=*ProcessingDir*")

    assert_raise SystemExit do
      dirNotifier.connect(URI(directory))
    end

  end

  def test_ProcessingDirDoesNotExist

    directory = 'foo'

    dirNotifier = Test_Monitor_DirNotifier.new
    dirNotifier.expects(:open_folder).with('/tmp').returns()
    dirNotifier.expects(:open_folder).with(directory).raises(Errno::ENOENT)
    dirNotifier.expects(:puts).with("***** Processing Directory does not exist, #{directory}.")
    dirNotifier.expects(:puts).with("***** Create the directory, #{directory}, and try again.")
    dirNotifier.expects(:puts).with("***** eg, mkdir #{directory}")

    assert_raise SystemExit do
      dirNotifier.connect(URI('/tmp?processing=' + directory))
    end

  end

  def test_ProcessingDirNotDirectory

    filename = '/tmp/test_dir_notifier.txt'
    FileUtils.touch(filename)

    dirNotifier = Test_Monitor_DirNotifier.new
    dirNotifier.expects(:open_folder).with('/tmp').returns()
    dirNotifier.expects(:open_folder).with(filename).raises(Errno::ENOTDIR)
    dirNotifier.expects(:puts).with("***** Processing Directory does not point to a directory, #{filename}.")
    dirNotifier.expects(:puts).with("***** Either repoint path to a directory, or remove, #{filename}, and create it as a directory.")
    dirNotifier.expects(:puts).with("***** eg, rm #{filename} && mkdir #{filename}")

    assert_raise SystemExit do
      dirNotifier.connect(URI('/tmp?processing=' + filename))
    end

  end

  def test_ProcessingDirNotWritable

    directory = '/'

    dirNotifier = Test_Monitor_DirNotifier.new
    dirNotifier.expects(:file_writable?).with('/tmp').returns(true)
    dirNotifier.expects(:file_writable?).with(directory).returns(false)
    dirNotifier.expects(:puts).with("***** Processing Directory is not writable, #{directory}.")
    dirNotifier.expects(:puts).with("***** Make the directory, #{directory}, writable and try again.")

    assert_raise SystemExit do
      dirNotifier.connect(URI("/tmp?processing=" + directory))
    end

  end

  def test_MovesFileForProcessing
    directory = '/tmp/incoming'
    processingDir = '/tmp/processing'
    filename = 'test_processing.txt'

    dirNotifier = Test_Monitor_DirNotifier.new
    dirNotifier.expects(:send)

    dirNotifier.connect(URI(directory + "?processing=" + processingDir))
    dirNotifier.filelist << Pathname.new(directory).join(filename)

    dirNotifier.Look

    assert_equal(Pathname.new(processingDir).join(filename), dirNotifier.filelist[0])
  end

  def test_NoFilterDefined
    directory = '/tmp/incoming'
    processingDir = '/tmp/processing'

    dirNotifier = Test_Monitor_DirNotifier.new

    dirNotifier.connect(URI(directory + "?processing=" + processingDir))

    assert_equal("*", dirNotifier.Filter)
  end

  def test_SetsFilter
    directory = '/tmp/incoming'
    processingDir = '/tmp/processing'
    filter = "test.txt"

    dirNotifier = Test_Monitor_DirNotifier.new

    dirNotifier.connect(URI(directory + "?processing=" + processingDir + '&filter=' + filter))

    assert_equal("test.txt", dirNotifier.Filter)
  end

end
