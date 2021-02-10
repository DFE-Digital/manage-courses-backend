#PaaS
cf_space                   = "bat-prod"
paas_app_environment       = "sandbox"
paas_web_app_host_name     = "sandbox"
paas_web_app_instances     = 2
paas_web_app_memory        = 512
paas_worker_app_instances  = 2
paas_worker_app_memory     = 512
paas_postgres_service_plan = "small-11"
paas_redis_service_plan    = "micro-5_x"

# KeyVault
key_vault_name              = "s121p01-shared-kv-01"
key_vault_resource_group    = "s121p01-shared-rg"
key_vault_app_secret_name   = "TTAPI-APP-SECRETS-SANDBOX"
key_vault_infra_secret_name = "BAT-INFRA-SECRETS-SANDBOX"

#StatusCake
statuscake_alerts = {
  ttapi-sandbox = {
    website_name   = "teacher-training-api-sandbox"
    website_url    = "https://sandbox.api.publish-teacher-training-courses.service.gov.uk/ping"
    test_type      = "HTTP"
    check_rate     = 60
    contact_group  = [151103]
    trigger_rate   = 0
    node_locations = ["UKINT", "UK1", "MAN1", "MAN5", "DUB2"]
  }
}