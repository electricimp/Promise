
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
     * Test delayed resolving
     */
    function testDelayedResoving() {
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

    /**
     * Test rejection with throw+fail() handler
     */
    function testCatchWithThenHandler1() {
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

    /**
     * Test that always() is called on resolution
     */
    function testAlwaysCallOnResolution() {
        return Promise(function(ok, err) {
            local p = ::Promise(function (resolve, reject) {resolve();});
            p.always(ok);
        }.bindenv(this));
    }

    /**
     * Test that always() is called on rejection
     */
    function testAlwaysCallOnResolution() {
        return Promise(function(ok, err) {
            local p = ::Promise(function (resolve, reject) {reject();});
            p.always(ok);
        }.bindenv(this));
    }

    /**
     * Test that always() is called on cancellation
     */
    function testAlwaysCallOnResolution() {
        return Promise(function(ok, err) {
            local p = ::Promise(function (resolve, reject) {this.cancel("abc");});
            p.always(function (v) {
                "abc" == v ? ok() : err();
            });
        }.bindenv(this));
    }

    /**
     * This test appeared due to Squirrel's not creating
     * new instances of variables defined in a class
     * outdide the constructor on new instance creation,
     * which is a bit weird
     *
     *  eg:
     *
     * class C  {
     *   _var = [];
     *
     *   function add(val) {
     *     this._var.push(val);
     *   }
     * }
     *
     * local c1 = C();
     * local c2 = C();
     * c2.add(1);
     *
     * print(c1._var) // == [1]
     *
     */
    function testHandlerInstances() {
        return Promise(function(ok, err) {
            local p1 = ::Promise(function (resolve, reject) {
            });

            p1.then(function (v) {
                err("p1 handlers should not be called");
            });

            local p2 = ::Promise(function (resolve, reject) {
                imp.wakeup(0.5, function() {
                    resolve();
                });
            });

            p2.then(function (v) {
            });

            p2.then(function (v) {
                ok();
            });

        }.bindenv(this));
    }
}
