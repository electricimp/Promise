
class Promise {

    static STATE_PENDING = 0;
    static STATE_RESOLVED = 1;
    static STATE_REJECTED = 2;

    _state = null;
    _value = null;

    /* @var {{resole, reject}[]} _handlers */
    _handlers = [];

    /**
    * @param {function(resolve, reject)} action - action function
    */
    constructor(action) {
        this._state = this.STATE_PENDING;

        try {
            action(
                this._resolve.bindenv(this)
                this._reject.bindenv(this)
            );
        } catch (e) {
            this._reject(e);
        }
    }

    function _handle() {
        // execute chain of handlers
        foreach (handler in this._handlers) {
            if (this._state == this.STATE_RESOLVED && "resolve" in handler) {
                imp.wakeup(0, function() { handler.resolve(this._value) }.bindenv(this));
            } else if (this._state == this.STATE_REJECTED && "reject" in handler) {
                imp.wakeup(0, function() { handler.reject(this._value) }.bindenv(this));
            }
        }

        this._handlers = [];
    }

    /**
     * Resolve promise with a value
     */
    function _resolve(value = null) {
        if (this.STATE_PENDING == this._state) {
            this._state = this.STATE_RESOLVED;
            this._value = value;
        }

        this._handle();
    }

    /**
     * Reject promise for a reason
     */
    function _reject(reason = null) {
        if (this.STATE_PENDING == this._state) {
            this._state = this.STATE_REJECTED;
            this._value = reason;
        }

        this._handle();
    }

    //

    function then(onResolve, onReject = null) {
        this._handlers.push({
            "resolve": onResolve
        })

        if (onReject) {
            this._handlers.push({
                "reject": onReject
            });
        }

        this._handle();

        return this;
    }

    function fail(onReject) {
        this._handlers.push({
            "reject": onReject
        });

        this._handle();

        return this;
    }

    function finally(always) {
        this._handlers.push({
            "resolve": always,
            "reject": always
        });

        this._handle();

        return this;
    }
}

/*local p = Promise(function(ok, err) {
    err(123);
});

p.then(function (value) {
    ::print(value + " // ok")
}, function (reason) {
    ::print(reason + " // err")
})*/
