
/**
 * "Promise" symbol is injected dependency from ImpUnit_Promise module,
 * while class being tested can be accessed from global scope as "::Promise".
 */

class LoopTestCase extends ImpTestCase {
    /**
     * Check return type
     */
    function testReturnType() {
        local p = ::Promise.loop(
            function () {},
            function () {}
        );

        this.assertTrue(p instanceof ::Promise);
    }

    /**
     * Test looping with all resolves
     */
    function testLoopingWithResolves() {
        return Promise(function(ok, err) {
            local i = 0;

            local loopPromise = ::Promise.loop(
                function () { return i++ < 3 },
                function () {
                    return ::Promise(function (resolve, reject) {
                        resolve("abc" + i);
                    });
                }
            );

            loopPromise
                .then(function (v) {
                    try {
                        this.assertEqual(4, i); // when i==4, loop should break
                        this.assertEqual("abc3", v); // last value that looped promise resolved with
                        ok();
                    } catch (e) {
                        err(e);
                    }
                }.bindenv(this));

        }.bindenv(this));
    }
}
