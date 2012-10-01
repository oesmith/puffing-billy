var assert = require('assert'),
    http = require('http'),
    request = require('request'),
    connect = require('connect'),
    async = require('async'),
    billy = require('../index.js');

describe('puffing-billy', function () {
  beforeEach(function (done) {
    var self = this;
    async.parallel([
      function (callback) {
        self.proxy = billy(callback);
      },
      function (callback) {
        var app = connect();
        app.use(function (req, res) {
          res.end(req.url);
        });
        self.server = http.createServer(app);
        self.server.listen(0, '127.0.0.1');
        self.server.on('listening', callback);
      }
    ], done);
  });

  afterEach(function () {
    this.proxy.close();
    this.server.close();
  });

  it('should proxy stuff', function (done) {
    request.get({
      url: 'http://localhost:' + this.server.address().port + '/foobarbaz',
      proxy: 'http://localhost:' + this.proxy.address().port
    }, function (error, response, body) {
      assert.equal(error, null);
      assert.equal(response.statusCode, 200);
      assert.equal(body, '/foobarbaz');
      done();
    });
  });
});
