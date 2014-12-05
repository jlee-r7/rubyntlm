# encoding: UTF-8
require 'spec_helper'

describe Net::NTLM::Message::Type2 do

  fields = [
      { :name => :sign, :class => Net::NTLM::String, :value => Net::NTLM::SSP_SIGN, :active => true },
      { :name => :type, :class => Net::NTLM::Int32LE, :value => 2, :active => true },
      { :name => :challenge, :class => Net::NTLM::Int64LE, :value => 0, :active => true },
      { :name => :context, :class => Net::NTLM::Int64LE, :value => 0, :active => false },
      { :name => :flag, :class => Net::NTLM::Int32LE, :value =>  Net::NTLM::DEFAULT_FLAGS[:TYPE2], :active => true },
      { :name => :target_name, :class => Net::NTLM::SecurityBuffer, :value => '', :active => true },
      { :name => :target_info, :class => Net::NTLM::SecurityBuffer, :value =>  '', :active => false },
      { :name => :padding, :class => Net::NTLM::String, :value => '', :active => false },
  ]
  flags = [
      :UNICODE
  ]
  it_behaves_like 'a fieldset', fields
  it_behaves_like 'a message', flags

  let(:type2_packet) {"TlRMTVNTUAACAAAAHAAcADgAAAAFgooCJ+UA1//+ZM4AAAAAAAAAAJAAkABUAAAABgGxHQAAAA9WAEEARwBSAEEATgBUAC0AMgAwADAAOABSADIAAgAcAFYAQQBHAFIAQQBOAFQALQAyADAAMAA4AFIAMgABABwAVgBBAEcAUgBBAE4AVAAtADIAMAAwADgAUgAyAAQAHAB2AGEAZwByAGEAbgB0AC0AMgAwADAAOABSADIAAwAcAHYAYQBnAHIAYQBuAHQALQAyADAAMAA4AFIAMgAHAAgAZBMdFHQnzgEAAAAA"}
  let(:type3_packet) {"TlRMTVNTUAADAAAAGAAYAEQAAADAAMAAXAAAAAAAAAAcAQAADgAOABwBAAAUABQAKgEAAAAAAAA+AQAABYKKAgAAAADVS27TfQGmWxSSbXmolTUQyxJmD8ISQuBKKHFKC8GksUZISYc8Ps9RAQEAAAAAAAAANasTdCfOAcsSZg/CEkLgAAAAAAIAHABWAEEARwBSAEEATgBUAC0AMgAwADAAOABSADIAAQAcAFYAQQBHAFIAQQBOAFQALQAyADAAMAA4AFIAMgAEABwAdgBhAGcAcgBhAG4AdAAtADIAMAAwADgAUgAyAAMAHAB2AGEAZwByAGEAbgB0AC0AMgAwADAAOABSADIABwAIAGQTHRR0J84BAAAAAAAAAAB2AGEAZwByAGEAbgB0AGsAbwBiAGUALgBsAG8AYwBhAGwA"}

  it 'should deserialize' do
    t2 =  Net::NTLM::Message.decode64(type2_packet)
    expect(t2.class).to eq(Net::NTLM::Message::Type2)
    expect(t2.challenge).to eq(14872292244261496103)
    expect(t2.context).to eq(0)
    expect(t2.flag).to eq(42631685)
    if "".respond_to?(:force_encoding)
      expect(t2.padding).to eq(("\x06\x01\xB1\x1D\0\0\0\x0F".force_encoding('ASCII-8BIT')))
    end
    expect(t2.sign).to eq("NTLMSSP\0")

    t2_target_info = Net::NTLM::EncodeUtil.decode_utf16le(t2.target_info)
    if RUBY_VERSION == "1.8.7"
      expect(t2_target_info).to eq("\x02\x1CVAGRANT-2008R2\x01\x1CVAGRANT-2008R2\x04\x1Cvagrant-2008R2\x03\x1Cvagrant-2008R2\a\b\e$(D+&\e(B\0\0")
    else
      expect(t2_target_info).to eq("\u0002\u001CVAGRANT-2008R2\u0001\u001CVAGRANT-2008R2\u0004\u001Cvagrant-2008R2\u0003\u001Cvagrant-2008R2\a\b፤ᐝ❴ǎ\0\0")
    end

    expect(Net::NTLM::EncodeUtil.decode_utf16le(t2.target_name)).to eq("VAGRANT-2008R2")
    expect(t2.type).to eq(2)
  end

  it 'should serialize' do
    source = Net::NTLM::Message.decode64(type2_packet)

    t2 =  Net::NTLM::Message::Type2.new
    t2.challenge = source.challenge
    t2.context = source.context
    t2.flag = source.flag
    t2.padding = source.padding
    t2.sign = source.sign
    t2.target_info = source.target_info
    t2.target_name = source.target_name
    t2.type = source.type
    t2.enable(:context)
    t2.enable(:target_info)
    t2.enable(:padding)

    expect(t2.encode64).to eq(type2_packet)
  end

  it 'should generate a type 3 response' do
    t2 = Net::NTLM::Message.decode64(type2_packet)

    type3_known = Net::NTLM::Message.decode64(type3_packet)
    type3_known.flag = 0x028a8205
    type3_known.enable(:session_key)
    type3_known.enable(:flag)

    t3 = t2.response({:user => 'vagrant', :password => 'vagrant', :domain => ''}, {:ntlmv2 => true, :workstation => 'kobe.local'})
    expect(t3.domain).to eq(type3_known.domain)
    expect(t3.flag).to eq(type3_known.flag)
    expect(t3.sign).to eq("NTLMSSP\0")
    expect(t3.workstation).to eq("k\0o\0b\0e\0.\0l\0o\0c\0a\0l\0")
    expect(t3.user).to eq("v\0a\0g\0r\0a\0n\0t\0")
    expect(t3.session_key).to eq('')
  end

  it 'should upcase domain when provided' do
    t2 = Net::NTLM::Message.decode64(type2_packet)
    t3 = t2.response({:user => 'vagrant', :password => 'vagrant', :domain => 'domain'}, {:ntlmv2 => true, :workstation => 'kobe.local'})
    expect(t3.domain).to eq("D\0O\0M\0A\0I\0N\0")
  end
end
