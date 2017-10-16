<?xml version='1.0' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@2.13">
  <actions>
    <io.jenkins.blueocean.service.embedded.BlueOceanUrlAction plugin="blueocean-rest-impl@1.2.0">
      <blueOceanUrlObject class="io.jenkins.blueocean.service.embedded.BlueOceanUrlObjectImpl">
        <mappedUrl>blue/organizations/jenkins/nodejs</mappedUrl>
      </blueOceanUrlObject>
    </io.jenkins.blueocean.service.embedded.BlueOceanUrlAction>
    <org.jenkinsci.plugins.workflow.multibranch.JobPropertyTrackerAction plugin="workflow-multibranch@2.16">
      <jobPropertyDescriptors>
        <string>hudson.model.ParametersDefinitionProperty</string>
        <string>org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty</string>
      </jobPropertyDescriptors>
    </org.jenkinsci.plugins.workflow.multibranch.JobPropertyTrackerAction>
  </actions>
  <description>nodejs - demo Agile Stacks</description>
  <displayName>nodejs - demo Agile Stacks</displayName>
  <keepDependencies>false</keepDependencies>
  <properties>
    <com.coravy.hudson.plugins.github.GithubProjectProperty plugin="github@1.28.0">
      <projectUrl>https://github.com/agilestacks/agile-demo/</projectUrl>
      <displayName></displayName>
    </com.coravy.hudson.plugins.github.GithubProjectProperty>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers/>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@2.39">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@3.5.1">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>https://github.com/agilestacks/agile-demo.git</url>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/master</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="list"/>
      <extensions/>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>