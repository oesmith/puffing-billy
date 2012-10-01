var http = require('http'),
    net = require('net'),
    url = require('url'),
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

  proxy.on('connect', function (req, socket, head) {
    var parts = req.url.split(':');
    socket.pause();
    var proxy_sock = net.connect(parseInt(parts[1], 10), parts[0], function () {
      socket.write( "HTTP/1.0 200 Connection established\r\nProxy-agent: Netscape-Proxy/1.1\r\n\r\n");
      proxy_sock.write(head);
      socket.pipe(proxy_sock).pipe(socket);
      socket.resume();
    });
  });

  proxy.listen(0);

  proxy.on('listening', function () {
    if (callback !== undefined) {
      callback(null, proxy);
    }
  });

  return proxy;
};

