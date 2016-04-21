<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


- [Promise 2.0.0](#promise-200)
  - [Usage](#usage)
    - [Promise()](#promise)
    - [.then()](#then)
    - [.fail()](#fail)
    - [.finally()](#finally)
    - [.always()](#always)
    - [.cancelled()](#cancelled)
    - [.cancel()](#cancel)
      - [Cancellation vs. Rejection](#cancellation-vs-rejection)
    - [Promise.loop()](#promiseloop)
    - [Promise.serial()](#promiseserial)
    - [Promise.parallel()](#promiseparallel)
    - [Promise.first()](#promisefirst)
  - [Example](#example)
  - [Testing](#testing)
    - [TL;DR](#tldr)
    - [Running Tests](#running-tests)
  - [Development](#development)
- [License](#license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

<br />

[![Build Status](https://travis-ci.org/electricimp/Promise.svg?branch=master)](https://travis-ci.org/electricimp/Promise)

# Promise 2.0.0

Implementation of _Promises_ for Electric Imp/Squirrel.

_According to Wikipedia, "Futures and promises originated in functional programming and
related paradigms (such as logic programming) to decouple a value (a future) from how
it was computed (a promise), allowing the computation to be done more flexibly, notably
by parallelizing it."_

## Usage

### Promise()

`Promise(action)`

The constructor should receive an _action function_, which will be executed to determine the final value and result.
This function provides two parameters: 

- `function resolve([value])` – calling `resolve` sets Promise state as resolved and calls success handlers (passed as first argument of `.then()`)
- `function reject([reason]` - calling  `reject` sets Promise state as rejected and calls `.fail()` handlers
 
### .then()

`.then(onResolve [,onReject])`

Add handlers on resolve/rejection.

### .fail()

`.fail(onReject)`

Adds handler for rejection.

### .finally()

`.finally(handler)`

Adds handler that is executed both on resolve and rejection.

### .always()

`.always(handler)`

Adds handler that is executed on resolve/rejection/cancellation.

### .cancelled()

`.cancelled(onCancell)`

Add handler on cancellation.

### .cancel()

`.cancel(reason)`

Cancels a Promise. 

- No `.then`/`.fail`/`.finally` handlers will be called
- `.cancelled` handler will be called

Example:

Cancel some process after 10s:

```squirrel
local p = Promise(function (resolve, reject) {
    someProcess.on("done", resolve);
    someProcess.start();
    this.cancelled(function (reason) {
        someProcess.stop();
    });
});

p
    .then(function (value) {
        // ok handler
    })
    .fail(function (reason) {
        // err handler
    });

imp.wakeup(10, function() { p.cancel("Timed out") });
```

#### Cancellation vs. Rejection

It is important to understand the difference beween the rejection and cancellation.
 
Rejection:

- Can not be _implicitly_ triggered from outside of _action function_
- Signifies a process that calculates the Promise values encountered a error
- Occurs on exception in the action function
- Executes rejection and `.finally` handlers

Cancellation:

- Can be triggered externally (from outside of _action function_)
- Signifies that the Promise value is no longer required
- Excutes only `.cancelled` handlers

### Promise.loop()

`Promise.loop(continueFunction, nextFunction)`

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

### Promise.serial()

`Promise.serial(series)`

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

### Promise.parallel()

`Promise.parallel(series)`

Execute Promises in parallel and resolve when they are all done.
Returns Promise that resolves with last paralleled Promise value or rejects with first rejected paralleled Promise value.

Parameters:
- `series` – array of _Promises_/functions that return promises.

For example in the following code `p` resolves with value "2" in 1.5 seconds:

```squirrel
local series = [
    @() Promise(@(resolve, reject) imp.wakeup(1, @() resolve(1))),
    @() Promise(@(resolve, reject) imp.wakeup(1.5, @() resolve(2))),
    Promise(@(resolve, reject) imp.wakeup(0.5, @() resolve(3)))
];

local p = Promise.parallel(series);
```

### Promise.first()

`Promise.first(series)`

Execute Promises in parallel and resolve when the first is done.
Returns Promise that resolves/rejects with the first resolved/rejected Promise value.

Parameters:
- `series` – array of _Promises_/functions that return promises.

For example in the following code `p` rejects with value "1" in 1 second:

```squirrel
local promises = [
    // rejects first as the other one with 1s timeout
    // starts later from inside .first()
    Promise(function (resolve, reject) { imp.wakeup(1, @() reject(1)) }),
    @() Promise(function (resolve, reject) { imp.wakeup(1.5, @() resolve(2)) }),
    @() Promise(function (resolve, reject) { imp.wakeup(1, @() reject(3)) }),
];

local p = Promise.parallel(series);
```

## Example

An example implementation of a promise is:

```squirrel
class Widget {

    function _longTask(data, callback) {
        // Some long asynchronous task which calls callback at the end
    }

    function calculate(input) {
        return Promise(function (fulfill, reject) {
            _longTask(input, function (err, res) {
                if (err) {
                    reject(err);
                } else {
                    fulfill(res);
                }
            }.bindenv(this));
        }.bindenv(this));
    }
}
```

An example execute of this class and promise is:

```squirrel
Widget().calculate(123)
        .then(
            function(res) {
                server.log("Success: " + res)
            }.bindenv(this)
        )
        .fail(
            function(err) {
                server.error("Failed: " + err)
            }.bindenv(this)
        )
        .finally(
            function(r) {
                server.log("I'm always called")
            }.bindenv(this)
        )
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


## Development

This repository uses [git-flow](http://jeffkreeftmeijer.com/2010/why-arent-you-using-git-flow/).
Please make your pull requests to the __develop__ branch.

# License

The Promise class is licensed under the [MIT License](./LICENSE.txt).
