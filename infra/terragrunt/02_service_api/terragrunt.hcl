include {
  path = "${find_in_parent_folders()}"
}

dependencies {
  paths = ["../01_ecs_cluster", "../01_rds_cluster"]
}

terraform {
  source = "../../terraform/modules/service_api"
}

inputs = {
  API_DOCKER_IMAGE_NAME = "louptheronlth/tezos-link"
  API_DOCKER_IMAGE_VERSION = "${get_env("TF_VAR_DOCKER_IMAGE_VERSION", "proxy-api")}"
  API_DESIRED_COUNT = 1

  API_CONFIGURATION_FILE = "local"

  API_PORT = 8000
  API_CPU = 256
  API_MEMORY = 512

  DATABASE_PASSWORD = "${get_env("TF_VAR_DATABASE_PASSWORD", "xxxx")}"
}