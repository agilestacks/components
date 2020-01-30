# AWS SageMaker Pipeline

Automating the build and deployment of machine learning models is an important step in creating production machine learning services. Models need to be retrained and deployed when code and/or data are updated. This project provides a full implementation of a CI/CD workflow and includes jupyter notebooks showing how to create, launch, stop, and track the progress of builds using python and Amazon Alexa! The goal of aws-sagemaker-build is to provide a repository of common and useful SageMaker/Step Function pipelines, to be shared with the community and grown by the community.

This automated pipeline is based on [AWS SageMaker Build project](https://github.com/aws-samples/aws-sagemaker-build)

For detailed documentation please read [Automated and continuous deployment of Amazon SageMaker models with AWS Step Functions](https://aws.amazon.com/blogs/machine-learning/automated-and-continuous-deployment-of-amazon-sagemaker-models-with-aws-step-functions/) by John Calhoun

# Frameworks
aws-sagemaker-build supports four different configurations: Bring-Your-Own-Docker (BYOD), Amazon SageMaker algorithms, TensorFlow, and MXNet. The configuration is set as a parameter of the CloudFormation template but can be changed after deployment. For the TensorFlow and MXNet configurations the user scripts are copied and saved with version names so that roll backs or redeployment of old versions works correctly. The notebook that is launched in the aws-sagemaker-build stack has examples of each different configuration.

The following architecture diagram shows how all services of SageMaker pipeline work together:

![architecture diagram](https://d2908q01vomqb2.cloudfront.net/f1f836cb4ea6efb2a0b1b99f41ad8b103eff4b59/2018/10/10/continuous-sagemaker-deployment-2.gif)
