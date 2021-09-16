# IaC Pod - ado-terraform-pipeline

CI/CD Pipeline as Code (in YAML) deploys Azure resources using Terraform.

## Getting Started

1. Preparing Your Dev Ops Environment

    1. Add the required Terraform Dev Ops Plugin

        [Microsoft Terraform Plugin](https://marketplace.visualstudio.com/items?itemName=ms-devlabs.custom-terraform-tasks)

    2. Create a Service Connection

        [Creating a Service Connection](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints?view=azure-devops&tabs=yaml#create-a-service-connection)

    3. Create a Repository or Use an Existing One

        [Creating a Repository](https://docs.microsoft.com/en-us/azure/devops/repos/git/create-new-repo?view=azure-devops)

2. Preparing Your Workstation and Visual Studio Code

    1. Install Visual Studio Code

        [Visual Studo Code Setup](https://code.visualstudio.com/docs/setup/setup-overview)

    2. Install Git for Windows

        [Git for Windows](https://code.visualstudio.com/Docs/editor/versioncontrol#_git-support)

3. Import Pipeline

    [Importing an Exisitng Pipeline](https://docs.microsoft.com/en-us/azure/devops/pipelines/?view=azure-devops)

    1. From the dashboard, select Pipelines then Builds
    2. Click on New pipeline
    3. Select Existing Azure Pipelines YAML File
    4. Select the Repo containing the uploaded files
    5. From the path dropdown, select /ado-pipeline/azure-pipelines.yml and press Continue
    6. Review your pipeline and update the variable serviceConnectionName with a valid Service Connection (REQUIRED)

        ```yml
        variables:
            serviceConnectionName:
                'iac-lab'
        ```

    7. from the Run dropdown, select Save

4. Adding and Removing Environments.

    Please see steps 5 and 6 for instructions on how to prepare your pipeline variable file and Terraform directories.

    * Environments in the context of the Pipeline work to achieve:

        * Environment selection for deployments
        * Naming of Pipeline runs and Artifacts
        * State file storage location
        * Pipeline Variable File Reference
        * Terraform Folder Reference
        * Deployment Approvals

    Adding/Removing an Environment

    1. Open ado-pipeline/azure-pipelines.yml
    2. Find environment in the parameters section

        ```yml
        - name: 
            environment
            displayName: 
            Environment
            type:
            string
            values:
            - example
        ```

    3. Add or Remove and Environment in the Values

        ```yml
        - name: 
            environment
            displayName: 
            Environment
            type:
            string
            values:
            - example
            - production
        ```

5. Preparing Pipeline Variable Files

    Each Environment created in the pipeline requires a variable file (.yml) that matches the name of the Environment added. Create pipeline variable files in ado-pipeline/variables. Copy the example below and update the variables for the Environment Name, Service Connection Name, Terraform Version and Azure Storage Account Information.

    Note: All file names are case sensitive and you should avoid using any spaces or special characters.

    The example below shows a typical YAML variable file to control Environment Properties. In the below example, a .tfvars file is referenced (by variables) in the terraform/variables/example/example.tfvars.

    If tfvars are not being used and each Environment uses it's own folder with its own Terraform files, uncomment the variable terraformSubDirectory. The pipeline will look for Terraform files in /terraform/example. You do not need to update or remove the pipeline reference to a tfvars file. If tfvars are not being used, the pipeline will create a blank one.

    ```yml
        variables:
        # -----------------------------------------------------------------#
        # --                   Pipeline Variables                       -- #
        # -----------------------------------------------------------------#
        # -- Variables used throughout the pipeline
        # -- Note: Variable names and files are case sensitive
        # --       In YAML files, indentation matters
        # -----------------------------------------------------------------#
        # --                  Environment Variables                     -- #
        # -----------------------------------------------------------------#
        # -- The name of the environment
            environmentName: 'example'                               
        # -- Dev Ops Service Connection Name
            serviceConnectionName: 'iac-lab' 

        # -----------------------------------------------------------------#
        # --                  Azure Storage Account                     -- #
        # -----------------------------------------------------------------#
        # Variables for the Azure Storage Account (tfState File Storage)
        # -- Azure Storage Account Resource Group Name
            azureStorageAccountRgName: 'iaclab-dev-tfstate-rg'
        # -- Azure Storage Account Region
            azureStorageAccountRegion: 'eastus'
        # -- Azure Storage Account Name (Must be unique in Azure globally)
            azureStorageAccountName: 'tfstatedevelopment'
        # -- Container Name
            azureStorageAccountContainerName: 'tfstatefiles'

        # -----------------------------------------------------------------#
        # --                    Terraform Settings                      -- #
        # -----------------------------------------------------------------#
        # -- TFVars File Name
            tfvarFileName: $[ format('{0}', variables['environmentName']) ]
        # -- Terraform Plan Name
        # -- Default is environmentName.plan
            terraformPlanName: $[ format('{0}.plan', variables['environmentName']) ]
        # -- Terraform State File Name
            terraformStateFileName: 'terraform.tfstate'
        # -- Terraform Subdirectory -- (optional)
        # -- Sub directory acts as Terraform working Directory
        # -- Comment out the variable below to use the terraform directory as the working directory
        # -- Uncomment out the variable below to use terraform/environtmentName as the working directory
        #  terraformSubDirectory: $[ format('{0}', variables['environmentName']) ]
        # -- Terraform Varialbe File (tfvars) -- Path relative to the working Terraform Directory
        # -- If this file doesn't exist a blank one will be created by the pipeline during the Plan Stage
        # -- This is relative to your terraform working directory
            terraformVariableFile: $[ format('{0}/{1}/{2}', variables['terraformRootDirectory'], variables['environmentName'], variables[tfvarFileName]) ]

        # -----------------------------------------------------------------#
        # --                     STATIC VARIABLES                       -- #
        # --      DO NOT CHANGE -- DO NOT CHANGE -- DO NOT CHANGE       -- #
        # -----------------------------------------------------------------# 
        # - Instead of YAML conditions using format()
        # - Any blank / null values will be removed from the string
            terraformTfVars:              #< -- DO NOT CHANGE
                $[ format('-var-file=./{0}', variables['terraformVariableFile']) ]
            terraformRootDirectory:       #< -- DO NOT CHANGE
                '$(build.artifactstagingdirectory)/build/src/terraform'
            terraformWorkingDirectory:    #< -- DO NOT CHANGE
                $[ format('{0}/{1}', variables['terraformRootDirectory'], variables['terraformSubDirectory']) ]
            terraformOutFile:             #< -- DO NOT CHANGE
                $[ format('-out {0}', variables['terraformPlanName']) ]
            terraformCommandOptions:      #< -- DO NOT CHANGE
                $[ format('{0} {1}', variables['terraformOutFile'], variables['terraformTfVars']) ]
        # -----------------------------------------------------------------#
        # --      DO NOT CHANGE -- DO NOT CHANGE -- DO NOT CHANGE       -- #
        # --                     STATIC VARIABLES                       -- #
        # -----------------------------------------------------------------# 
    ```

6. Preparing Terraform Files and Folders

    1. Create the required folders in the /src/ directory.

    2. Add Terraform files to the new directory.

        Example repo structure using tfvars.

        ```zsh
            /ado-pipeline/
            |-- /templates/
            |-- |-- az-tf-storageaccount.ps1
            |-- |-- az-tf-storageaccount.yml
            |-- /variables/
            |-- |-- example.yml
            |-- azure-pipelines.yml
            /src/
            |-- /terraform/
            |-- |-- /variables/
            |-- |-- |-- /example/
            |-- |-- |-- |-- example.tfvars
            |-- configuration.tf
            |-- main.tf
            |-- variables.tf
            REAMDME.md
        ```

        Example repo structure without tfvars.

        ```zsh
            /ado-pipeline/
            |-- /templates/
            |-- |-- az-tf-storageaccount.ps1
            |-- |-- az-tf-storageaccount.yml
            |-- /variables/
            |-- |-- example.yml
            |-- azure-pipelines.yml
            /src/
            |-- /terraform/
            |-- |-- /example/
            |-- |-- |-- configuration.tf
            |-- |-- |-- main.tf
            |-- |-- |-- variables.tf
            REAMDME.md
        ```

    3. Create a configuration.tf or add configuration to your main.tf. Below is an example of an Azure backend.

        ```terraform
            ############################################
            #          Terraform Configuration         #
            ############################################
            terraform {
                required_providers {
                    azurerm = {
                        source = "hashicorp/azurerm"
                    }
                    random = {
                        source = "hashicorp/random"
                    }
                }
                    required_version = ">=0.15.1"
                    backend "azurerm" {}
            }

            ############################################
            #                Providers                 #
            ############################################
            provider "azurerm" {
                features {}
            }

            provider "random" {
            }
        ```

7. Running the Pipeline

    [Running a Pipeline in DevOps](https://docs.microsoft.com/en-us/azure/devops/pipelines/?view=azure-devops)

    1. From the dashboard, select Pipelines then Builds
    2. In the tabs click All and select the pipeline
    3. Click New Run
    4. Select the Enviroment you created
        * Note: To run Terraform Plan only, leave Apply Changes unchecked.
    5. Click Run

## Pipeline Stages in Detail

1. todo

## How to Contribute

Please use the below naming conventions when creating branches:

* Bugfix Tracking
  * bugfix/name-of-bug
* Feature Tracking
  * feature/name-of-feature
* Documentation Tracking
  * docs/name-of-readme

Create a Pull Request to have your code reviewed.

If you have any questions, please reach out to mwiacpod@avanade.com
