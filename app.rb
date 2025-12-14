require 'sinatra'
require 'rest-client'
require 'json'

# Serve static files from the 'public' folder
set :public_folder, 'public'

# Enable CORS so we can test easily if needed
before do
  headers 'Access-Control-Allow-Origin' => '*',
          'Access-Control-Allow-Methods' => ['OPTIONS', 'GET', 'POST']
end

# The Home Route - Serves the HTML file
get '/' do
  send_file File.join(settings.public_folder, 'index.html')
end

# The API Endpoint - Fetches Wiki Data
get '/api/data' do
  content_type :json
  article_title = params['article'] || 'Warren'
  
  # 1. Fetch Article Summary and Links from Wikipedia API
  base_url = "https://en.wikipedia.org/w/api.php"
  
  begin
    response = RestClient.get(base_url, params: {
      action: 'query',
      format: 'json',
      prop: 'extracts|links',
      titles: article_title,
      exintro: true,      # Only the intro
      explaintext: true,  # Plain text
      pllimit: 50,        # Max 50 links
      plnamespace: 0      # Articles only (no categories)
    })
    
    data = JSON.parse(response.body)
    page_id = data['query']['pages'].keys.first
    
    # Handle "Page Not Found"
    if page_id.nil?
      return { error: "Page not found" }.to_json
    end

    page_data = data['query']['pages'][page_id]
    summary = page_data['extract']
    raw_links = page_data['links'] || []

    # 2. Format the Warren Burrows (Satellites)
    # Note: In a production app, we would fetch popularity counts here.
    # For speed/MVP, we are randomizing size slightly to simulate it.
    orbit_nodes = raw_links.map do |link|
      {
        id: link['title'],
        name: link['title'],
        type: 'satellite',
        popularitySize: rand(1..10) # Placeholder for popularity logic
      }
    end

    # 3. Return the JSON
    {
      centerNode: {
        id: article_title,
        name: article_title,
        summary: summary,
        type: 'center',
        popularitySize: 20
      },
      orbitNodes: orbit_nodes
    }.to_json

  rescue => e
    return { error: e.message }.to_json
  end
end
