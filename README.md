# Promise

Implementation of _Promises_ for Electric Imp/Squirrel.

_According to Wikipedia, "Futures and promises originated in functional programming and
related paradigms (such as logic programming) to decouple a value (a future) from how
it was computed (a promise), allowing the computation to be done more flexibly, notably
by parallelizing it."_

For more information on the concept of promises, see the following references
for Javascript:

- [Promises/A+](https://promisesaplus.com/)
- [Javascript Promises: There and back again](http://www.html5rocks.com/en/tutorials/es6/promises/)
- [Promise - Javascript](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise)

**To add this library to your project, add** `#require "promise.class.nut:3.0.0"` **to the top of your code.

[![Build Status](https://travis-ci.org/electricimp/Promise.svg?branch=master)](https://travis-ci.org/electricimp/Promise)

## Class Usage

### Constructor: Promise( *actionFunction(resolve, reject)* )

The constructor should receive a single function, which will be executed to determine the final value and result. The *actionFunction* requires two function parameters, *resolve* and *reject*.  Exactaly one of these functions should be executed at the completeing of the *actionFunction*.

- `function resolve([value])` – calling `resolve` sets Promise state as resolved and calls success handlers (passed as first argument of `.then()`)
- `function reject([reason]` - calling  `reject` sets Promise state as rejected and calls `.fail()` handlers

## Class Methods

### .then(*[onFulfilled, onRejected]*)

The *.then()* method allows the developer to provide an *onFulfilled* function and/or an *onRejected* function.  Default handlers will be used if no parameters are passed in.  **Note:** to pass in an *onRejected* function only, you must pass in `null` as the first parameter and the *onRejected* function as the second parameter.
This method returns a *Promise* to allow for method chaining.

```squirrel
myPromise
    .then(function(value) {
        server.log("myPromise resolved with value: " + value);
    }, function(reason) {
        server.log("myPromise rejected for reason: " + reason);
    });
```

Promises which reject with reasons will have their `onRejected` handlers called with that reason .  Promises which resolve with values will have their `onFulfilled` handler called with that value.  Calls to `.then` return promises, so a handler function (either `onFulfilled` or `onRejected) registered in `.then` which returns a value will pass this value on to the next `onFulfilled` handler in the chain, and any exceptions throw by a handler will be passed on to the next available 'onRejected' handler.  In this way errors can be "caught" and handled or thrown again, much like with `try` and `catch`.  The following example if for demonstration only and is overly verbose.

```squirrel
// name is a variable that _should_ contain a string, but may not

Promise.resolve(name)

    .then(function(name) {
        if (typeof name != "string") {
            throw "invalid name";
        } else {
            // name is valid, just pass it through
            return name;
        }
    }, null)

    .then(null, function(reason) {
        // I run with reason == "invalid name"
        return "Bob" // handle invalid name by providing a default
    })

    .then(function(name) {
        // I have a valid name
    });
```

Passing null as a handler corresponds to the default behaviour of passing any values through to the next available `onFulfilled` handler, or throwing exceptions throwing to the next available `onRejected` handler.

__NB__ that just as if no `onFulfilled` handlers are registered the last value returned will be ignored, if no `onRejected` handlers are registered any
exceptions that occur within a promise executor or handler function will __NOT__ be caught and will be silently ignored.  Thus it is prudent to always add the
following line at then end of your promise chains:

```squirrel
.fail(server.error.bindenv(server));
```

### .fail(*onRejected*)

The *.fail()* method allows the developer to provide an *onRejection* function.  Equivalent to `.then(null, onRejected)`.

```squirrel
myPromise
    .then(successHandler)
    .fail(function(reason) {
        server.log("myPromise rejected for reason OR successHandler through exception: " + reason);
    });
```

### .finally(*alwaysFunction*)

The *.finally()* method allows the developer to provide a function that is executed both on resolve and rejection (i.e. when the promise is *settled*).  Equivalent to `.then(alwaysFunction, alwaysFunction)`.  The *alwaysFunction* accepts one prameter - result or error.

```squirrel
myPromise
    .finally(function(valueOrReason) {
        server.log("myPromise resolved or rejected with value or reason: " +  valueOrReason);
    });
```

### Promise.resolve(*value*)

Returns Promise that immediately resolves to a given value.

```squirrel
Promise.resolve(value)
    .then(function(value) {
        // Operate on value
    });
```

### Promise.reject(*reason*)

Returns Promise that immediately rejects with a given reason.

```squirrel
Promise.reject(reason)
    .fail(function(reason) {
        // Operate on reason
    });
```

### Promise.all(*series*)

Execute Promises in parallel and resolve when they are all done.  Returns Promise that resolves with an array of the resolved Promise value or rejects
with first rejected paralleled Promise value.

Parameters:
- `series` – array of _Promises_/functions that return promises.

For example in the following code `p` resolves with value `[1, 2, 3]` in 1.5 seconds:

```squirrel
local series = [
    @() Promise(@(resolve, reject) imp.wakeup(1, @() resolve(1))),
    @() Promise(@(resolve, reject) imp.wakeup(1.5, @() resolve(2))),
    Promise(@(resolve, reject) imp.wakeup(0.5, @() resolve(3)))
];

local p = Promise.all(series);

p
    .then(function(values) {
        // values == [1, 2, 3]
    });
```

### Promise.race(*series*)

Execute Promises in parallel and resolve when the first is done. Returns Promise that resolves/rejects with the first resolved/rejected Promise value.

Parameters:
- `series` – array of _Promises_/functions that return promises.

For example in the following code `p` rejects with value "1" in 1 second:

```squirrel
local promises = [
    // rejects first as the other one with 1s timeout
    // starts later from inside .race()
    Promise(function (resolve, reject) { imp.wakeup(1, @() reject(1)) }),
    @() Promise(function (resolve, reject) { imp.wakeup(1.5, @() resolve(2)) }),
    @() Promise(function (resolve, reject) { imp.wakeup(1, @() reject(3)) }),
];

local p = Promise.race(series);

p
    .then(function(value) {
        // Not run
    }, function(reason) {
        // reason == 1
    });
```

### Promise.loop(*continueFunction, nextFunction*)

A way to perform while loops with asynchronous processes.

Parameters:
- `continueFunction` – function that returns `true` to continue loop or `false` to stop
- `nextFunction` – function that returns next _Promise_ in the loop

Stops on `continueFunction() == false` or first rejection of looped _Promise_'s.

Returns _Promise_ that is resolved/rejected with the last value that comes from looped _Promise_ when loop finishes.

For example in the following code `p` resolves with value "counter is 3" in 9 seconds.

```squirrel
local i = 0;
local p = Promise.loop(
    @() i++ < 3,
    function () {
        return Promise(function (resolve, reject) {
            imp.wakeup(3, function() {
                resolve("counter is " + i);
            });
        });
    }
);
```

### Promise.serial(*series*)

Returns _Promise_ that resolves when all promises in chain resolve or when the first one rejects.

Parameters:
- `series` – array of _Promises_/functions that return promises.

For example in the following code `p` rejects with value "2" in 2.5 seconds:

```squirrel
local series = [
    Promise(@(resolve, reject) imp.wakeup(1, @() resolve(1))),
    @() Promise(@(resolve, reject) imp.wakeup(1.5, @() reject(2))),
    Promise(@(resolve, reject) imp.wakeup(0.5, @() resolve(3)))
];

local p = Promise.serial(series);
```

## Testing

Repository contains [impUnit](https://github.com/electricimp/impUnit) tests and a configuration for [impTest](https://github.com/electricimp/impTest) tool.

### TL;DR

```bash
cp .imptest .imptest-local
nano .imptest-local # edit device/model
imptest test -c .imptest-local
```

### Running Tests

Tests can be launched with:

```bash
imptest test
```

By default configuration for the testing is read from [.imptest](https://github.com/electricimp/impTest/blob/develop/docs/imptest-spec.md).

To run test with your settings (for example while you are developing), create your copy of **.imptest** file and name it something like **.imptest.local**, then run tests with:

 ```bash
 imptest test -c .imptest.local
 ```

Tests will run with any imp.

## Examples

- [example a](./examples/example-a.nut)
- [example b](./examples/example-b.nut)
- [example c](./examples/example-c.nut)


# License

The Promise class is licensed under the [MIT License](./LICENSE.txt).
