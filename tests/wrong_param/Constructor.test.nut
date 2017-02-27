/**
 * "Promise" symbol is injected dependency from ImpUnit_Promise module,
 * while class being tested can be accessed from global scope as "::Promise".
 */

class Constructor extends ImpTestCase {
    values = [true, false, 0, 1, -1, "", "tmp", 0.001, 0.0, -0.001
        , regexp(@"(\d+) ([a-zA-Z]+)(\p)")
        , null, blob(4), array(5), {
            firstKey = "Max Normal", 
            secondKey = 42, 
            thirdKey = true
        }, function(fff) {
            return fff;
        },  class {
            tmp = 0;
            constructor(){
                tmp = 15;
            }
            
        }, server];

    function testWrongType() {
        local promises = [];
        foreach (value in values) {
            promises.append(
                ::Promise(function(ok, err) {
                    // 1 - resolve handler is called
                    // 2 - value is wrong in resolve handler
                    // 4 - reject handler is called
                    // 8 - value is wrong in reject handler
                    // 16 - fail handler is called
                    // 32 - value is wrong in fail handler
                    // 64 - finally handler is called
                    // 128 - value is wrong in finally handler
                    local iState = 0;

                    local p = ::Promise(value).then(function(res) { 
                        iState = iState & 1; // 1 - resolve handler is called
                        //TODO
                        if (value != res) {
                            iState = iState & 2; // 2 - value is wrong in resolve handler
                        }
                    }.bindenv(this), function(res) { 
                        iState = iState & 4; // 4 - reject handler is called
                        //TODO
                        if (value != res) {
                            iState = iState & 8; // 8 - value is wrong in reject handler
                        }
                    }.bindenv(this));
                    p.fail(function(res) { 
                        server.log("fail"+res+""+typeof(res));
                        iState = iState & 16; // 16 - fail handler is called
                    }.bindenv(this));
                    p.finally(function(res) {
                        iState = iState & 64; // 64 - finally handler is called
                        //TODO
                        if (value != res) {
                            iState = iState & 128; // 128 - value is wrong in finally handler
                        }
                    }.bindenv(this));


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
                            err("Failed value=" + value + ", iState=" + iState);
                        } else {
                            ok();
                        }
                    }.bindenv(this));
                }.bindenv(this))
            );
        }
        return ::Promise.all(promises);
    }

    function testWrongCount() {
        local promises = [];
        foreach (value in values) {
            promises.append(
                ::Promise(function(ok, err) {
                    local isOk = false;
                    try {
                        local p = ::Promise(value, value);
                    } catch(err) {
                        isOk = true;
                    }
                    imp.wakeup(0, function() {
                        if (isOk) {
                            ok();
                        } else {
                            err();
                        }
                    }.bindenv(this));
                }.bindenv(this))
            );
        }
        return ::Promise.all(promises);
    }
}
