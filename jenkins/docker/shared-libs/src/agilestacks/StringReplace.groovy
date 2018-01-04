#!/usr/bin/env groovy
package agilestacks

import java.util.logging.Logger

class StringReplace implements Serializable {

    final CURLY = /\$\{([\w\.\-\_]+)\}/
    final MUSTACHE = /\{\{([\w\.\-\_]+)\}\}/
    final log = Logger.getLogger(this.class.name)

    def render(text, params=[:], pattern=CURLY) {
        text.replaceAll(pattern) { m, i ->
            if (m.class in Collection || m.class.array) {
                return params[ m[1] ] ?: m[0]
            }
            return params[i] ?: m
        }
    }

    def curly(text, params=[:]) {
        render(text, params, CURLY)
    }

    def mustache(text, params=[:]) {
        render(text, params, MUSTACHE)
    }
}
