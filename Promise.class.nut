/**
 * Promises for Electric Imp/Squirrel
 *
 * @author Aron Steg <aron@electricimp.com>
 * @author Mikhail Yurasov <mikhail@electricimp.com>
 *
 * @version 2.0.0
 */
class Promise {
    static version = [2, 0, 0];

    static STATE_PENDING = 0;
    static STATE_RESOLVED = 1;
    static STATE_REJECTED = 2;
    static STATE_CANCELLED = 3;

    _state = null;
    _value = null;

    /* @var {{resole, reject}[]} _handlers */
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
            foreach (handler in this._handlers) {
                (/* create closure and bind handler to it */ function (handler) {
                    if (this._state == this.STATE_RESOLVED) {
                        if ("resolve" in handler && "function" == type(handler.resolve)) {
                            imp.wakeup(0, function() {
                                handler.resolve(this._value);
                            }.bindenv(this));
                        }
                    } else if (this._state == this.STATE_REJECTED) {
                        if ("reject" in handler && "function" == type(handler.reject)) {
                            imp.wakeup(0, function() {
                                handler.reject(this._value);
                            }.bindenv(this));
                        }
                    } else if (this._state == this.STATE_CANCELLED) {
                        if ("cancel" in handler && "function" == type(handler.cancel)) {
                            imp.wakeup(0, function() {
                                handler.cancel(this._value);
                            }.bindenv(this));
                        }
                    }
                })(handler);
            }

            this._handlers = [];
        }
    }

    /**
     * Resolve promise with a value
     */
    function _resolve(value = null) {
        if (this.STATE_PENDING == this._state) {
            // if promise is resolved with another promise
            // let it resolve/reject this one,
            // otherwise resolve immideately
            if (this._isPromise(value)) {
                value.then(
                    this._resolve.bindenv(this),
                    this._reject.bindenv(this)
                );
            } else {
                this._state = this.STATE_RESOLVED;
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
    * @param {function} onResolve
    * @param {function|null} onReject
    * @return {this}
    */
    function then(onResolve, onReject = null) {
        this._handlers.push({
            "resolve": onResolve
        });

        if (onReject) {
            this._handlers.push({
                "reject": onReject
            });
        }

        this._callHandlers();
        return this;
    }

   /**
    * Add handler on rejection
    * @param {function} onReject
    * @return {this}
    */
    function fail(onReject) {
        this._handlers.push({
            "reject": onReject
        });

        this._callHandlers();
        return this;
    }

   /**
    * Add handler that is executed both on resolve and rejection
    * @param {function(value)} handler
    * @return {this}
    */
    function finally(handler) {
        this._handlers.push({
            "resolve": handler,
            "reject": handler
        });

        this._callHandlers();
        return this;
    }

   /**
    * Add handlers on cancellation
    * @param {function()} onCancel
    * @return {this}
    */
    function cancelled(onCancel) {
      this._handlers.push({
        "cancel": onCancel
      });

      this._callHandlers();
      return this;
    }

    /**
     * Cancel a promise
     * - No .then/.fail/.finally handlers will be called
     * - .cancelled handler will be called
     * @param {*} reason - value that will be passed to .cancelled handler
     */
    function cancel(reason = null) {
        if (this.STATE_PENDING == this._state) {
            this._state = this.STATE_CANCELLED;
            this._value = reason;
            this._callHandlers();
        }
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
        return (this)(function (resolve, reject) {

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
     * Execute Promises in parallel.
     *
     * @param {{Primise|functiuon}[]} promises
     * @param {wait} wait - wait for all promises to finish?
     * @returns {Promise}
     */
    static function _parallel(promises, wait) {
        return (this)(function (resolve, reject) {
            local resolved = 0;

            local checkDone = function(v = null) {
                if ((!wait && resolved == 1) || (wait && resolved == promises.len())) {
                    resolve(v);
                    return true;
                }
            }

            if (!checkDone()) {
                for (local i = 0; i < promises.len(); i++) {
                    (
                        "function" == type(promises[i])
                            ? promises[i]()
                            : promises[i]
                    )
                    .then(function (v) {
                        resolved++;
                        checkDone(v);
                    }, reject);
                }
            }

        }.bindenv(this));
    }

    /**
     * Execute Promises in parallel and resolve when they are all done.
     * Returns Promise that resolves with last paralleled Promise value
     * or rejects with first rejected paralleled Promise value.
     *
     * @param {{Primise|functiuon}[]} promises
     * @returns {Promise}
     */
    static function parallel(promises) {
        return this._parallel(promises, true);
    }

    /**
     * Execute Promises in parallel and resolve when the first is done.
     * Returns Promise that resolves/rejects with the first
     * resolved/rejected Promise value.
     *
     * @param {{Primise|functiuon}[]} promises
     * @returns {Promise}
     */
    static function first(promises) {
        return this._parallel(promises, false);
    }
}
