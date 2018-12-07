# OpenJDK Image

Primary motivation for this Image is the Selenium slave for Jenkins. There are number of gaps that are not part of original [`openjdk`](https://hub.docker.com/_/openjdk/) docker image.

## Issues fixed

- `libgconf-2-4`: Jenkins complains: `/root/.m2/repository/webdriver/chromedriver/linux64/2.34/chromedriver: error while loading shared libraries: libgconf-2.so.4: cannot open shared object file: No such file or directory`
