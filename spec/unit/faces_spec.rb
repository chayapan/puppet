#!/usr/bin/env ruby

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe Puppet::Faces do
  before :all do
    @faces = Puppet::Faces::FaceCollection.instance_variable_get("@faces").dup
  end

  before :each do
    Puppet::Faces::FaceCollection.instance_variable_get("@faces").clear
  end

  after :all do
    Puppet::Faces::FaceCollection.instance_variable_set("@faces", @faces)
  end

  describe "#define" do
    it "should register the face" do
      face = Puppet::Faces.define(:face_test_register, '0.0.1')
      face.should == Puppet::Faces[:face_test_register, '0.0.1']
    end

    it "should load actions" do
      Puppet::Faces.any_instance.expects(:load_actions)
      Puppet::Faces.define(:face_test_load_actions, '0.0.1')
    end

    it "should require a version number" do
      expect { Puppet::Faces.define(:no_version) }.should raise_error ArgumentError
    end
  end

  describe "#initialize" do
    it "should require a version number" do
      expect { Puppet::Faces.new(:no_version) }.should raise_error ArgumentError
    end

    it "should require a valid version number" do
      expect { Puppet::Faces.new(:bad_version, 'Rasins') }.
        should raise_error ArgumentError
    end

    it "should instance-eval any provided block" do
      face = Puppet::Faces.new(:face_test_block, '0.0.1') do
        action(:something) do
          when_invoked { "foo" }
        end
      end

      face.something.should == "foo"
    end
  end

  it "should have a name" do
    Puppet::Faces.new(:me, '0.0.1').name.should == :me
  end

  it "should stringify with its own name" do
    Puppet::Faces.new(:me, '0.0.1').to_s.should =~ /\bme\b/
  end

  it "should allow overriding of the default format" do
    face = Puppet::Faces.new(:me, '0.0.1')
    face.set_default_format :foo
    face.default_format.should == :foo
  end

  it "should default to :pson for its format" do
    Puppet::Faces.new(:me, '0.0.1').default_format.should == :pson
  end

  # Why?
  it "should create a class-level autoloader" do
    Puppet::Faces.autoloader.should be_instance_of(Puppet::Util::Autoload)
  end

  it "should try to require faces that are not known" do
    Puppet::Faces::FaceCollection.expects(:require).with "puppet/faces/foo"
    Puppet::Faces[:foo, '0.0.1']
  end

  it "should be able to load all actions in all search paths"


  it_should_behave_like "things that declare options" do
    def add_options_to(&block)
      Puppet::Faces.new(:with_options, '0.0.1', &block)
    end
  end

  describe "with face-level options" do
    it "should not return any action-level options" do
      face = Puppet::Faces.new(:with_options, '0.0.1') do
        option "--foo"
        option "--bar"
        action :baz do
          option "--quux"
        end
      end
      face.options.should =~ [:foo, :bar]
    end

    it "should fail when a face option duplicates an action option" do
      expect {
        Puppet::Faces.new(:action_level_options, '0.0.1') do
          action :bar do option "--foo" end
          option "--foo"
        end
      }.should raise_error ArgumentError, /Option foo conflicts with existing option foo on/i
    end

    it "should work when two actions have the same option" do
      face = Puppet::Faces.new(:with_options, '0.0.1') do
        action :foo do option "--quux" end
        action :bar do option "--quux" end
      end

      face.get_action(:foo).options.should =~ [:quux]
      face.get_action(:bar).options.should =~ [:quux]
    end
  end

  describe "with inherited options" do
    let :face do
      parent = Class.new(Puppet::Faces)
      parent.option("--inherited")
      face = parent.new(:example, '0.2.1')
      face.option("--local")
      face
    end

    describe "#options" do
      it "should list inherited options" do
        face.options.should =~ [:inherited, :local]
      end
    end

    describe "#get_option" do
      it "should return an inherited option object" do
        face.get_option(:inherited).should be_an_instance_of Puppet::Faces::Option
      end
    end
  end
end
