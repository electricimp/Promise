/**
 * "Promise" symbol is injected dependency from ImpUnit_Promise module,
 * while class being tested can be accessed from global scope as "::Promise".
 */

/**
 * Test case for Promise.parallel()
 */
class ParallelTestCase extends ImpTestCase {
    /**
     * Check return type
     */
    function testReturnType() {
        local p = ::Promise.parallel([]);
        this.assertTrue(p instanceof ::Promise);
    }

    /**
     * Test .parallel() with empty array
     */
    function testEmptyPromisesArray() {
        return Promise(function(ok, err) {
            local p = ::Promise.parallel([]);
            p.then(function (v) {
                try {
                    this.assertEqual(null, v);
                    ok();
                } catch (e) {
                    err(e);
                }
            }.bindenv(this));
        }.bindenv(this));
    }

    /**
     * Test .parallel() with all Promises in the chain resolving
     */
    function testParallelWithAllResolving() {
        return Promise(function(ok, err) {

            local promises = [
                ::Promise(function (resolve, reject) { resolve(1) }),
                @() ::Promise(function (resolve, reject) { resolve(2) }),
                ::Promise(function (resolve, reject) { resolve(3) })
            ];

            ::Promise.parallel(promises)
                .then(function (v) {
                    try {
                        // .parallel() should resolve with value of the last value
                        // if all Promise's are resolving
                        this.assertEqual(3, v);
                        ok();
                    } catch (e) {
                        err(e);
                    }
                }.bindenv(this));

        }.bindenv(this));
    }

    /**
     * Test .parallel() with all Promises in the chain resolving
     */
    function testParallelWithRejection() {
        return Promise(function(ok, err) {
            local promises = [
                ::Promise(function (resolve, reject) { resolve(1) }),
                @() ::Promise(function (resolve, reject) { reject(2) }), // rejects first as .fail() handlers are added in order of appearance
                ::Promise(function (resolve, reject) { reject(3) })
            ];

            ::Promise.parallel(promises)
                .then(function (v) {
                    err(".then() should not be called on parallel Promise rejection")
                })

                .fail(function (v) {
                    try {
                        // .parallel() should reject with value of the fisrt rejected promise
                        this.assertEqual(2, v);
                        ok();
                    } catch (e) {
                        err(e);
                    }
                }.bindenv(this));

        }.bindenv(this));
    }
}
