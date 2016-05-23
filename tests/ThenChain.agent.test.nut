/**
 * "Promise" symbol is injected dependency from ImpUnit_Promise module,
 * while class being tested can be accessed from global scope as "::Promise".
 */

class ThenChainTestCase extends ImpTestCase {
    /**
     * Test a chain of `then`, with each return value being passed to the next
     * handler
     */
    function testThenChaining() {
        return Promise(function(ok, err) {
            ::Promise.resolve("value").then(@(val) val + 1)
                .then(@(val) val + 2)
                .then(@(val) val + 3)
                .then(function(val) {
                    this.assertEqual(val, "value123");
                    ok();
                }.bindenv(this)).fail(err);
        }.bindenv(this));
    }
}
