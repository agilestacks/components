import jenkins.*
import jenkins.model.*
import hudson.*
import hudson.model.*

def instance = Jenkins.instance
println("Changing root workspace directory settings")

f = Jenkins.class.getDeclaredField("workspaceDir");
f.setAccessible(true)
f.set(instance, '${JENKINS_HOME}/workspace/${ITEM_FULLNAME}')
instance.save()
