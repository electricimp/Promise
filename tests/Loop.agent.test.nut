
/**
 * "Promise" symbol is injected dependency from ImpUnit_Promise module,
 * while class being tested can be accessed from global scope as "::Promise".
 */

/**
 * Test case for Promise.loop()
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
     * Check immediate stop
     */
    function testImmediateStop() {
        return Promise(function(ok, err) {
            local p = ::Promise.loop(
                @() false,
                function () {
                    throw "next() shold not be called"
                }.bindenv(this)
            );
            p.then(ok, err);
        }.bindenv(this));
    }

    /**
     * Test looping with all resolves
     */
    function testLoopingWithResolves() {
        return Promise(function(ok, err) {
            local i = 0;

            local loopPromise = ::Promise.loop(
                @() i++ < 3,
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

    /**
     * Test looping with exit on rejection
     */
    function testLoopingWithRejection() {
        return Promise(function(ok, err) {
            local i = 0;

            local loopPromise = ::Promise.loop(
                @() i < 10,
                function () {
                    return ::Promise(function (resolve, reject) {
                        ++i == 5 ? reject("abc" + i) : resolve("abc" + i);
                    });
                }
            );

            loopPromise

                .then(function (v) {
                    err(".then() should not be called on looped Promise rejection")
                })

                .fail(function (v) {
                    try {
                        this.assertEqual(5, i); // when i==5, looped Promise rejects
                        this.assertEqual("abc5", v); // last value that looped promise rejected with
                        ok();
                    } catch (e) {
                        err(e);
                    }
                }.bindenv(this));

        }.bindenv(this));
    }
}
