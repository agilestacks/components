#!/usr/bin/env groovy

@Grab(group = 'com.amazonaws', module = 'aws-java-sdk', version = '1.11.119')
import com.amazonaws.services.ecr.AmazonECRClientBuilder
import com.amazonaws.services.ecr.model.GetAuthorizationTokenRequest
import com.amazonaws.auth.InstanceProfileCredentialsProvider
import com.amazonaws.regions.Regions

def call(params = [:], Closure body) {
    def region = params?.region ?: Regions.currentRegion.name

    def token = AmazonECRClientBuilder.
            standard().
            withCredentials(InstanceProfileCredentialsProvider.getInstance()).
            withRegion(region).
            build().
            getAuthorizationToken(new GetAuthorizationTokenRequest())
    def auth = token.authorizationData[0]
    def login = new String(auth.authorizationToken.decodeBase64()).tokenize(':')

    def returnStatus = sh(script: "docker login -u ${login[0]} -p ${login[1]} ${auth.proxyEndpoint}",
                          returnStatus:true)

    if (returnStatus != 0) {
      error "I was not able to login to ECR {auth.proxyEndpoint}"
    }

    if (body != null) {
      try {
        body()
      } catch(Exception e) {
        error e
      }
    }
}
