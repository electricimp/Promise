/**
 * "Promise" symbol is injected dependency from ImpUnit_Promise module,
 * while class being tested can be accessed from global scope as "::Promise".
 */

class FailChainTestCase extends ImpTestCase {
    /**
     * Test a chain of `fail`s, with each thrown value being passed to the next
     * handler
     */
    function testFailChaining() {
        return Promise(function(ok, err) {
            ::Promise.reject("reason")
                .fail(function(res) { throw res + 1})
                .fail(function(res) { throw res + 2})
                .fail(function(res) { throw res + 3})
                .fail(function(res) {
                    this.assertEqual(res, "reason123");
                    ok();
                }.bindenv(this)).fail(err);
        }.bindenv(this));
    }

    function testThenToFail() {
        return Promise(function(ok, err) {
            ::Promise.resolve("value")
                .then(function(v) { throw "reason"; })
                .fail(function(reason) {
                    this.assertEqual(reason, "reason");
                    ok();
                }.bindenv(this))
                .fail(err);
        }.bindenv(this));
    }

    function testFailToThen() {
        return Promise(function(ok, err) {
            ::Promise.reject("reason")
            .fail(function(reason) {
                return "value";
            }).then(function(value) {
                this.assertEqual(value, "value");
                ok();
            }.bindenv(this)).fail(err);
        }.bindenv(this));
    }
}
