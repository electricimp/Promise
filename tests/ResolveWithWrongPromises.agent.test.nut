
/**
 * "Promise" symbol is injected dependency from ImpUnit_Promise module,
 * while class being tested can be accessed from global scope as "::Promise".
 */

class ResolveWithWrongPromises extends ImpTestCase {
    /**
     * Test resolution of Promise with wrong Promise
     */
    function testResolutionWithPromise() {
        return Promise(function(ok, err) {

            local p = ::Promise(function (resolve1, reject1) {
                local MyClass = class {
                        function then(){
                            return 0;
                        }
                    };
                resolve1(MyPromise());
            });

            p.then(function (res) {
                err("Resolve handler is called " + res);
            }.bindenv(this), function(res) { 
                ok("Reject handler is called " + res);
            }.bindenv(this));

        }.bindenv(this));
    }

    /**
     * Test resolution of Promise with table
     */
    function testResolutionWithTable() {
        return Promise(function(ok, err) {

            local p = ::Promise(function (resolve1, reject1) {
                resolve1({then = ::Promise(function (resolve2, reject2) {
                    resolve2("abc");
                })});
            });

            p.then(function (res) {
                ok("Resolve handler is called " + res);
            }.bindenv(this), function(res) { 
                err("Reject handler is called " + res);
            }.bindenv(this));

        }.bindenv(this));
    }
}
