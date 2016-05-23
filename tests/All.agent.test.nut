/**
 * "Promise" symbol is injected dependency from ImpUnit_Promise module,
 * while class being tested can be accessed from global scope as "::Promise".
 */

/**
 * Test case for Promise.all()
 */
class AllTestCase extends ImpTestCase {
    /**
     * Check return type
     */
    function testReturnType() {
        local p = ::Promise.all([]);
        this.assertTrue(p instanceof ::Promise);
    }

    /**
     * Test .all() with empty array
     */
    function testEmptyPromisesArray() {
        return Promise(function(ok, err) {
            local p = ::Promise.all([]);
            p.then(function (v) {
                try {
                    this.assertDeepEqual([], v);
                    ok();
                } catch (e) {
                    err(e);
                }
            }.bindenv(this));
        }.bindenv(this));
    }

    /**
     * Test .all() with all Promises in the chain resolving
     */
    function testAllWithAllResolving() {
        return Promise(function(ok, err) {

            local promises = [
                ::Promise(function (resolve, reject) { resolve(1) }),
                @() ::Promise(function (resolve, reject) { resolve(2) }),
                ::Promise(function (resolve, reject) { resolve(3) })
            ];

            ::Promise.all(promises)
                .then(function (v) {
                    try {
                        // .all() should resolve with value of the last value
                        // if all Promise's are resolving
                        this.assertEqual(1, v[0]);
                        this.assertEqual(2, v[1]);
                        this.assertEqual(3, v[2]);
                        ok();
                    } catch (e) {
                        err(e);
                    }
                }.bindenv(this));

        }.bindenv(this));
    }

    /**
     * Test .all() with all Promises in the chain resolving
     */
    function testAllWithRejection() {
        return Promise(function(ok, err) {
            local promises = [
                ::Promise(function (resolve, reject) { resolve(1) }),
                @() ::Promise(function (resolve, reject) { reject(2) }), // rejects first as .fail() handlers are added in order of appearance
                ::Promise(function (resolve, reject) { reject(3) })
            ];

            ::Promise.all(promises)
                .then(function (v) {
                    err(".then() should not be called on all Promise rejection")
                })

                .fail(function (v) {
                    try {
                        // .all() should reject with value of the fisrt rejected promise
                        this.assertEqual(2, v);
                        ok();
                    } catch (e) {
                        err(e);
                    }
                }.bindenv(this));

        }.bindenv(this));
    }
}
