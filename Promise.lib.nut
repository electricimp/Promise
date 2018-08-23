// MIT License
//
// Copyright 2016-2017 Electric Imp
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


// Error messages
const PROMISE_ERR_UNHANDLED_REJ  = "Unhandled promise rejection: ";

// Promises for Electric Imp/Squirrel
class Promise {
    static VERSION = "4.0.0";

    static STATE_PENDING = 0;
    static STATE_FULFILLED = 1;
    static STATE_REJECTED = 2;

    _state = null;
    _value = null;
    _last = null;

    // @var {{resolve, reject}[]} _handlers
    _handlers = null;

    //
    // @param {function(resolve, reject)} action - action function
    //
    constructor(action) {
        _state = STATE_PENDING;
        _last = true;
        _handlers = [];

        try {
            action(
                _resolve.bindenv(this)
                _reject.bindenv(this)
            );
        } catch (e) {
            _reject(e);
        }
    }

    //
    // Execute chain of handlers
    //
    function _callHandlers() {
        if (STATE_PENDING != _state) {
            imp.wakeup(0, function() {
                if (_last && _handlers.len() == 0 && STATE_REJECTED == _state) {
                    server.log(PROMISE_ERR_UNHANDLED_REJ + _value);
                }
                foreach (handler in _handlers) {
                    (function (handler) { // create closure and bind handler to it
                        if (_state == STATE_FULFILLED) {
                            try {
                                handler.resolve(handler.onFulfilled(_value));
                            } catch (err) {
                                handler.reject(err);
                            }
                        } else if (_state == STATE_REJECTED) {
                            try {
                                handler.resolve(handler.onRejected(_value));
                            } catch (err) {
                                handler.reject(err);
                            }
                        }
                    })(handler);
                }

                _handlers = [];
            }.bindenv(this));
        }
    }

    //
    // Resolve promise with a value
    //
    function _resolve(value = null) {
        if (STATE_PENDING == _state) {
            // If promise is resolved with another promise let it resolve/reject
            // this one, otherwise resolve immediately
            if (_isPromise(value)) {
                value.then(
                    _resolve.bindenv(this),
                    _reject.bindenv(this)
                );
            } else {
                _state = STATE_FULFILLED;
                _value = value;
                _callHandlers();
            }
        }
    }

    //
    // Reject promise for a reason
    //
    function _reject(reason = null) {
        if (STATE_PENDING == _state) {
            _state = STATE_REJECTED;
            _value = reason;
            _callHandlers();
        }
    }

    //
    // Check if a value is a Promise.
    // @param {Promise|*} value
    // @return {boolean}
    //
    function _isPromise(value) {
        if (
            // detect that the value is some form of Promise
            // by the fact it has .then() method
            (typeof value == "instance")
            && ("then" in value)
            && (typeof value.then == "function")
          ) {
            return true
        }

        return false
    }

    //
    // Add handlers on resolve/rejection
    // @param {function|null} onFulfilled
    // @param {function|null} onRejected
    // @return {this}
    //
    function then(onFulfilled = null, onRejected = null) {
        // If either handler is left null, set it to our default handlers
        onFulfilled = (typeof onFulfilled == "function") ? onFulfilled : Promise._onFulfilled;
        onRejected  = (typeof onRejected  == "function") ? onRejected  : Promise._onRejected;

        local self = this;
        _last = false;
        local result = Promise(function(resolve, reject) {
            self._handlers.push({
                "resolve": resolve.bindenv(this),
                "onFulfilled": onFulfilled,
                "reject": reject.bindenv(this),
                "onRejected": onRejected
            })
        });

        _callHandlers();

        return result;
    }

    //
    // Add handler on rejection
    // @param {function} onRejected
    // @return {this}
    //
    function fail(onRejected) {
        return then(null, onRejected);
    }

    //
    // Add handler that is executed both on resolve and rejection
    // @param {function(value)} handler
    // @return {this}
    //
    function finally(handler) {
        return then(handler, handler);
    }

    //
    // The default `onFulfilled` handler (the identity function)
    //
    static function _onFulfilled(value) {
        return value;
    }

    //
    // The default rejection handler, just throws to the next handler
    //
    static function _onRejected(reason) {
        throw reason;
    }

    //
    // While loop with Promise's
    // Stops on continueCallback() == false or first rejection of looped Promise
    //
    // @param {function:boolean} condition - if returns false, loop stops
    // @param {function:Promise} next - function to get next promise in the loop
    // @return {Promise} Promise that is resolved/rejected with the last value that come from looped promise when loop finishes
    //
    static function loop(condition, next) {
        return Promise(function (resolve, reject) {

            local doLoop;
            local lastResolvedWith;

            doLoop = function() {
                if (condition()) {
                    next().then(
                        function (v) {
                            lastResolvedWith = v;
                            imp.wakeup(0, doLoop)
                        },
                        reject
                    );
                } else {
                    resolve(lastResolvedWith);
                }
            }

            imp.wakeup(0, doLoop);

        }.bindenv(this));
    }

    //
    // Returns Promise that resolves when
    // all promises in chain resolve:
    // one after each other.
    // Make every promise in array of promises not last
    // for suppressing Unhadled Exeptions Warnings
    //
    // @param {{Promise|function}[]} promises - array of Promises/functions that return Promises
    // @return {Promise} Promise that is resolved/rejected with the last value that come from looped promise
    //
    static function serial(promises) {
        local i = 0;
        return loop(
            @() i < promises.len(),
            function () {
                return "function" == type(promises[i])
                     ? promises[i++]()
                     : promises[i++];
            }
        )
    }

    //
    // Returns Promise that resolves when all promises in the list resolve
    //
    // @param {{Promise}[]} promises - array of Promises (or functions that
    // return promises)
    // @param {boolean} wait - whether to wait for all promises to resolve, or
    // just the first
    // @return {Promise} Promise that is resolved with the list of values that
    // `promises` resolved to (in order) OR with the value of the first promise
    // that resolves (depending on `wait`)
    //
    static function _parallel(promises, wait) {
        return Promise(function(resolve, reject) {
            local resolved = 0; // number of promises resolved
            local len = promises.len(); // number of promises given
            local result = array(len); // results array (for if we're waiting for all to resolve)
            // early return/resolve for case when `promises` is empty
            if (!len) return resolve(result);

            // resolve one promise with a value
            local resolveOne = function(index, value) {
                if (!wait) {
                    // early return if we're not waiting for all to resolve
                    return resolve(value);
                }
                result[index] = value;
                resolved += 1;
                if (resolved == len) {
                    resolve(result);
                }
            };

            foreach (index, promise in promises) {
                promise = (typeof promise == "function") ? promise() : promise;
                (function(index) {
                    promise.then(function(value) {
                        resolveOne(index, value);
                    }.bindenv(this), reject);
                }.bindenv(this))(index);

            }

        }.bindenv(this))
    }

    //
    // Returns Promise that resolves to an array containing the results of each
    // given promise (or rejects with the first rejected)
    // @param {{Promise}[]} promises - array of Promises (or functions which
    //          return promises)
    // @return {Promise} Promise that is resolved with the list of values that
    //          `promises` resolved to (in order) or rejects with the reason of the first
    //          of `promises` to reject
    //
    static function all(promises) {
        return _parallel(promises, true);
    }


    //
    // Returns Promise that resolves to the first value that any of the given
    // promises resolve to
    //
    // @param {{Promise}[]} promises - array of Promises (or functions which
    // return promises)
    // @return {Promise} Promise that is resolved with the to the value of the
    // first of `promises` to resolve (or rejects with the first to reject)
    //
    static function race(promises) {
        return _parallel(promises, false);
    }

    //
    // Returns promise that immediately resolves to the given value
    //
    // @param {*} value - value to resolve to
    // @return {Promise} - a Promise that immediately resolves to `value`
    //
    static function resolve(value) {
        return Promise(function(resolve, reject) {
            resolve(value);
        })
    }

    // Returns promise that immediately rejects with the given reason
    //
    // @param {*} value - value to resolve to
    // @return {Promise} - a Promise that immediately rejects with `reason`
    //
    static function reject(reason) {
        return Promise(function(resolve, reject) {
            reject(reason);
        })
    }
}
