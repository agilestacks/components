#!/usr/bin/env groovy

def call(template, bindings = [:]) {
    return new groovy.text.SimpleTemplateEngine()
        .createTemplate(template)
        .make(bindings)
        .toString()
}
