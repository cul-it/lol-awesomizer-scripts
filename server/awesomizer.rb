# Simple Ruby web server (using Sinatra) to handle requests from the
# Pi and from the front-end website

require 'yaml'
$config = YAML.load_file('config.yml')

require 'sinatra'
require 'json'
require 'mysql2'
require 'oci8'

# 'list' returns a list of all items in the database
get '/list' do
  _get_items.to_json
end

# 'inc' increments the votes for a particular item (assuming that
# the barcode lookup succeeds)
get '/inc/:barcode' do |barcode|
  metadata = _voyager_lookup barcode
  if !metadata[:bibid].nil?
    _increment_count metadata
  end
end

# 'inc' increments the votes for a particular item (assuming that
# the barcode lookup succeeds)
get '/inc' do
  barcode = params['barcode']
  location = params['loc']
  metadata = _voyager_lookup barcode
  unless metadata[:bibid].nil?
    _increment_count metadata, location
  end
end

# Retrieve a list of all the items in the database
def _get_items
  con = Mysql2::Client.new(:host     => $config['awesomizer']['host'], 
                           :username => $config['awesomizer']['user'], 
                           :password => $config['awesomizer']['pass'], 
                           :database => $config['awesomizer']['database'])
  output = []
  con.query('select * from items order by timestamp desc limit 80').each do |row|
    output.push row
  end

  output

end

# Main Awesomizer database write function
def _increment_count metadata, location = nil

  con = Mysql2::Client.new(:host     => $config['awesomizer']['host'], 
                           :username => $config['awesomizer']['user'], 
                           :password => $config['awesomizer']['pass'], 
                           :database => $config['awesomizer']['database'])  
  # TODO: the 'duplicate key' clause of this query
  # is nice, but it means that the code does a
  # Voyager lookup each and every time a code is
  # scanned, even for items already in the database.
  # it would be more efficient to check for the bibid
  # first and only do the voyager lookup if we don't
  # have the metadata yet.
  con.query("insert into items (bibid, title, author, oclc_id, votes) values ('#{metadata[:bibid]}', '#{metadata[:title]}', '#{metadata[:author]}', '#{metadata[:oclc_id]}', 1) on duplicate key update votes=votes+1")
end

# Looks up a barcode in the Voyager database and retrieves useful metadata
# about the item
def _voyager_lookup code

  metadata = {}

  voyager = OCI8.new($config['voyager']['user'], $config['voyager']['pass'], $config['voyager']['host'])

  # Do the main Voyager query to get bibid from barcode
  voyager.exec("select bt.* from item_barcode ib, bib_item bi, bib_text bt where ib.item_barcode='#{code}' and ib.item_id=bi.item_id and bi.bib_id = bt.bib_id") do |result|
    metadata[:bibid] = result[0]
    metadata[:author] = result[1]
    metadata[:title] = result[3]
  end

  # Do a secondary query to collect oclc number
  index_fields = voyager.exec("select normal_heading from bib_index where bib_id='#{metadata[:bibid]}' and index_code='0350'")
  while field = index_fields.fetch
    if result = /.*OCOLC\D*(\d+)/i.match(field[0])
      metadata[:oclc_id] = result.captures[0]
    end
  end

  return metadata

end
