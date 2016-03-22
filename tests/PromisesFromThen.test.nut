
/**
 * "Promise" symbol is injected dependency from ImpUnit_Promise module,
 * while class being tested can be accessed from global scope as "::Promise".
 */

 // todo: add .then() returning a rejecting promise

class PromisesFromThenTestCase extends ImpTestCase {

    /**
     * Test .then() returning Promise
     */
    function testThenReturningPromise() {
        return Promise(function(ok, err) {
            local p = ::Promise(function (resolve, reject) {
                resolve();
            });

            p
                .then(@(v) ::Promise(function (resolve, reject) {
                    imp.wakeup(0.5, ok); // should called before next .then() in correct implementation
                }))
                .then(@(v) err("When .then() returns a Promise, next .then()-s should not be called before it resolves"));

        }.bindenv(this));
    }
}
