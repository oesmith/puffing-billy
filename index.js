var http = require('http');

module.exports = http.createServer(function (req, res) {
  var proxy_req = http.request({
    hostname: req.headers['host'],
    path: req.url,
    method: req.method,
    headers: req.headers
  });
  proxy_req.addListener('response', function (proxy_res) {
    proxy_res.addListener('data', function(chunk) {
      res.write(chunk, 'binary');
    });
    proxy_res.addListener('end', function() {
      res.end();
    });
    res.writeHead(proxy_res.statusCode, proxy_res.headers);
  });
  req.addListener('data', function(chunk) {
    proxy_req.write(chunk, 'binary');
  });
  req.addListener('end', function() {
    proxy_req.end();
  });
});

