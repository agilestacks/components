#!/usr/bin/env groovy

def call() {
  node('master') {
    sh(script: 'git rev-parse HEAD', returnStdout: true).take(7)
  }
}
