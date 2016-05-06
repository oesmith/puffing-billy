require 'spec_helper'

describe 'jQuery preflight request example', type: :feature, js: true do
  let(:url) { 'http://example.com/api' }

  before do
    proxy.stub(url, method: 'get').and_return(
      headers: { 'Access-Control-Allow-Origin' => '*' },
      code: 201
    )
  end

  it 'stubs out the OPTIONS request' do
    visit '/preflight_request.html'
    expect(page.find('#result')).to have_content 'Fail!'

    proxy.stub(url, method: 'options').and_return(
      headers: {
        'Access-Control-Allow-Methods' => 'GET, OPTIONS',
        'Access-Control-Allow-Headers' => 'Content-Type',
        'Access-Control-Allow-Origin' => '*'
      },
      code: 200
    )

    visit '/preflight_request.html'
    expect(page.find('#result')).to have_content 'Success!'
  end
end
