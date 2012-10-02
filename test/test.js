var assert = require('assert'),
    fs = require('fs'),
    http = require('http'),
    https = require('https'),
    request = require('request'),
    connect = require('connect'),
    async = require('async'),
    billy = require('../index.js');

describe('puffing-billy', function () {
  beforeEach(function (done) {
    var self = this;
    var app = connect();
    app.use(function (req, res) {
      res.end(req.url);
    });
    async.parallel([
      function (callback) {
        self.proxy = new billy.Proxy();
        self.proxy.on('listening', callback);
      },
      function (callback) {
        self.server = http.createServer(app);
        self.server.listen(0, '127.0.0.1');
        self.server.on('listening', callback);
      },
      function (callback) {
        var options = {
          key: fs.readFileSync('test/fixtures/billy.key'),
          cert: fs.readFileSync('test/fixtures/billy.crt')
        };
        self.ssl_server = https.createServer(options, app);
        self.ssl_server.listen(0, '127.0.0.1');
        self.ssl_server.on('listening', callback);
      }
    ], done);
  });

  afterEach(function () {
    this.proxy.close();
    this.server.close();
  });

  it('should proxy HTTP to upstream servers', function (done) {
    request.get({
      url: 'http://localhost:' + this.server.address().port + '/foobarbaz',
      proxy: 'http://localhost:' + this.proxy.port()
    }, function (error, response, body) {
      assert.equal(error, null);
      assert.equal(response.statusCode, 200);
      assert.equal(body, '/foobarbaz');
      done();
    });
  });

  it('should proxy HTTPS to upstream servers', function (done) {
    request.get({
      url: 'https://localhost:' + this.ssl_server.address().port + '/foobarbill',
      proxy: 'http://localhost:' + this.proxy.port()
    }, function (error, response, body) {
      assert.equal(error, null);
      assert.equal(response.statusCode, 200);
      assert.equal(body, '/foobarbill');
      done();
    });
  });

  it('should mock HTTP responses');
  it('should mock HTTPS responses');
  it('should cache upstream requests that are cacheable');
  it('should not cache upstream requests that are not cacheable');
});
