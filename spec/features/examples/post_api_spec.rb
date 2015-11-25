require 'spec_helper'

describe 'jQuery POST API example', type: :feature, js: true do
  before do
    proxy.stub('http://example.com/api', method: 'post').and_return(
      headers: { 'Access-Control-Allow-Origin' => '*' },
      code: 201
    )
  end

  it 'posts to an API' do
    visit '/post_api.html'
    expect(page.find('#result')).to have_content 'Success!'
  end
end
