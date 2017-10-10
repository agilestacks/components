#!/usr/bin/env groovy
@Grab(group='org.jenkins-ci.plugins', module='junit', version='1.21')
@Grab(group='org.jenkins-ci.plugins.workflow', module='workflow-support', version='2.14')
import org.jenkinsci.plugins.workflow.support.steps.build.RunWrapper
import hudson.tasks.test.AbstractTestResultAction

def call(RunWrapper currentBuild) {
    def testResultAction = currentBuild?.rawBuild?.getAction(AbstractTestResultAction.class)

    if (testResultAction != null) {
        def total = testResultAction.getTotalCount()
        def failed = testResultAction.getFailCount()
        def skipped = testResultAction.getSkipCount()
        def passed = total - failed - skipped

       return "Passed: ${passed}, Failed: ${failed}, Skipped ${skipped}"
    }
    return "No tests found"
}
