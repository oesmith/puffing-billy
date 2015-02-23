require 'spec_helper'

describe Billy::Handler do
  let(:handler) { Class.new { include Billy::Handler }.new }
  it '#handle_request raises an error if not overridden' do
    expect(handler.handle_request(nil, nil, nil, nil)).to eql(error: 'The handler has not overridden the handle_request method!')
  end

  it '#handles_request returns false by default' do
    expect(handler.handles_request?(nil, nil, nil, nil)).to be false
  end

  it 'responds to #reset' do
    expect(handler).to respond_to :reset
  end
end
