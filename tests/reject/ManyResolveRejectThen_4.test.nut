/**
 * "Promise" symbol is injected dependency from ImpUnit_Promise module,
 * while class being tested can be accessed from global scope as "::Promise".
 */

// Case reject - then(null, func) + fail(func) + finally()
class ManyResolveRejectAllFuncs extends ImpTestCase {
    middleOfRand = 1.0 * RAND_MAX / 2;

    values = [true, false, 0, 1, -1, "", "tmp", 0.001, 0.0, -0.001
        , regexp(@"(\d+) ([a-zA-Z]+)(\p)")
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

    function _manyResolvingRejecting(isDelyed) {
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
                    local strChain = "";

                    local cb = function (resolve, reject) { // many resolve/reject call
                        foreach (nextValue in values) {
                            local rnd = math.rand();
                            if (middleOfRand < rnd) {
                                strChain += "1";
                                resolve(nextValue);
                            } else {
                                strChain += "0";
                                reject(nextValue);
                            }
                        }
                    }.bindenv(this));

                    local p = ::Promise(function (resolve, reject) {
                        if (isDelyed) { // delayed rejecting
                            imp.wakeup(0.1, function () {
                                reject(value);
                                cb(resolve, reject); // many resolve/reject call
                            }.bindenv(this));
                        } else { // basic rejecting
                            reject(value);
                            cb(resolve, reject); // many resolve/reject call
                        }
                    }.bindenv(this));
                    p.then(null, function(res) { 
                        assertDeepEqual(value, res, "Reject handler - wrong value, value=" + res);
                        iState = iState & 4; // 4 - reject handler is called
                        //TODO
                        if (value != res) {
                            iState = iState & 8; // 8 - value is wrong in reject handler
                        }
                    }.bindenv(this));
                    p.fail(function(res) { 
                        assertDeepEqual(value, res, "Fail handler - wrong value, value=" + res);
                        iState = iState & 16; // 16 - fail handler is called
                        //TODO
                        if (value != res) {
                            iState = iState & 32; // 32 - value is wrong in fail handler
                        }
                    }.bindenv(this));
                    p.finally(function(res) {
                        assertDeepEqual(value, res, "Finally handler - wrong value, value=" + res);
                        iState = iState & 64; // 64 - finally handler is called
                        //TODO
                        if (value != res) {
                            iState = iState & 128; // 128 - value is wrong in finally handler
                        }
                    }.bindenv(this));

                    // at this point Promise should not be rejected as it's body is handled in imp.wakeup(0)
                    assertEqual(0, iState, "The Promise should not be rejected strict after the promise declaration");

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
                        assertTrue(iState & 4, "reject handler is not called");
                        assertTrue(iState & 8, "value is wrong in reject handler");
                        assertTrue(iState & 16, "fail handler is not called");
                        assertTrue(iState & 32, "value is wrong in fail handler");
                        assertTrue(iState & 64, "finally handler is not called");
                        assertTrue(iState & 128, "value is wrong in finally handler");
                        if (iState & 0X03) { // 0000 0011 = 0X03
                            err("Failed value=" + value + ", strChain=" + strChain + ", iState=" + iState);
                        } else {
                            ok();
                        }
                    }.bindenv(this));
                }.bindenv(this))
            );
        }
        return promises;
    }

    /**
     * Test rejection with many resolve/reject call
     */
    function testBasicRejection() {
        return Promise.all(_manyResolvingRejecting(false));
    }

    /**
     * Test delayed rejection with many resolve/reject call
     */
    function testDelayedRejection() {
        return Promise.all(_manyResolvingRejecting(true));
    }
}
