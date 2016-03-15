/**
 * "Promise" symbol is injected dependency from ImpUnit_Promise module,
 * while class being tested can be accessed from global scope as "::Promise".
 */

/**
 * Test case for Promise.serial()
 */
class SerialTestCase extends ImpTestCase {
    /**
     * Check return type
     */
    function testReturnType() {
        local p = ::Promise.serial([]);
        this.assertTrue(p instanceof ::Promise);
    }

    /**
     * Test .serial() with all Promises in the chain resolving
     */
    function testSerialWithAllResolving() {
        return Promise(function(ok, err) {

            local promises = [
                ::Promise(function (resolve, reject) { resolve(1) }),
                ::Promise(function (resolve, reject) { resolve(2) }),
                ::Promise(function (resolve, reject) { resolve(3) })
            ];

            ::Promise.serial(promises)
                .then(function (v) {
                    try {
                        // .all() should resolve with value of the last value
                        // if all Promise's are resolving
                        this.assertEqual(3, v);
                        ok();
                    } catch (e) {
                        err(e);
                    }
                }.bindenv(this));

        }.bindenv(this));
    }
}
