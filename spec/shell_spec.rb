require File.expand_path('../spec_helper', __FILE__)

describe Ice::Shell do
  let(:root) do
    File.expand_path('../dummy', __FILE__)
  end

  let(:sh) do
    Ice::Shell.new(root)
  end

  describe "#initialize" do
    it "should point to root path" do
      sh.root.should == root
    end

    it "should set config path" do
      sh.configs.should == File.join(root, 'etc')
    end

    it "should preconfigure binary paths" do
      sh.path.should have(2).items
      sh.path[0].should =~ /dummy\/bin$/
      sh.path[1].should =~ /dummy\/sbin$/
    end

    it "should preconfigure help paths" do
      sh.help_path.should have(2).items
      sh.help_path[0].should =~ /dummy\/bin$/
      sh.help_path[1].should =~ /dummy\/sbin$/
    end
  end

  describe "#motd" do
    it "should load message of the day" do
      sh.motd.should == "Test MOTD"
    end
  end

  describe "#prompt" do
    it "should load shell's prompt" do
      sh.prompt.should == "#{`whoami`.chomp}@#{`hostname -s`.chomp}$ "
    end
  end

  describe "#complete" do
    context "when command is not executable" do
      it "shouldn't complete it" do
        sh.complete("foo2").should be_empty
      end
    end

    context "when commands are in different load paths" do
      it "should complete them anyway" do
        suggestions = sh.complete("foo")
        suggestions.should have(2).items
        suggestions.should =~ %w(foo1 foo3)
      end
    end
  end

  describe "#handle" do
    context "when buffer is empty" do
      it "should do nothing and continue" do
        sh.handle(nil).should_not be
        sh.handle(" ").should_not be
      end
    end

    context "when help command requested" do
      it "should display help information" do
        sh.should_receive(:help)
        sh.handle("help").should_not be
      end

      it "should display specific information when help called with params" do
        sh.should_receive(:help).with("test")
        sh.handle("help test").should_not be
      end
    end

    context "when command doesn't exist" do
      it "should display an error" do
        sh.should_receive(:error).with("Command `test' not found!")
        sh.handle("test").should_not be
      end
    end

    context "when command exists" do
      it "should execute it and return its exit status" do
        sh.handle("foo1").should == 251
        sh.handle("foo3").should == 1
      end
    end
  end
end
