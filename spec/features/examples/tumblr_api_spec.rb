require 'spec_helper'

describe 'Tumblr API example', :type => :feature, :js => true do
  before do
    proxy.stub('http://blog.howmanyleft.co.uk/api/read/json').and_return(
      :jsonp => {
        :posts => [
          {
            'regular-title' => 'News Item 1',
            'url-with-slug' => 'http://example.com/news/1',
            'regular-body' => 'News item 1 content here'
          },
          {
            'regular-title' => 'News Item 2',
            'url-with-slug' => 'http://example.com/news/2',
            'regular-body' => 'News item 2 content here'
          }
        ]
    })
  end

  it 'should show news stories' do
    visit '/tumblr_api.html'
    expect(page).to have_link('News Item 1', :href => 'http://example.com/news/1')
    expect(page).to have_content('News item 1 content here')
    expect(page).to have_link('News Item 2', :href => 'http://example.com/news/2')
    expect(page).to have_content('News item 2 content here')
  end
end
