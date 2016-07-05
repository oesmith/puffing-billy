require 'spec_helper'

describe 'Watir-specific tests', type: :feature, js: true do
  before do
    proxy.stub('http://www.example.com/get').and_return(
      text: 'Success!'
    )
  end

  it 'should raise a NameError if an invalid browser driver is specified' do
    expect(Billy::Browsers::Watir.new :invalid).to raise_error(NameError)
  end

  it 'should respond to a stubbed GET request' do
    @browser.goto 'http://www.example.com/get'
    expect(@browser.text).to eq 'Success!'
  end
end
