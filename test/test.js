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
    ], function (error) {
      self.http_url = 'http://localhost:' + self.server.address().port;
      self.https_url = 'https://localhost:' + self.ssl_server.address().port;
      self.proxy_url = 'http://localhost:' + self.proxy.port();
      self.request = request.defaults({ proxy: self.proxy_url });
      done(error);
    });
  });

  afterEach(function () {
    this.proxy.close();
    this.server.close();
  });

  describe('proxying', function () {
    it('should proxy HTTP', function (done) {
      this.request.get(this.http_url + '/http_upstream', function (error, response, body) {
        assert.equal(error, null);
        assert.equal(response.statusCode, 200);
        assert.equal(body, '/http_upstream');
        done();
      });
    });

    it('should proxy HTTPS', function (done) {
      this.request.get(this.https_url + '/https_upstream', function (error, response, body) {
        assert.equal(error, null);
        assert.equal(response.statusCode, 200);
        assert.equal(body, '/https_upstream');
        done();
      });
    });
  });

  describe('stubbing', function () {
    it('should stub HTTP', function (done) {
      this.proxy.stub(this.http_url + '/stub_http', {data: 'stubbed_http_text'});
      this.request.get(this.http_url + '/stub_http', function (error, response, body) {
        assert.equal(error, null);
        assert.equal(response.statusCode, 200);
        assert.equal(body, 'stubbed_http_text');
        assert.equal(response.headers['content-type'], 'text/plain');
        done();
      });
    });

    it('should stub HTTPS', function (done) {
      this.proxy.stub(this.https_url + '/stub_https', {data: 'stubbed_https_text'});
      this.request.get(this.https_url + '/stub_https', function (error, response, body) {
        assert.equal(error, null);
        assert.equal(response.statusCode, 200);
        assert.equal(body, 'stubbed_https_text');
        assert.equal(response.headers['content-type'], 'text/plain');
        done();
      });
    });

    it('should stub POSTs');
    it('should stub PUTs');
    it('should stub DELETEs');

    it('should stub JSON data', function (done) {
      this.proxy.stub(this.https_url + '/stub_json', {json: {stub: ['json', 'data'], awesome: true}});
      this.request.get(this.https_url + '/stub_json', function (error, response, body) {
        assert.equal(error, null);
        assert.equal(response.statusCode, 200);
        assert.equal(body, JSON.stringify({stub: ['json', 'data'], awesome: true}));
        assert.equal(response.headers['content-type'], 'application/json');
        done();
      });
    });

    it('should stub files', function (done) {
      this.proxy.stub(this.https_url + '/stub_file', {file: __dirname + '/fixtures/test.jpg'});
      this.request.get(this.https_url + '/stub_file', function (error, response, body) {
        assert.equal(error, null);
        assert.equal(response.statusCode, 200);
        assert.equal(body, fs.readFileSync(__dirname + '/fixtures/test.jpg'));
        assert.equal(response.headers['content-type'], 'image/jpeg');
        done();
      });
    });

    it('should stub custom content-types', function (done) {
      this.proxy.stub(this.https_url + '/stub_content_type', {data: 'stubbed_content_type', type: 'text/html'});
      this.request.get(this.https_url + '/stub_content_type', function (error, response, body) {
        assert.equal(error, null);
        assert.equal(response.statusCode, 200);
        assert.equal(body, 'stubbed_content_type');
        assert.equal(response.headers['content-type'], 'text/html');
        done();
      });
    });

    it('should reset stubs', function (done) {
      this.proxy.stub(this.https_url + '/reset', {data: 'reset_content'});
      this.proxy.reset();
      this.request.get(this.https_url + '/reset', function (error, response, body) {
        assert.equal(error, null);
        assert.equal(response.statusCode, 200);
        assert.equal(body, '/reset');
        done();
      });
    });
  });

  describe('RESTful configuration', function () {
    it('should add new stubs', function (done) {
      var self = this;
      request({
        url: this.proxy_url + '/puffing-billy/stub',
        method: 'POST',
        headers: { 'HTTP-X-Puffing-Billy': 1 },
        json: {
          url: this.https_url + '/restful_config',
          data: 'restfully configured stub'
        }
      }, function (error) {
        assert.equal(error, null);
        self.request.get(self.https_url + '/restful_config', function (error, response, body) {
          assert.equal(error, null);
          assert.equal(response.statusCode, 200);
          assert.equal(body, 'restfully configured stub');
          assert.equal(response.headers['content-type'], 'text/plain');
          done();
        });
      });
    });

    it('should reset stubs', function (done) {
      var self = this;
      this.proxy.stub(this.https_url + '/restful_reset', 'restfully reset stub');
      request({
        url: this.proxy_url,
        method: 'DELETE',
        headers: { 'HTTP-X-Puffing-Billy': 1 }
      }, function (error) {
        assert.equal(error, null);
        self.request.get(self.https_url + '/restful_reset', function (error, response, body) {
          assert.equal(error, null);
          assert.equal(response.statusCode, 200);
          assert.equal(body, '/restful_reset');
          done();
        });
      });
    });
  });

  describe('caching', function () {
    it('should cache upstream requests that are cacheable');
    it('should not cache upstream requests that are not cacheable');
  });
});
