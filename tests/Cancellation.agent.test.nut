
/**
 * "Promise" symbol is injected dependency from ImpUnit_Promise module,
 * while class being tested can be accessed from global scope as "::Promise".
 */

class CancellationTestCase extends ImpTestCase {
    /**
     * Test cancellation
     */
    function test01_Cancellation() {
        return Promise(function(ok, err) {

            local p = ::Promise(function (resolve, reject) {
                imp.wakeup(0.5, resolve);
            });

            p
                .then(function (value) {
                    err("Should not be called");
                })
                .cancelled(function (reason) {
                    ok(reason);
                })
                .fail(function (reason) {
                    err("Should not be called");
                });

            p.cancel("Cancelled");

        }.bindenv(this));
    }

    /**
     * Test cancellation from within action function
     */
    function test02_CancellationWithinActionFunction() {
        return Promise(function(ok, err) {

            local p;

            p = ::Promise(function (resolve, reject) {
                imp.wakeup(1, resolve);

                this.cancelled(function (reason) {
                    // some process may be interrupted here
                    ok(reason);
                });
            });

            p
                .then(function (value) {
                    err("Should not be called");
                })
                .fail(function (reason) {
                    err("Should not be called");
                });

            imp.wakeup(0.33, function() { p.cancel("Interrupted") });

        }.bindenv(this));
    }
}
