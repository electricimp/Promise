/**
 * "Promise" symbol is injected dependency from ImpUnit_Promise module,
 * while class being tested can be accessed from global scope as "::Promise".
 */

/**
 * Test case for Promise.first()
 */
class FirstTestCase extends ImpTestCase {
    /**
     * Check return type
     */
    function testReturnType() {
        local p = ::Promise.first([]);
        this.assertTrue(p instanceof ::Promise);
    }


    /**
     * Test .first() with empty array
     */
    function testEmptyPromisesArray() {
        return Promise(function(ok, err) {
            local p = ::Promise.first([]);
            p
                .then(@() err("When empty array is passed to .first(), returned promise should not resolve"))
                .fail(@() err("When empty array is passed to .first(), returned promise should not reject"));
            imp.wakeup(0, ok);
        }.bindenv(this));
    }

    /**
     * Test .first() with all Promises in the chain resolving
     */
    function testFirstWithAllResolving() {
        return Promise(function(ok, err) {

            local promises = [
                // resolves first as the other one with "1" value
                // starts later from inside .first()
                ::Promise(function (resolve, reject) { imp.wakeup(0, @() resolve(1)) }),
                @() ::Promise(function (resolve, reject) { imp.wakeup(0.5, @() resolve(2)) }),
                @() ::Promise(function (resolve, reject) { imp.wakeup(0, @() resolve(3)) }),
            ];

            ::Promise.first(promises)
                .then(function (v) {
                    try {
                        // .first() should resolve with value of the first resolved promise
                        this.assertEqual(1, v);
                        ok();
                    } catch (e) {
                        err(e);
                    }
                }.bindenv(this));

        }.bindenv(this));
    }

    /**
     * Test .first() with rejection
     */
    function testFirstWithRejection() {
        return Promise(function(ok, err) {

            local promises = [
                // rejects first as the other one with "1" value
                // starts later from inside .first()
                ::Promise(function (resolve, reject) { imp.wakeup(0, @() reject(1)) }),
                @() ::Promise(function (resolve, reject) { imp.wakeup(0.5, @() resolve(2)) }),
                @() ::Promise(function (resolve, reject) { imp.wakeup(0, @() reject(3)) }),
            ];

            ::Promise.first(promises)

                .then(@(v) err(".then() should not be called on .first Promise rejection"))

                .fail(function (v) {
                    try {
                        // .first() should reject with value of the first rejected promise
                        this.assertEqual(1, v);
                        ok();
                    } catch (e) {
                        err(e);
                    }
                }.bindenv(this));

        }.bindenv(this));
    }
}
