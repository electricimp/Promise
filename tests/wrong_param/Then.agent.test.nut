// MIT License
//
// Copyright 2017 Electric Imp
//
// SPDX-License-Identifier: MIT
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

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
