# Promise 4.0.1 #

This library provides an implementation of promises for Electric Imp Squirrel.

According to Wikipedia: “Futures and promises originated in functional programming and related paradigms (such as logic programming) to decouple a value (a future) from how it was computed (a promise), allowing the computation to be done more flexibly, notably by parallelizing it”.

For more information on the concept of promises, please see the following references for JavaScript:

- [Promises/A+](https://promisesaplus.com/)
- [JavaScript Promises: There and back again](http://www.html5rocks.com/en/tutorials/es6/promises/)
- [Promise - Javascript](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise)

The Promise library API extends that of the JavaScript implementation. It also introduces some new methods that don’t exist in the original JavaScript implementation, including:

- [*Promise.race()*](#raceseries)
- [*Promise.loop()*](#loopcontinuefunction-nextfunction)
- [*Promise.serial()*](#serialseries)

**To include this library in your project, add** `#require "Promise.lib.nut:4.0.1"` **to the top of your agent and/or device code.**

![Build Status](https://cse-ci.electricimp.com/app/rest/builds/buildType:(id:Promise_BuildAndTest)/statusIcon)

## Class Usage ##

### Constructor: Promise(*actionFunction*) ###

The constructor should receive a single function which will be executed to determine the final value and result of the promise. This function has two parameters of its own, *resolve* and *reject*, both of which are themselves functions that have a single parameter: respectively, *value* (the value of the resolved promise) and *reason* (the reason for the promise’s rejection).

Exactly one of these functions should be executed at the completion of the *actionFunction*:

- Calling *resolve()* accepts the promise and calls any *onFulfilled* callbacks registered with [*then()*](#thenonfulfilled-onrejected).
- Calling *reject()* rejects the promise and calls any callback registered with [*fail()*](#failonrejected) and *onRejected* callback registered with [*then()*](#thenonfulfilled-onrejected).

#### Example ####

```squirrel
#require "Promise.lib.nut:4.0.1"

myPromise <- Promise(myActionFunction);
```

**Note** The action function is executed when the promise is instantiated. It is not delayed in time.

## Instance Methods ##

### then(*[onFulfilled, onRejected]*) ###

This method allows you to specify callbacks which will be executed when, respectively, the promise is resolved or rejected. Default callbacks will be used if you provide none of your own.

Because calls to *then()* return promises, you can chain sequences of *then()* calls, each with their own callbacks which are triggered according to the output of earlier functions in the chain. Please see the [Chained State Handling example](#chained-state-handling), below, for further guidance on using this powerful feature.

#### Parameters ####

| Parameter | Type | Required? | Description |
| --- | --- | --- | --- |
| *onFulfilled* | Function | No | Called when the promise is resolved. It has one parameter of its own: *value*, which receives the promise value |
| *onRejected* | Function | No | Called when the promise is rejected. It has one parameter of its own: *reason*, which receives a message indicating the reason for the rejection |

The promise instance that *then()* is called on may already have been resolved or rejected. In this case the *onFulfilled* or *onRejected* callback will be executed immediately.

**Note** If you only intend to provide an *onRejected* function, you must pass `null` into the first parameter and the *onRejected* function into the second parameter, or use [*fail()*](#failonrejected) instead.

#### Return Value ####

Promise &mdash; A promise object.

#### Examples ####

##### Basic State Handling #####

```squirrel
myPromise.then(function(value) {
    server.log("myPromise was resolved with value: " + value);
}, function(reason) {
    server.log("myPromise was rejected for reason: " + reason);
});
```

##### Chained State Handling #####

Because calls to *then()* return promises, any registered callback function (ie. either *onFulfilled* or *onRejected*) which returns a value will therefore pass this value on to the next *onFulfilled* callback in the chain, if there is one. Similarly, any exceptions throw by the first *onRejected* handler will be passed on to the next available *onRejected* callback. In this way errors can be caught and handled or thrown again, much as with Squirrel’s `try` and `catch`. The following example is for demonstration only and is overly verbose.

```squirrel
// 'name' is a variable that should contain a string, but may not

Promise.resolve(name)
        // First 'then' in the chain
        .then(
            // Set the 'onFulfilled' handler
            function(name) {
                if (typeof name != "string") {
                    throw "Invalid name";
                } else {
                    // 'name' is valid, so just pass it through
                    return name;
                }
            },
            // No 'onRejected' handler
            null)
        // Second 'then' in the chain
        .then(
            // THere is now no 'onFulfilled' handler
            null,
            // Set the 'onRejected' handler
            function(reason) {
                // I run with reason == "invalid name"
                // So handle invalid name by providing a default
                return "Bob";
            })
        // Third 'then' in the chain
        .then(
            // Set the 'onFulfilled' handler
            function(name) {
                // I have a valid name
                server.log("Name: " + name);
            },
            // No 'onRejected' handler
            null);
```

Passing `null` as a handler causes the use of the default behavior, ie. pass any values through to the next available *onFulfilled* callback, or throw exceptions on to the next available *onRejected* callback.

If no *onFulfilled* callbacks are registered, then the last value returned will be ignored. Similarly, if no *onRejected* callbacks are registered, any exceptions that occur within a promise executor or callback function will **not** be caught and will be ignored. An `"Unhandled promise rejection"` warning is generated by the library in this case.

It is prudent always to add the following line at the end of your promise chains:

```squirrel
.fail(server.error.bindenv(server));
```

### fail(*onRejected*) ###

This method allows you to register a callback which will be executed the promise is rejected. It is equivalent to calling `then(null, onRejected)`.

#### Parameters #// Copyright 2021 Twilio
// Copyright 2016-19 Electric Imps you to provide a handler which will be called when the promise is either resolved or rejected, ie. when the promise is *settled*. It is equivalent to `then(onResolvedOrRejected, onResolvedOrRejected)`.

#### Parameters ####

| Parameter | Type | Required? | Description |
| --- | --- | --- | --- |
| *onResolvedOrRejected* | Function | Yes | Called when the promise is resolved or rejected. It has one parameter of its own: *valueOrReason*, which receives a message indicating the reason for the rejection, or the value of the resolved promise, whichever has taken place |

**Note** There is no implicit indication when *onResolvedOrRejected* is called as to whether the promise was resolved or rejected, but you may code your value or rejection reason to allow your *onResolvedOrRejected* code to determine which of these two possible events occurred.

#### Return Value ####

Promise &mdash; A promise object.

#### Example ####

```squirrel
myPromise.finally(function(valueOrReason) {
    server.log("myPromise resolved or rejected with value or reason: " + valueOrReason);
});
```

## Class Methods ##

### resolve(*value*) ###

This method returns a promise that immediately resolves to a given value.

#### Parameters ####

| Parameter | Type | Required? | Description |
| --- | --- | --- | --- |
| *value* | Any | Yes | The promise’s forced resolution value |

#### Return Value ####

Promise &mdash; A promise object.

#### Example ####

```squirrel
Promise.resolve(value)
       .then(function(value) {
           // Operate on value
       });
```

### reject(*reason*) ###

This method returns a promise that is immediately rejected with a given reason.

#### Parameters ####

| Parameter | Type | Required? | Description |
| --- | --- | --- | --- |
| *reason* | Any | Yes | The promise’s forced rejection reason |

#### Return Value ####

Promise &mdash; A promise object.

#### Example ####

```squirrel
Promise.reject(reason)
       .fail(function(reason) {
           // Operate on reason
       });
```

### all(*series*) ###

This method executes promises in parallel and resolves them when they are all done.

#### Parameters ####

| Parameter | Type | Required? | Description |
| --- | --- | --- | --- |
| *series* | Array of promises and/or<br />functions that return promises | Yes | The promises to be executed together |

#### Return Value ####

Promise &mdash; A promise that resolves to an array of the resolved promise values, or rejects with first rejected promise’s value.

#### Example ####

In the following code, *promises* resolves with value `[1, 2, 3]` in 1.5 seconds:

```squirrel
local series = [
    Promise(function(resolve, reject) {
        imp.wakeup(1.0, function() { resolve(1); });
    }),
    Promise(function(resolve, reject) {
        imp.wakeup(1.5, function() { resolve(2); });
    }),
    Promise(function(resolve, reject) {
        imp.wakeup(0.5, function() { resolve(3); });
    })
];

local promises = Promise.all(series);
promises.then(function(values) {
    // values == [1, 2, 3]
    foreach (a in values) {
        server.log(a);
    }
});
```

### race(*series*) ###

This method executes promises in parallel and resolves them all when the first promise is resolved.

#### Parameters ####

| Parameter | Type | Required? | Description |
| --- | --- | --- | --- |
| *series* | Array of promises and/or<br />functions that return promises | Yes | The promises to be executed together |

**Note** Execution of the promises is started immediately at the moment of declaration but execution of each function that returns a promise is started at the moment of the *race()* method call. Do not mix promises and functions in one *race()* call.

#### Return Value ####

Promise &mdash; A promise that resolves with the first resolved promise’s value, or is rejected with the first rejected promise’s reason.

#### Example ####

In the following code, *promises* rejects in 0.5 second with the value `"3"`:

```squirrel
local series = [
    // Rejects first as the other one with 1s timeout starts later from inside .race()
    Promise(function(resolve, reject) {
        imp.wakeup(1, function() { reject(1); });
    }),
    function() {
        return Promise(function(resolve, reject) {
            imp.wakeup(1.5, function() { resolve(2); });
        });
    },
    function() {
        return Promise(function(resolve, reject) {
            imp.wakeup(0.5, function() { reject(3); });
        });
    }
];

local promises = Promise.race(series);
promises.then(function(value) {
    // Not run
}, function(reason) {
    // reason == 1
});
```

### loop(*continueFunction, nextFunction*) ###

This method provides a way to perform `while` loops with asynchronous processes. It makes use of two control functions, *continueFunction* and *nextFunction*. The first controls the flow of the loop; the second provides the next promise to be used in the loop.

The loop stops when *continueFunction* returns `false` or upon the first rejection of a looped promise.

#### Parameters ####

| Parameter | Type | Required? | Description |
| --- | --- | --- | --- |
| *continueFunction* | Function | Yes | Returns `true` to continue the loop, or `false` to stop it |
| *nextFunction* | Function | Yes | Returns the next promise in the loop |

#### Return Value ####

Promise &mdash; A promise that is resolved or rejected with the last value that comes from the looped promise when the loop finishes.

#### Example ####

In the following code, *done* resolves in nine seconds with the value `"counter is 3"`.

```squirrel
local i = 0;
local done = Promise.loop(
                // The loop control function: a lambda that increments i
                // while i < 3, and returns false when i == 3
                @() i++ < 3,
                // The next promise provider function
                function() {
                    return Promise(function (resolve, reject) {
                        imp.wakeup(3, function() {
                            resolve("Counter is " + i);
                        });
                    });
                });
```

### serial(*series*) ###

This method returns a promise that resolves when all of the promises in the chain resolve or when the first one is rejected.

**Note** A promise’s action function is triggered at the moment when the promise is created. So using functions returning promises to pass into *serial()* makes instantiation sequential, ie. a promise is created and the action is triggered only when the previous promise in the series was resolved or rejected.

#### Parameters ####

| Parameter | Type | Required? | Description |
| --- | --- | --- | --- |
| *series* | Array of promises and/or<br />functions that return promises | Yes | The promises to be executed |

#### Return Value ####

Promise &mdash; A promise that resolves with the last resolved promise’s value, or is rejected with the first rejected promise’s reason.

#### Examples ####

In the following code, *p* resolves in 2.5 seconds with the value `3`. The second function’s argument is executed only when the first promise resolves and the second one is instantiated:

```squirrel
local series = [
    Promise(function(resolve, reject) {
        imp.wakeup(1, function() { resolve(1); });
    }),
    function() {
        return Promise(function(resolve, reject) {
            imp.wakeup(1.5, function() { resolve(2); });
        });
    },
    Promise(function(resolve, reject) {
        imp.wakeup(0.5, function() { resolve(3); });
    });
];

local p = Promise.serial(series);
```

In the following code, *p* resolves in 1.5 seconds with the value `3` as all the promises are instantiated at the same time:

```squirrel
local series = [
    Promise(function(resolve, reject) {
        imp.wakeup(1, function() { resolve(1); });
    }),
    Promise(function(resolve, reject) {
        imp.wakeup(1.5, function() { resolve(2); });
    }),
    Promise(function(resolve, reject) {
        imp.wakeup(0.5, function() { resolve(3); });
    })
];

local p = Promise.serial(series);
```

## Recommended Use ##

The execution of multiple promises is possible in two modes: *synchronous* (one by one) execution and *asynchronous* (parallel) execution. The library supports both modes.

### Synchronous (One By One) Execution ###

There are three methods that you can use to execute multiple promises sequentially:

* [*then()*](#thenonfulfilled-onrejected)
   A chain of [*then()*)](#thenonfulfilled-onrejected)-registered callbacks is a classic way to ensure serial execution. Each action passes the result of execution to the next action. If the current promise in the chain has been rejected, execution stops and any [*fail()*](#failonrejected)-registered callback is triggered.

   This method is useful when you need to pass data from one step to the next. For example, a smart weather station needs to read temperature data from sensor and send it to the agent:

   ```squirrel
    const MAX = 100;

    function initSensor() {
        return Promise(function(resolve, reject) {
            local deviceId = math.rand() % MAX;
            resolve(deviceId);
        });
    }

    // Generate some random float value as temperature
    function readData(sensor) {
        local temp = math.rand() % MAX + 0.1;
        return temp;
    }

    initSensor()
        .then(function(sensorId) {
            return readData(sensorId);
        })
        .then(function(temp) {
            agent.send("temp", temp);
        })
        .fail(function(err) {
            server.log("Unexpected error: " + err);
        });
   ```

   Complete example code can be found [here](./examples/example-then.device.nut)

* [*serial(series)*](#serialseries)
   This approach executes actions in the listed order (is *series*) exactly, but without passing the result from one step to the next. It returns a promise, so when the whole chain of actions has been executed, the result of the last action is passed to any [*then()*](#thenonfulfilled-onrejected)-registered callback. If any of the actions have failed, any [*fail()*](#failonrejected)-registered callback is executed.

   For example, the following code checks for firmware updates. Check, download and install functions are executed one after another, if the previous function completed successfully. The install function returns the version of the installed software update (eg. 0.57) so, hen all steps are complete, the [*then()*](#thenonfulfilled-onrejected) callback is triggered to print out the version.

    ```squirrel
    function checkUpdates () {
        return Promise(function (resolve, reject) {
            // Some asynchronous update check operations here
            resolve(true);
        });
    }

    function download () {
        // Some download operations here; return promise
        return Promise.resolve(true);
    }

    function install () {
        // Some installation operations here; return promise
        return Promise.resolve(version);
    }

    // Set 'series' as an array of the above functions
    local series = [checkUpdates, download, install];

    Promise.serial(series)
           .then(function(version) {
               server.log("Installed version: " + version); // Installed version: 0.57
           })
           .fail(function(err) {
               server.log("Error: " + err);
           });
    ```

    Complete example code can be found [here](./examples/example-serial.agent.nut)

* [*loop(counterFunction, callback)*](#loopcontinuefunction-nextfunction)
   This method executes *callback*, which returns Promise, in a loop, while *counterFunction* returns `true`. When the loop ends, it returns the result of last executed Promise.

   For example, you can use *loop()* to check a building’s door sensors one by one to be sure that all the doors are closed. The *checkDoorById()* function checks the sensor by ID and returns a promise. If a promise is rejected, the loop ends and the [*fail()*](#failonrejected)-registered callback is triggered.

    ```squirrel
    function checkDoorById (id) {
        return Promise(function (resolve, reject) {
            // Some asynchronous operations here
            resolve(true);
        });
    }

    local i = 1;
    Promise.loop(
        @() i++ < 6,
        function () {
            return checkDoorById(i);
        })
        .then(function(x) {
            server.log("All doors are closed");
        })
        .fail(function(err) {
            server.log("Unlocked door detected");
        });
    ```

    Complete example code can be found [here](./examples/example-loop.nut)

### Asynchronous (Parallel) Execution ###

There are two methods to execute multiple promises in parallel:

* [*all(series)*](#allseries)
   This method executes promises in parallel and resolves them when they are all done. It returns a promise that resolves to an array of the resolved promise values, or rejects with first rejected promise’s value.

   For example, a smart weather station application has multiple sensors. The following code reads and sends metrics from all of them. The [*all()*](#allseries) call returns a promise that is resolved only when all the measurements have been collected.

    ```squirrel
    function getTemperature () {
        return Promise(function (resolve, reject) {
            // Some operations here
            resolve(/***/);
        });
    }

    function getBarometer () {
        return Promise(function (resolve, reject) {
            // Some operations here
            resolve(/***/);
        });
    }

    function getHumidity () {
        return Promise(function (resolve, reject) {
            // Some operations here
            resolve(/***/);
        });
    }

    Promise.all([getTemperature, getBarometer, getHumidity])
           .then(function(metrics) {
               agent.send("weather metrics", metrics);
            });
    ```

    Complete example code can be found [here](./examples/example-all.nut)

* [*race(series)*](#raceseries)
   This method executes multiple promises in parallel and resolves when the first one is done. It returns a promise that resolves with the first resolved promise’s value, or is rejected with the first rejected promise’s reason.

   For example, you have written a parking assistance application for three different carparks. Each carpark has its own API with different methods to find a free parking bay. You can call three different methods in parallel using [*race()*](#raceseries). As soon as any method finds a place, the [*then()*](#thenonfulfilled-onrejected)-registered callback will be triggered.

    ```squirrel
    function checkParkingA () {
        return Promise(function (resolve, reject) {
            // Some asynchronous API calls here
            resolve(place);
        });
    }

    function checkParkingB () {
        return Promise(function (resolve, reject) {
            // Some asynchronous API calls here
            resolve(place);
        });
    }

    function checkParkingC () {
        return Promise(function (resolve, reject) {
            // Some asynchronous API calls here
            resolve(place);
        });
    }

    Promise.race([checkParkingA, checkParkingB, checkParkingC])
           .then(function(place) {
                server.log("Found a free parking bay: " + place); // Found place: B11
            })
           .fail(function(err) {
                server.log("Sorry, all parking bays are full");
            });
    ```

    Complete example code can be found [here](./examples/example-race.nut)

## Further Examples ##

- [Example A](./examples/example-a.nut)
- [Example B](./examples/example-b.nut)

## Testing ##

The library repository contains [*impt*](https://github.com/electricimp/imp-central-impt) tests. Please refer to the [imp test](https://github.com/electricimp/imp-central-impt/blob/master/TestingGuide.md) documentation for more details.

The tests can be run on any imp.

## License ##

This library is licensed under the [MIT License](https://github.com/electricimp/Promise/blob/master/LICENSE).
