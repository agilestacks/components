import org.jenkinsci.plugins.scriptsecurity.scripts.ScriptApproval
import groovy.io.FileType

def approvalDir = System.getenv('SCRIPT_APPROVAL_DIR') ?: '/usr/share/jenkins/ref/approval.d'

def f = ScriptApproval.class.getDeclaredField('approvedSignatures')
f.setAccessible(true)

def instance = ScriptApproval.get()
def approvedSignatures = f.get(instance)
def dir = new File(approvalDir)
dir.eachFileRecurse(FileType.FILES) { file ->
  file.eachLine { line ->
    approvedSignatures.add(line)
  }
}
instance.save()

f.setAccessible(false)

