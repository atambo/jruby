require File.expand_path('../../../spec_helper', __FILE__)

describe "ARGF.read" do
  before :each do
    @file1_name = fixture __FILE__, "file1.txt"
    @file2_name = fixture __FILE__, "file2.txt"
    @stdin_name = fixture __FILE__, "stdin.txt"

    @file1 = File.read @file1_name
    @file2 = File.read @file2_name
    @stdin = File.read @stdin_name
  end

  it "reads the contents of a file" do
    argf [@file1_name] do
      @argf.read().should == @file1
    end
  end

  it "treats first nil argument as no length limit" do
    argf [@file1_name] do
      @argf.read(nil).should == @file1
    end
  end

  it "treats second nil argument as no output buffer" do
    argf [@file1_name] do
      @argf.read(nil, nil).should == @file1
    end
  end

  it "treats second argument as an output buffer" do
    argf [@file1_name] do
      buffer = ""
      @argf.read(nil, buffer)
      buffer.should == @file1
    end
  end

  it "reads a number of bytes from the first file" do
    argf [@file1_name] do
      @argf.read(5).should == @file1[0,5]
    end
  end

  it "reads from a single file consecutively" do
    argf [@file1_name] do
      @argf.read(1).should == @file1[0,1]
      @argf.read(2).should == @file1[1,2]
      @argf.read(3).should == @file1[3,3]
    end
  end

  it "reads the contents of two files" do
    argf [@file1_name, @file2_name] do
      @argf.read.should ==  @file1 + @file2
    end
  end

  it "reads the contents of one file and some characters from the second" do
    argf [@file1_name, @file2_name] do
      len = @file1.size + (@file2.size / 2)
      @argf.read(len).should ==  (@file1 + @file2)[0,len]
    end
  end

  it "reads across two files consecutively" do
    argf [@file1_name, @file2_name] do
      @argf.read(@file1.size - 2).should == @file1[0..-3]
      @argf.read(2+5).should == @file1[-2..-1] + @file2[0,5]
    end
  end

  it "reads the contents of stdin" do
    stdin = ruby_exe("print ARGF.read", :args => "< #{@stdin_name}")
    stdin.should == @stdin
  end

  it "reads a number of bytes from stdin" do
    stdin = ruby_exe("print ARGF.read(10)", :args => "< #{@stdin_name}")
    stdin.should == @stdin[0,10]
  end

  it "reads the contents of one file and stdin" do
    stdin = ruby_exe("print ARGF.read", :args => "#{@file1_name} - < #{@stdin_name}")
    stdin.should == @file1 + @stdin
  end

  it "reads the contents of the same file twice" do
    argf [@file1_name, @file1_name] do
      @argf.read.should == @file1 + @file1
    end
  end

  platform_is_not :windows do
    it "reads the contents of a special device file" do
      argf ['/dev/zero'] do
        @argf.read(100).should == "\000" * 100
      end
    end
  end

  with_feature :encoding do

    before :each do
      @external = Encoding.default_external
      @internal = Encoding.default_internal

      Encoding.default_external = Encoding::UTF_8
      Encoding.default_internal = nil
    end

    after :each do
      Encoding.default_external = @external
      Encoding.default_internal = @internal
    end

    it "reads the contents of the file with default encoding" do
      Encoding.default_external = Encoding::US_ASCII
      argf [@file1_name, @file2_name] do
        @argf.read.encoding.should == Encoding::US_ASCII
      end
    end
  end
end
