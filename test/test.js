var assert = require('assert'),
    http = require('http'),
    billy = require('../index.js');

describe('puffing-billy', function () {
  beforeEach(function () {
    billy.listen(8080);
  });

  afterEach(function () {
    billy.close();
  });

  it('should proxy stuff', function (done) {
    http.get({
      host: 'localhost',
      port: 8080,
      path: 'http://olly.oesmith.co.uk/~oliver/puffing-billy/foo.txt',
      headers: {
        Host: 'olly.oesmith.co.uk'
      }
    }, function (res) {
      var body = "";
      assert.equal(res.statusCode, 200);
      res.on('data', function (data) {
        body += data;
      });
      res.on('end', function () {
        assert.equal(body, 'foobar\n');
        done();
      });
      res.on('error', function () {
        assert(false, 'request failed');
        done();
      });
    });
  });
});
