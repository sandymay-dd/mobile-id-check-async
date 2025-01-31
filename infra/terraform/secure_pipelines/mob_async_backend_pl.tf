resource "aws_cloudformation_stack" "mob_async_backend_pl" {
  name = "mob-async-backend-pl"

  template_url = format(local.preformat_template_url,
    "sam-deploy-pipeline",             # https://github.com/govuk-one-login/devplatform-deploy/tree/main/sam-deploy-pipeline
    "T6TI2U6b_eZjNorsTP6sDXGa4zfdOKAL" # v2.68.1
  )

  // Default parameters. Can be overwritten by using the locals below.
  parameters = merge(
    {
      Environment  = var.environment
      SAMStackName = "mob-async-backend"

      VpcStackName                     = "devplatform-vpc"
      CustomKmsKeyArns                 = "arn:aws:kms:eu-west-2:216552277552:key/4bc58ab5-c9bb-4702-a2c3-5d339604a8fe" # To support Dynatrace
      AdditionalCodeSigningVersionArns = "arn:aws:signer:eu-west-2:216552277552:/signing-profiles/DynatraceSigner/5uwzCCGTPq"

      BuildNotificationStackName = "devplatform-build-notifications"
      SlackNotificationType      = "All"
    },
    local.mob_async_backend_pl[var.environment]
  )

  capabilities = ["CAPABILITY_NAMED_IAM"]
}

locals {
  // Define environment specific parameters here. Will be merged and take precedence over the
  // parameters defined in the resource above.
  // https://developer.hashicorp.com/terraform/language/functions/merge
  // https://developer.hashicorp.com/terraform/language/functions/one
  mob_async_backend_pl = {
    dev = {
      AllowedServiceOne                         = "EC2"
      AllowedServiceTwo                         = "SQS"
      AllowedServiceThree                       = "DynamoDB"
      ContainerSignerKmsKeyArn                  = one(data.aws_cloudformation_stack.container_signer_dev[*].outputs["ContainerSignerKmsKeyArn"])
      IncludePromotion                          = "No"
      OneLoginRepositoryName                    = "mobile-id-check-async"
      ProgrammaticPermissionsBoundary           = "True"
      RequireTestContainerSignatureValidation   = "Yes"
      RunTestContainerInVPC                     = "True"
      SigningProfileArn                         = one(data.aws_cloudformation_stack.signer_dev[*].outputs["SigningProfileArn"])
      SigningProfileVersionArn                  = one(data.aws_cloudformation_stack.signer_dev[*].outputs["SigningProfileVersionArn"])
      TestImageRepositoryUri                    = one(aws_cloudformation_stack.mob_async_backend_tir[*].outputs["TestRunnerImageEcrRepositoryUri"])
    }

    build = {
      AllowedAccounts                           = local.account_vars.staging.account_id
      AllowedServiceOne                         = "EC2"
      AllowedServiceTwo                         = "SQS"
      AllowedServiceThree                       = "DynamoDB"
      ContainerSignerKmsKeyArn                  = one(data.aws_cloudformation_stack.container_signer_build[*].outputs["ContainerSignerKmsKeyArn"])
      IncludePromotion                          = "Yes"
      OneLoginRepositoryName                    = "mobile-id-check-async"
      ProgrammaticPermissionsBoundary           = "True"
      RequireTestContainerSignatureValidation   = "Yes"
      RunTestContainerInVPC                     = "True"
      SigningProfileArn                         = one(data.aws_cloudformation_stack.signer_build[*].outputs["SigningProfileArn"])
      SigningProfileVersionArn                  = one(data.aws_cloudformation_stack.signer_build[*].outputs["SigningProfileVersionArn"])
      TestImageRepositoryUri                    = one(aws_cloudformation_stack.mob_async_backend_tir[*].outputs["TestRunnerImageEcrRepositoryUri"])
    }

    staging = {
      ArtifactSourceBucketArn                 = one(data.aws_cloudformation_stack.mob_async_backend_pl_build[*].outputs["ArtifactPromotionBucketArn"])
      ArtifactSourceBucketEventTriggerRoleArn = one(data.aws_cloudformation_stack.mob_async_backend_pl_build[*].outputs["ArtifactPromotionBucketEventTriggerRoleArn"])
      AllowedAccounts  = null # join(",", [local.account_vars.integration.account_id, local.account_vars.production.account_id])  # Stopping promotion at staging

      IncludePromotion = "No" # "Yes"  # Stopping promotion at staging

      SigningProfileArn        = one(data.aws_cloudformation_stack.signer_build[*].outputs["SigningProfileArn"])
      SigningProfileVersionArn = one(data.aws_cloudformation_stack.signer_build[*].outputs["SigningProfileVersionArn"])
      
    }

    integration = {
      ArtifactSourceBucketArn                 = one(data.aws_cloudformation_stack.mob_async_backend_pl_staging[*].outputs["ArtifactPromotionBucketArn"])
      ArtifactSourceBucketEventTriggerRoleArn = one(data.aws_cloudformation_stack.mob_async_backend_pl_staging[*].outputs["ArtifactPromotionBucketEventTriggerRoleArn"])

      IncludePromotion = "No"

      SigningProfileArn        = one(data.aws_cloudformation_stack.signer_build[*].outputs["SigningProfileArn"])
      SigningProfileVersionArn = one(data.aws_cloudformation_stack.signer_build[*].outputs["SigningProfileVersionArn"])
    }

    production = {
      ArtifactSourceBucketArn                 = one(data.aws_cloudformation_stack.mob_async_backend_pl_staging[*].outputs["ArtifactPromotionBucketArn"])
      ArtifactSourceBucketEventTriggerRoleArn = one(data.aws_cloudformation_stack.mob_async_backend_pl_staging[*].outputs["ArtifactPromotionBucketEventTriggerRoleArn"])

      IncludePromotion = "No"

      SigningProfileArn        = one(data.aws_cloudformation_stack.signer_build[*].outputs["SigningProfileArn"])
      SigningProfileVersionArn = one(data.aws_cloudformation_stack.signer_build[*].outputs["SigningProfileVersionArn"])
    }
  }
}
