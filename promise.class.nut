/**
 * Promises for Electric Imp/Squirrel
 *
 * @author Mikhail Yurasov <mikhail@electricimp.com>
 * @author Aron Steg <aron@electricimp.com>
 * @author Jaye Heffernan <jaye@mysticpants.com>
 * @version 3.0.0
 */
class Promise {
    static version = [3, 0, 0];

    static STATE_PENDING = 0;
    static STATE_FULFILLED = 1;
    static STATE_REJECTED = 2;

    _state = null;
    _value = null;

    /* @var {{resolve, reject}[]} _handlers */
    _handlers = null;

    /**
    * @param {function(resolve, reject)} action - action function
    */
    constructor(action) {
        this._state = this.STATE_PENDING;
        this._handlers = [];

        try {
            action(
                this._resolve.bindenv(this)
                this._reject.bindenv(this)
            );
        } catch (e) {
            this._reject(e);
        }
    }

    /**
     * Execute chain of handlers
     */
    function _callHandlers() {
        if (this.STATE_PENDING != this._state) {
            imp.wakeup(0, function() {
                foreach (handler in this._handlers) {
                    (/* create closure and bind handler to it */ function (handler) {
                        if (this._state == this.STATE_FULFILLED) {
                            try {
                                handler.resolve(handler.onFulfilled(this._value));
                            } catch (err) {
                                handler.reject(err);
                            }
                        } else if (this._state == this.STATE_REJECTED) {
                            try {
                                handler.resolve(handler.onRejected(this._value));
                            } catch (err) {
                                handler.reject(err);
                            }
                        }
                    })(handler);
                }

                this._handlers = [];
            }.bindenv(this));
        }
    }

    /**
     * Resolve promise with a value
     */
    function _resolve(value = null) {
        if (this.STATE_PENDING == this._state) {
            // If promise is resolved with another promise let it resolve/reject
            // this one, otherwise resolve immediately
            if (this._isPromise(value)) {
                value.then(
                    this._resolve.bindenv(this),
                    this._reject.bindenv(this)
                );
            } else {
                this._state = this.STATE_FULFILLED;
                this._value = value;
                this._callHandlers();
            }
        }
    }

    /**
     * Reject promise for a reason
     */
    function _reject(reason = null) {
        if (this.STATE_PENDING == this._state) {
            this._state = this.STATE_REJECTED;
            this._value = reason;
            this._callHandlers();
        }
    }

   /**
    * Check if a value is a Promise.
    * @param {Promise|*} value
    * @return {boolean}
    */
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

   /**
    * Add handlers on resolve/rejection
    * @param {function|null} onFulfilled
    * @param {function|null} onRejected
    * @return {this}
    */
    function then(onFulfilled = null, onRejected = null) {
        // If either handler is left null, set it to our default handlers
        onFulfilled = (typeof onFulfilled == "function") ? onFulfilled : Promise._onFulfilled;
        onRejected  = (typeof onRejected  == "function") ? onRejected  : Promise._onRejected;

        local self = this;
        local result = Promise(function(resolve, reject) {
            self._handlers.push({
                "resolve": resolve.bindenv(this),
                "onFulfilled": onFulfilled,
                "reject": reject.bindenv(this),
                "onRejected": onRejected
            })
        });

        this._callHandlers();

        return result;
    }

   /**
    * Add handler on rejection
    * @param {function} onRejected
    * @return {this}
    */
    function fail(onRejected) {
        return this.then(null, onRejected);
    }

   /**
    * Add handler that is executed both on resolve and rejection
    * @param {function(value)} handler
    * @return {this}
    */
    function finally(handler) {
        return this.then(handler, handler);
    }

    /**
     * The default `onFulfilled` handler (the identity function)
     */
    static function _onFulfilled(value) {
        return value;
    }

    /**
     * The default rejection handler, just throws to the next handler
     */
    static function _onRejected(reason) {
        throw reason;
    }

    /**
     * While loop with Promise's
     * Stops on continueCallback() == false or first rejection of looped Promise
     *
     * @param {function:boolean} condition - if returns false, loop stops
     * @param {function:Promise} next - function to get next promise in the loop
     * @return {Promise} Promise that is resolved/rejected with the last value that come from looped promise when loop finishes
     */
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

    /**
     * Returns Promise that resolves when
     * all promises in chain resolve:
     * one after each other
     *
     * @param {{Promise|function}[]} promises - array of Promises/functions that return Promises
     * @return {Promise} Promise that is resolved/rejected with the last value that come from looped promise
     */
    static function serial(promises) {
        local i = 0;
        return this.loop(
            @() i < promises.len(),
            function () {
                return "function" == type(promises[i])
                    ? promises[i++]()
                    : promises[i++];
            }
        )
    }

    /**
     * Returns Promise that resolves when all promises in the list resolve
     *
     * @param {{Promise}[]} promises - array of Promises (or functions that
     * return promises)
     * @param {boolean} wait - whether to wait for all promises to resolve, or
     * just the first
     * @return {Promise} Promise that is resolved with the list of values that
     * `promises` resolved to (in order) OR with the value of the first promise
     * that resolves (depending on `wait`)
     */
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
                    resolve(result)
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

    /**
     * Returns Promise that resolves to an array containing the results of each
     * given promise (or rejects with the first rejected)
     *
     * @param {{Promise}[]} promises - array of Promises (or functions which
     * return promises)
     * @return {Promise} Promise that is resolved with the list of values that
     * `promises` resolved to (in order) or rejects with the reason of the first
     * of `promises` to reject
     */
    static function all(promises) {
        return this._parallel(promises, true);
    }

    /**
     * Returns Promise that resolves to the first value that any of the given
     * promises resolve to
     *
     * @param {{Promise}[]} promises - array of Promises (or functions which
     * return promises)
     * @return {Promise} Promise that is resolved with the to the value of the
     * first of `promises` to resolve (or rejects with the first to reject)
     */
    static function race(promises) {
        return this._parallel(promises, false);
    }

    /**
     * Returns promise that immediately resolves to the given value
     *
     * @param {*} value - value to resolve to
     * @return {Promise} - a Promise that immediately resolves to `value`
     */
    static function resolve(value) {
        return Promise(function(resolve, reject) {
            resolve(value);
        })
    }

    /**
     * Returns promise that immediately rejects with the given reason
     *
     * @param {*} value - value to resolve to
     * @return {Promise} - a Promise that immediately rejects with `reason`
     */
    static function reject(reason) {
        return Promise(function(resolve, reject) {
            reject(reason);
        })
    }
}
