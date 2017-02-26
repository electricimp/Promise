/**
 * "Promise" symbol is injected dependency from ImpUnit_Promise module,
 * while class being tested can be accessed from global scope as "::Promise".
 */

// Case resolve - then(func, func) + fail(func) + finally()
class DifferentValues extends ImpTestCase {
    values = [true, false, 0, 1, -1, "", "tmp", 0.001, 0.0, -0.001
        , regexp(@"(\d+) ([a-zA-Z]+)(\p)")
        , regexp2(@"(\d+) ([a-zA-Z]+)(\p)")
        , null, blob(4), array(5), {
            firstKey = "Max Normal", 
            secondKey = 42, 
            thirdKey = true
        }, function() {
            return 15;
        },  class {
            tmp = 0;
            constructor(){
                tmp = 15;
            }
            
        }, server];

    function _basicResolving(isDelyed) {
        local promises = [];
        foreach (value in values) {
            promises.append(
                Promise(function(ok, err) {
                    // 1 - resolve handler is called
                    // 2 - value is wrong in resolve handler
                    // 4 - reject handler is called
                    // 8 - value is wrong in reject handler
                    // 16 - fail handler is called
                    // 32 - value is wrong in fail handler
                    // 64 - finally handler is called
                    // 128 - value is wrong in finally handler
                    local iState = 0;

                    local p = ::Promise(function (resolve, reject) {
                        if (isDelyed) { // delayed resolving
                            imp.wakeup(0.1, function () {
                                resolve(value);
                            }.bindenv(this));
                        } else { // basic resolving
                            resolve(value);
                        }
                    }.bindenv(this));
                    p.then(function(res) { 
                        assertDeepEqual(value, res, "Resolve handler - wrong value, value=" + res);
                        iState &= 1; // 1 - resolve handler is called
                        //TODO
                        if (value != res) {
                            iState &= 2; // 2 - value is wrong in resolve handler
                        }
                    }.bindenv(this), function(res) { 
                        assertDeepEqual(value, res, "Reject handler - wrong value, value=" + res);
                        iState &= 4; // 4 - reject handler is called
                        //TODO
                        if (value != res) {
                            iState &= 8; // 8 - value is wrong in reject handler
                        }
                    }.bindenv(this));
                    p.fail(function(res) { 
                        assertDeepEqual(value, res, "Fail handler - wrong value, value=" + res);
                        iState &= 16; // 16 - fail handler is called
                        //TODO
                        if (value != res) {
                            iState &= 32; // 32 - value is wrong in fail handler
                        }
                    }.bindenv(this);
                    p.finally(function(res) {
                        assertDeepEqual(value, res, "Finally handler - wrong value, value=" + res);
                        iState &= 64; // 64 - finally handler is called
                        //TODO
                        if (value != res) {
                            iState &= 128; // 128 - value is wrong in finally handler
                        }
                    }.bindenv(this)));

                    // at this point Promise should not be resolved as it's body is handled in imp.wakeup(0)
                    assertEqual(0, iState, "The Promise should not be resolved strict after the promise declaration");

                    // now it should be resolved
                    imp.wakeup(isDelyed ? 0.2 : 0, function() {
                        // 1 - resolve handler is called
                        // 2 - value is wrong in resolve handler
                        // 4 - reject handler is called
                        // 8 - value is wrong in reject handler
                        // 16 - fail handler is called
                        // 32 - value is wrong in fail handler
                        // 64 - finally handler is called
                        // 128 - value is wrong in finally handler
                        assertTrue(iState & 1, "resolve handler is not called");
                        assertTrue(iState & 2, "value is wrong in resolve handler");
                        assertTrue(iState & 64, "finally handler is not called");
                        assertTrue(iState & 128, "value is wrong in finally handler");
                        if (iState & 0X3C) { // 0011 1100 = 0X3C
                            err("Failed value=" + value + ", iState=" + iState);
                        } else {
                            ok();
                        }
                    }.bindenv(this));
                })
            );
        }
        return promises;
    }

    /**
     * Test basic resolving
     */
    function testBasicResolving() {
        return Promise.all(_basicResolving(false));
    }

    /**
     * Test delayed resolving
     */
    function testDelayedResolving() {
        return Promise.all(_basicResolving(true));
    }

    /**
     * Test resolving with nested promises
     */
    function testNestedResolve() {
        local promises = [];
        local res = ::Promise.resolve.bindenv(::Promise);
        foreach (nextValue in values) {
            promises.append(Promise(function(ok, err) {
                res(res(res(nextValue)))
                .then(function(value) {
                    this.assertDeepEqual(nextValue, value, , "Promise is resolved with wrong value, value=" + value);
                    ok();
                }.bindenv(this), err).fail(err);
            }.bindenv(this)));
        }
        return Promise.all(promises);
    }
}
