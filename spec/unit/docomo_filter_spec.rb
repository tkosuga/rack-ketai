# -*- coding: utf-8 -*-
require 'kconv'
require 'rack/ketai/carrier/docomo'
describe Rack::Ketai::Carrier::Docomo::Filter, "内部エンコーディングに変換する時" do

  before(:each) do
    @filter = Rack::Ketai::Carrier::Docomo::Filter.instance
  end
  
  it "POSTデータ中のSJISバイナリの絵文字を絵文字IDに変換すること" do
    Rack::Ketai::Carrier::Docomo::Filter::EMOJI_TO_EMOJIID.should_not be_empty
    Rack::Ketai::Carrier::Docomo::Filter::EMOJI_TO_EMOJIID.each do |emoji, emojiid|
      postdata = CGI.escape("message=今日はいい".tosjis + emoji + "ですね。".tosjis)
      postdata.force_encoding('Shift_JIS') if postdata.respond_to?(:force_encoding)
      
      env = Rack::MockRequest.env_for('http://hoge.com/dummy',
                                      'HTTP_USER_AGENT' => 'DoCoMo/2.0 P903i',
                                      :input => postdata)
      env = @filter.inbound(env)
      request = Rack::Request.new(env)
      request.params['message'].should == '今日はいい[e:'+format("%03X", emojiid)+']ですね。'
    end
  end
  
end

describe Rack::Ketai::Carrier::Docomo::Filter, "外部エンコーディングに変換する時" do

  before(:each) do
    @filter = Rack::Ketai::Carrier::Docomo::Filter.instance
  end
  
  it "データ中の絵文字IDをSJISの絵文字コードに変換すること" do
    Rack::Ketai::Carrier::Docomo::Filter::EMOJI_TO_EMOJIID.should_not be_empty
    Rack::Ketai::Carrier::Docomo::Filter::EMOJI_TO_EMOJIID.each do |emoji, emojiid|
      resdata = "今日はいい".tosjis + emoji + "ですね。".tosjis

      status, headers, body = @filter.outbound(200, { "Content-Type" => "text/html"}, ['今日はいい[e:'+format("%03X", emojiid)+']ですね。'])

      body[0].should == resdata
    end
  end
  
  it "データ中にドコモにはない絵文字IDが存在するとき、代替文字を表示すること" do
    resdata = "黒い矢印[#{[0x2190].pack('U')}]です".tosjis # 左黒矢印

    status, headers, body = @filter.outbound(200, { "Content-Type" => "text/html"}, ['黒い矢印[e:AFB]です'])
    
    body[0].should == resdata
  end

end
