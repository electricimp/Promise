# Promise

The library provides an implementation of promises for Electric Imp/Squirrel.

According to Wikipedia: “Futures and promises originated in functional programming and related paradigms (such as logic programming) to decouple a value (a future) from how it was computed (a promise), allowing the computation to be done more flexibly, notably by parallelizing it.”

For more information on the concept of promises, see the following references for Javascript:

- [Promises/A+](https://promisesaplus.com/)
- [JavaScript Promises: There and back again](http://www.html5rocks.com/en/tutorials/es6/promises/)
- [Promise - Javascript](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise)

**To add this library to your project, add** `#require "Promise.class.nut:3.0.0"` **to the top of your agent and/or device code.**

[![Build Status](https://travis-ci.org/electricimp/Promise.svg?branch=master)](https://travis-ci.org/electricimp/Promise)

## Class Usage

### Constructor: Promise(*actionFunction*)

The constructor should receive a single function, which will be executed to determine the final value and result. The function passed into *actionFunction* requires two parameters of its own, *resolve* and *reject*, both of which are themselves function references. Exactly one of these functions should be executed at the completion of the *actionFunction*.

- `function resolve([value])` &mdash; calling *resolve()* sets Promise state as resolved and calls success handlers (passed as first argument of *.then()*)
- `function reject([reason])` &mdash; calling *reject()* sets Promise state as rejected and calls *.fail()* handlers

```squirrel
#require "Promise.class.nut:3.0.0"

myPromise <- Promise(myActionFunction);
```

## Instance Methods

### then(*[onFulfilled, onRejected]*)

The *then()* method allows the developer to provide an *onFulfilled* function and/or an *onRejected* function. Default handlers will be used if no parameters are passed in. **Note** to pass in an *onRejected* function only, you must pass in `null` as the first parameter and the *onRejected* function as the second parameter.

This method returns a *Promise* object to allow for method chaining.

```squirrel
myPromise
    .then(function(value) {
        server.log("myPromise resolved with value: " + value);
    }, function(reason) {
        server.log("myPromise rejected for reason: " + reason);
    });
```

Promises which reject with reasons will have their *onRejected* handlers called with that reason. Promises which resolve with values will have their *onFulfilled* handler called with that value. Calls to *then()* return promises, so a handler function (either *onFulfilled* or *onRejected*) registered in *then()* which returns a value will pass this value on to the next *onFulfilled* handler in the chain, and any exceptions throw by a handler will be passed on to the next available *onRejected* handler. In this way errors can be caught and handled or thrown again, much like with Squirrel’s `try` and `catch`. The following example is for demonstration only and is overly verbose.

```squirrel
// 'name' is a variable that *should* contain a string, but may not be

Promise.resolve(name)
    .then(function(name) {
        if (typeof name != "string") {
            throw "Invalid name";
        } else {
            // 'name' is valid, so just pass it through
            return name;
        }
    }, null)

    .then(null, function(reason) {
        // I run with reason == "invalid name"
        // So handle invalid name by providing a default
        return "Bob"; 
    })

    .then(function(name) {
        // I have a valid name
    });
```

Passing `null` as a handler corresponds to the default behaviour of passing any values through to the next available *onFulfilled* handler, or throwing exceptions throwing to the next available *onRejected* handler.

**Note** Just as if no *onFulfilled* handlers are registered the last value returned will be ignored, if no *onRejected* handlers are registered any exceptions that occur within a promise executor or handler function will **not** be caught and will be silently ignored. Thus it is prudent to always add the following line at the end of your promise chains:

```squirrel
.fail(server.error.bindenv(server));
```

### fail(*onRejected*)

The *fail()* method allows the developer to provide an *onRejection* function. This call is quivalent to `.then(null, onRejected)`.

```squirrel
myPromise
    .then(successHandler)
    .fail(function(reason) {
        server.log("myPromise rejected for reason OR successHandler through exception: " + reason);
    });
```

### finally(*alwaysFunction*)

The *finally()* method allows the developer to provide a function that is executed both on resolve and rejection (ie. when the promise is *settled*). This call is quivalent to `.then(alwaysFunction, alwaysFunction)`. The *alwaysFunction* accepts one prameter: result or error.

```squirrel
myPromise
    .finally(function(valueOrReason) {
        server.log("myPromise resolved or rejected with value or reason: " +  valueOrReason);
    });
```

## Class Methods

### Promise.resolve(*value*)

This method returns a promise that immediately resolves to a given value.

```squirrel
Promise.resolve(value)
    .then(function(value) {
        // Operate on value
    });
```

### Promise.reject(*reason*)

This method returns a promise that immediately rejects with a given reason.

```squirrel
Promise.reject(reason)
    .fail(function(reason) {
        // Operate on reason
    });
```

### Promise.all(*series*)

This method executes promises in parallel and resolves when they are all done. It Returns a promise that resolves with an array of the resolved promise value or rejects with first rejected paralleled promise value.

The parameter *series* is an array of promises and/or functions that return promises.

For example, in the following code *p* resolves with value `[1, 2, 3]` in 1.5 seconds:

```squirrel
local series = [
    @() Promise(@(resolve, reject) imp.wakeup(1, @() resolve(1))),
    @() Promise(@(resolve, reject) imp.wakeup(1.5, @() resolve(2))),
    Promise(@(resolve, reject) imp.wakeup(0.5, @() resolve(3)))
];

local p = Promise.all(series);
p.then(function(values) {
        // values == [1, 2, 3]
    });
```

### Promise.race(*series*)

This method executes promises in parallel and resolves when the first is done. It returns a promise that resolves or rejects with the first resolved/rejected promise value.

The parameter *series* is an array of promises and/or functions that return promises.

For example, in the following code *p* rejects with value `"1"` in 1 second:

```squirrel
local promises = [
    // rejects first as the other one with 1s timeout
    // starts later from inside .race()
    Promise(function (resolve, reject) { imp.wakeup(1, @() reject(1)) }),
    @() Promise(function (resolve, reject) { imp.wakeup(1.5, @() resolve(2)) }),
    @() Promise(function (resolve, reject) { imp.wakeup(1, @() reject(3)) }),
];

local p = Promise.race(promises);
p.then(function(value) {
        // Not run
    }, function(reason) {
        // reason == 1
    });
```

### Promise.loop(*continueFunction, nextFunction*)

This method provides a way to perform `while` loops with asynchronous processes. It takes the following parameters:

- *continueFunction* &mdash; a function that returns `true` to continue the loop or `false` to stop it
- *nextFunction* &mdash; a function that returns next promise in the loop

The loop stops on `continueFunction() == false` or first rejection of looped promises.

*loop()* returns a promise that is resolved/rejected with the last value that comes from the looped promise when the loop finishes.

For example, in the following code *p* resolves with value `"counter is 3"` in 9 seconds.

```squirrel
local i = 0;
local p = Promise.loop(
    @() i++ < 3,
    function () {
        return Promise(function (resolve, reject) {
            imp.wakeup(3, function() {
                resolve("Counter is " + i);
            });
        });
    });
```

### Promise.serial(*series*)

This method returns a promise that resolves when all the promises in the chain resolve or when the first one rejects.

The parameter *series* is an array of promises and/or functions that return promises.

For example, in the following code *p* rejects with value `"2"` in 2.5 seconds:

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


## License

The Promise class is licensed under the [MIT License](./LICENSE.txt).
