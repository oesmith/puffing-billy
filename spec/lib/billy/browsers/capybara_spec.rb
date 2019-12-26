require 'spec_helper'

describe 'Capybara drivers', type: :feature, js: true do
  it 'allows HTTPS calls' do
    proxy.stub('https://blog.howmanyleft.co.uk:443/api/read/json').and_return(
      jsonp: {
        posts: [
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

    visit '/tumblr_api_https.html'

    expect(page).to have_link('News Item 1', href: 'http://example.com/news/1')
    expect(page).to have_content('News item 1 content here')
    expect(page).to have_link('News Item 2', href: 'http://example.com/news/2')
    expect(page).to have_content('News item 2 content here')
  end
end
