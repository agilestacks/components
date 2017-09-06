#!groovy
import jenkins.model.Jenkins
import ru.yandex.qatools.allure.jenkins.tools.*
import java.nio.file.Files
import java.nio.file.Path

def plugin=Jenkins.instance
                .getDescriptorByType(AllureCommandlineInstallation.DescriptorImpl.class)

def home = System.getenv("ALLURE_HOME")
if (home == null) {
  allureInPath = 'which allure'.execute().text
  if (!allureInPath.empty) {
    def allure = new File(allureInPath).toPath()
    if (Files.isSymbolicLink(allure)) {
      home = Files.readSymbolicLink(allure)?.parent?.parent?.toString()
    } else {
      home = allure?.parent?.parent?.toString()
    }
  } else {
    throw new RuntimeException('Cannot find allure CLI neither in ALLURE_HOME neither in PATH')
  }
}

def installation = new AllureCommandlineInstallation('default', home, [])
plugin.setInstallations( installation )
