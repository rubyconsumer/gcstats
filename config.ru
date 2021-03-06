require 'rubygems'
require 'zip/zip'
require 'lib/mapping'
require 'lib/template'

class GCStatsApp
  def call(env)
    req = Rack::Request.new(env)
    res = Rack::Response.new

    if req.get?
      if req.path_info == '/'
        res.write %{\
<html>
<head>
<title>gcstats</title>
<style type="text/css">body { font-family: sans-serif; }</style>
</head>
<body>
<form enctype="multipart/form-data" action="/" method="post">
<label for="pq">Pocket Query (.zip or .gpx):</label>
<input id="pq" type="file" name="pq" />
<input type="submit" value="Generate Stats" />
</form>
</body>
</html>}
      else
        res.status = 404
        res.write '<h1>Not Found</h1>'
      end
    elsif req.post?
      begin
        pq = req.POST['pq']

        if pq[:type] == 'application/zip'
          data = nil

          Zip::ZipFile.foreach(pq[:tempfile].path) {|entry|
            if File.extname(entry.name) == '.gpx'
              data = entry.get_input_stream.read
              break
            end
          }
        else
          data = pq[:tempfile].read
        end

        rhtml = open('gcstats.rhtml').read
        caches = Caches.from_xml(data)
        html = Template.new(rhtml, :caches => caches).result
        html.sub!('/* %css% */', "\n" + File.read('gcstats.css'))
        html.sub!('/* %js% */', "\n" + File.read('gcstats.js'))
        res.write html
      rescue
        res.status = 500
        res.write '<h1>Internal Server Error</h1>'
      end
    end

    res.finish
  end
end

app = GCStatsApp.new

run app
