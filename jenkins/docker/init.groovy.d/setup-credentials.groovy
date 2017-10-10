import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import com.cloudbees.jenkins.plugins.sshcredentials.impl.*
import org.csanchez.jenkins.plugins.kubernetes.*
import hudson.plugins.sshslaves.*
import java.nio.file.*
import com.cloudbees.jenkins.plugins.awscredentials.*

import hudson.model.ItemGroup
import com.amazonaws.util.EC2MetadataUtils;

def createSshCreds(user, pemFile) {
  println "Creating SSH creds for user: $user and private key: $pemFile"
  new BasicSSHUserPrivateKey(
    CredentialsScope.GLOBAL,
    "$user-private-key",
    user,
    new BasicSSHUserPrivateKey.FileOnMasterPrivateKeySource(pemFile),
    "",
    "SSH private key for user $user"
  )
}

domain = Domain.global()
store = Jenkins.instance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()

def dir = new File( System.getenv("JENKINS_SECRETS_HOME") )
dir.eachFileMatch(~/.*.pem/) {
  def user = it.name.substring(0,it.name.lastIndexOf("."))
  def pemFile = it.path
  def privateKey = createSshCreds(user, pemFile)
  store.addCredentials(domain, privateKey)
}


// aws = new AWSCredentialsImpl(
//   CredentialsScope.GLOBAL,
//   "ecr:default",
//   "",                                             // accessKey
//   "",                                             // secretKey
//   "Empty AWS credentials for ECR authorization",  // description
//   "",                                             // iamRoleArn
//   ""                                              // iamMfaSerialNumber
// )

// def currentRegion = Regions.values().find {
//   it.name == EC2MetadataUtils.getEC2InstanceRegion()
// }

// def aws = new AmazonECSRegistryCredential(
//   CredentialsScope.GLOBAL,
//   "default",
//   currentRegion,
//   "ECR credentials for ${Regions.getCurrentRegion()}".toString(),
//   (ItemGroup<?>)store.getContext()
// )

// store.addCredentials(domain, aws)

// pk = new BasicSSHUserPrivateKey(
//   CredentialsScope.GLOBAL,
//   "jenkins-slave-key",
//   "slave",
//   new BasicSSHUserPrivateKey.UsersPrivateKeySource(),
//   "",
//   ""
// )
// store.addCredentials(domain, pk)


// userPass = new UsernamePasswordCredentialsImpl(
//   CredentialsScope.GLOBAL,
//   "jenkins-slave-password", "Jenkis Slave with Password Configuration",
//   "root",
//   "jenkins"
// )
// store.addCredentials(domain, userPass)
