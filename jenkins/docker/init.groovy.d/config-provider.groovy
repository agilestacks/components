#!groovy

import org.jenkinsci.plugins.configfiles.*
import org.jenkinsci.plugins.configfiles.xml.*
import org.jenkinsci.plugins.configfiles.json.*
import org.jenkinsci.plugins.configfiles.groovy.*
import org.jenkinsci.plugins.configfiles.custom.*
import groovy.io.FileType

def store = GlobalConfigFiles.get()

def configDir = System.getenv('CONFIG_DIR') ?: '/usr/share/jenkins/ref/conf.d'

def dir = new File(configDir)
dir.eachFileRecurse (FileType.FILES) { file ->
  def ext = (file.name =~ /.[a-z]*/)[-1]

  def config
  if (ext == '.xml') {
    config = new XmlConfig(file.name, file.name, "Imported from ${configDir}", file.text)
  } else if (ext == '.json' || ext == 'js') {
    config = new JsonConfig(file.name, file.name, "Imported from ${configDir}", file.text)
  } else if (ext == '.groovy') {
    config = new GroovyScript(file.name, file.name, "Imported from ${configDir}", file.text)
  } else {
    config = new CustomConfig(file.name, file.name, "Imported from ${configDir}", file.text)
  }
  store.save( config )
}
