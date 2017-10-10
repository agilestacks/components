#!/usr/bin/env groovy

def call() {
  node('master') {
    sh script: 'git rev-parse HEAD > commit'
    readFile('commit').trim().substring(0, 7)
  }
}


