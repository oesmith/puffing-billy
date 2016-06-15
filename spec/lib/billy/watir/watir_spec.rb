require 'spec_helper'

describe 'Watir usage example', type: :feature, js: true do
  before do
    proxy.stub('http://www.example.com/get').and_return(
      text: 'Success!'
    )
  end

  it 'should respond to a stubbed GET request' do
    @browser.goto 'http://www.example.com/get'
    expect(@browser.text).to eq 'Success!'
  end
end
