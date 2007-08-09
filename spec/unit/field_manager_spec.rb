require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

describe "AutomateIt::FieldManager", :shared => true do
  it "should lookup keys by string" do
    @m.lookup("key").should eql("value")
  end

  it "should lookup keys by symbol" do
    @m.lookup(:key).should eql("value")
  end

  it "should lookup hash" do
    @m.lookup(:hash)["leafkey"].should eql("leafvalue")
  end

  it "should lookup leaves" do
    @m.lookup("hash#leafkey").should eql("leafvalue")
    @m.lookup("hash#branchkey#deepleafkey").should eql("deepleafvalue")
  end

  it "should have aliased lookup into the interpreter" do
    #require 'rubygems'; require 'breakpoint'; breakpoint # FIXME 
    #@m.interpreter.lookup("hash#branchkey#deepleafkey").should eql("deepleafvalue")
=begin
irb(#<#<Class:0xb7681840>:0xb7673f9c>):004:0>  @m.interpreter.field_manager[:yaml]
=> #<AutomateIt::FieldManager::YAML:0xb76734c0>
irb(#<#<Class:0xb7681840>:0xb7673f9c>):005:0>  @m[:yaml]
=> #<AutomateIt::FieldManager::YAML:0xb76720ac @struct={"hash"=>{"leafkey"=>"leafvalue", "branchkey"=>{"deepleafkey"=>"deepleafvalue"}}, "key"=>"value"}>

irb(#<#<Class:0xb7681840>:0xb7673f9c>):010:0> @m.object_id
=> -608985708
irb(#<#<Class:0xb7681840>:0xb7673f9c>):011:0> @m.interpreter.field_manager.object_id
=> -608985928
=end
    @m.object_id.should == @m.interpreter.field_manager.object_id
    @m[:yaml].object_id.should == @m.interpreter.field_manager[:yaml].object_id
  end
end

# FIXME use @m.setup(:default => :struct, :struct => {...})
describe AutomateIt::FieldManager::Struct do
  it_should_behave_like "AutomateIt::FieldManager"

  before do
    @m = AutomateIt::FieldManager.new
    @m.setup(:default => :struct, :struct => {
      "key" => "value",
      "hash" => {
        "leafkey" => "leafvalue",
        "branchkey" => {
          "deepleafkey" => "deepleafvalue",
        },
      },
    })
  end
end

describe AutomateIt::FieldManager::YAML do
  it_should_behave_like "AutomateIt::FieldManager"

  before do
    @m = AutomateIt::FieldManager.new
    File.should_receive(:read).with("demo.yml").and_return(<<-EOB)
      <%="key"%>: value
      hash:
        leafkey: leafvalue
        branchkey:
          deepleafkey: deepleafvalue
    EOB
    @m.setup(:default => :yaml, :file => "demo.yml")
  end
end
