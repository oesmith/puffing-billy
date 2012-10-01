var http = require('http'),
    request = require('request');

module.exports = function (callback) {
  var proxy = http.createServer(function (req, res) {
    var proxy_req = request({
      url: req.url,
      method: req.method,
      headers: req.headers,
      followRedirect: false
    }, function (error, response, body) {
      // TODO
    });

    req.pipe(proxy_req).pipe(res);
  });

  proxy.listen(0);

  proxy.on('listening', function () {
    if (callback !== undefined) {
      callback(null, proxy);
    }
  });

  return proxy;
};

