/**
 * "Promise" symbol is injected dependency from ImpUnit_Promise module,
 * while class being tested can be accessed from global scope as "::Promise".
 */

class BasicTestCase extends ImpTestCase {
    /**
     * Test basic resolving
     */
    function testBasicResolving() {
        return Promise(function(ok, err) {
            local isResolved = false;

            local p = ::Promise(function (resolve, reject) {
                resolve();
            }.bindenv(this));

            p.then(function(res) {isResolved = true;}.bindenv(this));

            // at this point Promise should not be resolved as it's body is handled in imp.wakeup(0)
            this.assertEqual(false, isResolved);

            // now it should be resolved
            imp.wakeup(0, function() {
                isResolved ? ok() : err("Promise is expected to be resolved");
            }.bindenv(this));

        }.bindenv(this));
    }

    /**
     * Test delayed resolving
     */
    function testDelayedResolving() {
        return Promise(function(ok, err) {
            local p = ::Promise(function (resolve, reject) {
                imp.wakeup(0.1, function () {
                    resolve();
                }.bindenv(this));
            });

            p.then(ok);

        }.bindenv(this));
    }

    /**
     * Test delayed rejection
     */
    function testDelayedRejection() {
        return Promise(function(ok, err) {
            local p = ::Promise(function (resolve, reject) {
                imp.wakeup(0.1, function () {
                    reject();
                }.bindenv(this));
            });

            p.fail(ok);

        }.bindenv(this));
    }
}
