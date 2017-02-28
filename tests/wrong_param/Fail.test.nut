/**
 * "Promise" symbol is injected dependency from ImpUnit_Promise module,
 * while class being tested can be accessed from global scope as "::Promise".
 */

class Fail extends ImpTestCase {
    values = [false, 0, "", "tmp", 0.001
        , regexp(@"(\d+) ([a-zA-Z]+)(\p)")
        , null, blob(4), array(5), {
            firstKey = "Max Normal", 
            secondKey = 42, 
            thirdKey = true
        }, function() {
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
                    local _value = null;
                    try {
                        ::Promise(function (resolve, reject) {
                            reject(1);
                        }).fail(value).fail(function(res) { 
                            _value = res;
                        }.bindenv(this));
                    } catch(err) {
                        assertTrue(false, "Unexpected error "+err);
                    }
                    imp.wakeup(0, function() {
                        if (_value == null) {
                            err("Fail with value="+value);
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
        this.assertTrue(true);
        foreach (value in values) {
            try {
                ::Promise(function (resolve, reject) {
                    reject(1);
                }).fail(value, value);
                this.assertTrue(false, "Exception is expected. Value="+value);
            } catch(err) {
            }
        }
    }
}
