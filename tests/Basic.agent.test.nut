
/**
 * "Promise" symbol is injected dependency from ImpUnit_Promise module,
 * while class being tested can be accessed from global scope as "::Promise".
 */

class BasicTestCase extends ImpTestCase {
    /**
     * Test basic resolving
     */
    function testBasicResoving() {
        return Promise(function(ok, err) {
            local isResolved = false;

            local p = ::Promise(function (resolve, reject) {
                resolve();
            });

            p.then(function(res) {isResolved = true;});

            // at this point Promise should not be resolved as it's body is handled in imp.wakeup(0)
            this.assertEqual(false, isResolved);

            // now it should be resolved
            imp.wakeup(0, function() {
                isResolved ? ok() : err("Promise is expected to be resolved");
            });

        }.bindenv(this));
    }

    /**
     * Test rejection with throw+fail() handler
     */
    function testCatchWithThenHandler2() {
        return Promise(function(ok, err) {
            local p = ::Promise(function (resolve, reject) {
                throw "Error in Promise";
            });

            p.then(err, @(res) ok());
        }.bindenv(this));
    }

    /**
     * Test rejection with reject()+fail() handler
     */
    function testCatchWithThenHandler2() {
        return Promise(function(ok, err) {
            local p = ::Promise(function (resolve, reject) {
                reject();
            });
            p.then(err, ok);
        }.bindenv(this));
    }

    /**
     * Test rejection with throw+fail() handler
     */
    function testCatchWithFailHandler1() {
        return Promise(function(ok, err) {
            local p = ::Promise(function (resolve, reject) {
                throw "Error in Promise";
            });
            p.then(err).fail(@(res) ok());
        }.bindenv(this));
    }

    /**
     * Test rejection with reject()+fail() handler
     */
    function testCatchWithFailHandler2() {
        return Promise(function(ok, err) {
            local p = ::Promise(function (resolve, reject) {
                reject();
            });
            p.then(err).fail(ok);
        }.bindenv(this));
    }

    /**
     * Test that finally() is called on rejection
     */
    function testFinallyCallOnRejection() {
        return Promise(function(ok, err) {

            local thenCalled = false;
            local failCalled = false;

            local p = ::Promise(function (resolve, reject) {
                reject();
            });

            p
                .then(function (v) { thenCalled = true; })
                .fail(function (v) { failCalled = true; })
                .finally(function (v) {
                    try {
                        this.assertEqual(false, thenCalled);
                        this.assertEqual(true, failCalled);
                        ok();
                    } catch (e) {
                        err(e);
                    }
                }.bindenv(this));


        }.bindenv(this));
    }

    /**
     * Test that finally() is called on resolution
     */
    function testFinallyCallOnResolution() {
        return Promise(function(ok, err) {

            local thenCalled = false;
            local failCalled = false;

            local p = ::Promise(function (resolve, reject) {
                resolve();
            });

            p
                .then(function (v) { thenCalled = true; })
                .fail(function (v) { failCalled = true; })
                .finally(function (v) {
                    try {
                        this.assertEqual(true, thenCalled);
                        this.assertEqual(false, failCalled);
                        ok();
                    } catch (e) {
                        err(e);
                    }
                }.bindenv(this));

        }.bindenv(this));
    }
}
