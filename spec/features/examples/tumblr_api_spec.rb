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

  it 'should show news stories', :js => true do
    visit '/tumblr_api.html'
    page.should have_link('News Item 1', :href => 'http://example.com/news/1')
    page.should have_content('News item 1 content here')
    page.should have_link('News Item 2', :href => 'http://example.com/news/2')
    page.should have_content('News item 2 content here')
  end
end
