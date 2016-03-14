
/**
 * "Promise" symbol is injected dependency from ImpUnit_Promise module,
 * while class being tested can be accessed from global scope as "::Promise".
 */

class ThenAfterFailTestCase extends ImpTestCase {
    /**
     * Test that .then() placed after .fail() should be called on rejection
     */
    function testThenAfterFail() {
        return Promise(function(ok, err) {

            local thenCalled = false;
            local failCalled = false;
            local thenAfterFailedCalled = false;

            local p = ::Promise(function (resolve, reject) {
                reject();
            });

            p
                .then(function (v) { thenCalled = true; }) // should NOT be called
                .fail(function (v) { failCalled = true; }) // should be called
                .then(function (v) { thenAfterFailedCalled = true; }) // should be called

            imp.wakeup(0, function() {
                try {
                    this.assertEqual(false, thenCalled);
                    this.assertEqual(true, failCalled);
                    this.assertEqual(true, thenAfterFailedCalled,
                        ".then() expected to be called after .fail() on rejection");
                } catch (e) {
                    err(e);
                }
            }.bindenv(this))

        }.bindenv(this));
    }
}
