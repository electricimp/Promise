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

#require "Promise.class.nut:3.0.0"

/**
 * Uses a chain of promises to call an API and make some transformations on the
 * data returned.
 *
 * Documentation for the API can be found at:
 *
 * https://repat.github.io/morsecode-api/
 *
 * The functionality of this class is as follows:
 *
 * - Take a message
 * - Use the API to get the morse-code for the given message
 * - Print the morse-code
 * - Use the API to translate the morse-code back to plain-text
 * - Convert the plain-text to lower-case
 * - Print the result
 *
 * The code demonstrates how to chain calls to `.then` and how to wrap a
 * traditional, callback style function in a promise.
 */
class MorseCode {
    static URL_TEMPLATE = "http://www.morsecode-api.de/%s/%s";

    _message = null;

    constructor(message) {
        _message = message;
    }

	/**
     * Demonstrate a chain of promises, with a mix of synchrony and asynchrony
     *
     * The way functionality is broken up between `.then` methods is flexible.
     * For example, the last three `.then`s contain only synchronous code and
     * could easily combined into one function with the following inner:
     *
     * server.log(http.jsondecode(response.body).plaintext.tolower());
     */
    function run(){
        Promise.resolve(_message)

            // Send the http request to morse-encode the message (asynchronous)
            .then(function(message) {
                local url = format(URL_TEMPLATE, "encode", urlencodes(message));
                return PromisedSendAsync(http.get(url));
            }.bindenv(this)) // bind to current env for URL_TEMPLATE and urlencodes

            // Pick the morse-code out of the httpresponse object, log it, and
            // pass it down the chain (all synchronous actions but, as always,
            // the block will execute asynchronously with an `imp.wakeup(0)`
            .then(function(response) {
                local morsecode = http.jsondecode(response.body).morsecode;
                server.log(morsecode);
                return morsecode;
            })

            // Construct the http request to decode the morse-encoded string
            .then(function(morsecode) {
                local url = format(URL_TEMPLATE, "decode", urlencodes(morsecode));
                return PromisedSendAsync(http.get(url));
            }.bindenv(this)) // bind to current env for URL_TEMPLATE and urlencodes


            // From the httpresponse object, pick out the plain text version of
            // the morse-code we sent
            .then(function(response) {
                return http.jsondecode(response.body).plaintext;
            })

            // Convert the plain text to all lower-case
            .then(function(message) {
                return message.tolower();
            })

            // Log the end result, an all lower-case string version of our
            // original message
            .then(server.log.bindenv(server))

            // Catch any errors that may fall through and log them as errors
            .fail(server.error.bindenv(server));
    }

    /**
     * Example of how to wrap an asyncronous function (or, in this case, method
     * call) in a promise
     * @param {request} - httprequest object, e.g. from an `http.get()` request
     * @return {Promise} - Resolves with a successful response object or rejects
     * with unsuccesful response object
     */
    static function PromisedSendAsync(request) {
        return Promise(function(resolve, reject) {
            
            request.sendasync(function(response) {
                if (response.statuscode < 200 || response.statuscode > 299) {
                    return reject(response);
                }
                return resolve(response); // Resolve promise on response
            }.bindenv(this));
            
        }.bindenv(this));
    }

    /**
     * Small helper function to urlencode a string
     * @return {string}
     */
    static function urlencodes(string) {
        // encode the table a table, with empty key, then slice of the "=" at the start
        return http.urlencode({"": string}).slice(1);
    }
}

// Run the code with the message "Hello World"
MorseCode("Hello World").run();

/*
 * Expect the output:
 *
 *     .... . .-.. .-.. --- ....... .-- --- .-. .-.. -..
 *     hello world
 *
 */
