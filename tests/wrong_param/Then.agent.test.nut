// Copyright (c) 2017 Electric Imp
// This file is licensed under the MIT License
// http://opensource.org/licenses/MIT

// "Promise" symbol is injected dependency from ImpUnit_Promise module,
// while class being tested can be accessed from global scope as "::Promise".

class Then extends ImpTestCase {
    
    function _wrongFirst(values) {
        local promises = [];
        foreach (value in values) {
            promises.append(
                ::Promise(function(ok, err) {
                    local myValue = value;
                    local msg = "with value='" + myValue + "'";
                    local _value = null;
                    try {
                        ::Promise(function (resolve, reject) {
                            resolve(1);
                        }).then(myValue).then(function(res) { 
                            _value = res;
                        }.bindenv(this), function(res) { 
                            msg = "Reject handler is called " + msg;
                        }.bindenv(this));
                    } catch(ex) {
                        msg = "Unexpected error " + ex + " " + msg;
                    }
                    imp.wakeup(1, function() {
                        if (_value == null) {
                            server.log("Fail " + msg);
                            err("Fail " + msg);
                        } else {
                            //server.log("Pass " + msg);
                            ok("Pass " + msg);
                        }
                    }.bindenv(this));
                }.bindenv(this))
            );
        }
        return Promise(function(ok, err) {
            ::Promise.all(promises).then(ok, err);
        }.bindenv(this));
    }

    function testWrongFirst_1() {
        return _wrongFirst([false]);
    }

    function testWrongFirst_2() {
        return _wrongFirst([0, ""]);
    }

    function testWrongFirst_3() {
        return _wrongFirst(["tmp", 0.001
        , regexp(@"(\d+) ([a-zA-Z]+)(\p)")]);
    }

    function testWrongFirst_4() {
        return _wrongFirst([null, blob(4), array(5)]);
    }

    // Disabled case: function() {}
    // Issue: The behavior of Promise.then() should be the same in cases of wrong parameters #25
    function testWrongFirst_5() {
        return _wrongFirst([{
            firstKey = "Max Normal", 
            secondKey = 42, 
            thirdKey = true
        }, /*function() {
        },*/  class {
            tmp = 0;
            constructor(){
                tmp = 15;
            }
            
        }]);
    }

    function testWrongFirst_6() {
        return _wrongFirst([server]);
    }

    function _wrongSecond(values) {
        local promises = [];
        foreach (value in values) {
            promises.append(
                ::Promise(function(ok, err) {
                    local msg = "with value='" + value + "'";
                    local _value = null;
                    try {
                        ::Promise(function (resolve, reject) {
                            reject(1);
                        }).then(null, value).then(function(res) { 
                            msg = "Resolve handler is called " + msg;
                        }.bindenv(this), function(res) { 
                            _value = res;
                        }.bindenv(this));
                    } catch(ex) {
                        msg = "Unexpected error " + ex + " " + msg;
                    }
                    imp.wakeup(1, function() {
                        if (_value == null) {
                            server.log("Fail " + msg);
                            err("Fail " + msg);
                        } else {
                            //server.log("Pass " + msg);
                            ok("Pass " + msg);
                        }
                    }.bindenv(this));
                }.bindenv(this))
            );
        }
        return Promise(function(ok, err) {
            ::Promise.all(promises).then(ok, err);
        }.bindenv(this));
    }

    function testWrongSecond_1() {
        return _wrongSecond([false]);
    }

    function testWrongSecond_2() {
        return _wrongSecond([0, ""]);
    }

    function testWrongSecond_3() {
        return _wrongSecond(["tmp", 0.001
        , regexp(@"(\d+) ([a-zA-Z]+)(\p)")]);
    }

    function testWrongSecond_4() {
        return _wrongSecond([null, blob(4), array(5)]);
    }

    function testWrongSecond_5() {
        return _wrongSecond([{
            firstKey = "Max Normal", 
            secondKey = 42, 
            thirdKey = true
        }, function() {
        },  class {
            tmp = 0;
            constructor(){
                tmp = 15;
            }
            
        }]);
    }

    function testWrongSecond_6() {
        return _wrongSecond([server]);
    }

    function testWrongCount() {
        local values = [false, 0, "", "tmp", 0.001
        , regexp(@"(\d+) ([a-zA-Z]+)(\p)")
        , blob(4), array(5), {
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
        foreach (value in values) {
            local p = ::Promise(function (resolve, reject) {
                resolve(1);
            });
            try {
                p.then(value, value, value);
                this.assertTrue(false, "Exception is expected. Value="+value);
            } catch(err) {
            }
        }
    }
}
