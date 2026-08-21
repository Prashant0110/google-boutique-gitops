locals {
  vault_services = {
    paymentservice = {
      service_account = "paymentservice"
      secret_path     = "paymentservice/config"
      policy_name     = "paymentservice-policy"
      role_name       = "paymentservice"
    }

    cartservice = {
      service_account = "cartservice"
      secret_path     = "cartservice/config"
      policy_name     = "cartservice-policy"
      role_name       = "cartservice"
    }

    checkoutservice = {
      service_account = "checkoutservice"
      secret_path     = "checkoutservice/config"
      policy_name     = "checkoutservice-policy"
      role_name       = "checkoutservice"
    }

    currencyservice = {
      service_account = "currencyservice"
      secret_path     = "currencyservice/config"
      policy_name     = "currencyservice-policy"
      role_name       = "currencyservice"
    }

    emailservice = {
      service_account = "emailservice"
      secret_path     = "emailservice/config"
      policy_name     = "emailservice-policy"
      role_name       = "emailservice"
    }

    frontend = {
      service_account = "frontend"
      secret_path     = "frontend/config"
      policy_name     = "frontend-policy"
      role_name       = "frontend"
    }

    productcatalogservice = {
      service_account = "productcatalogservice"
      secret_path     = "productcatalogservice/config"
      policy_name     = "productcatalogservice-policy"
      role_name       = "productcatalogservice"
    }

    recommendationservice = {
      service_account = "recommendationservice"
      secret_path     = "recommendationservice/config"
      policy_name     = "recommendationservice-policy"
      role_name       = "recommendationservice"
    }

    shippingservice = {
      service_account = "shippingservice"
      secret_path     = "shippingservice/config"
      policy_name     = "shippingservice-policy"
      role_name       = "shippingservice"
    }
  }
}

module "vault" {
  source = "../../modules/vault"

  namespace = "ecommerce-prod"

  services = local.vault_services

  database = {
    enabled           = false
    mount_path        = "database"
    connection_name   = "rds-mysql"
    address           = ""
    port              = 3306
    database_name     = ""
    admin_username    = ""
    admin_password    = ""
    dynamic_role_name = "paymentservice-db"
    default_ttl       = 3600
    max_ttl           = 7200

    creation_statements = [
      "CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';",
      "GRANT SELECT, INSERT, UPDATE, DELETE ON boutique.* TO '{{name}}'@'%';"
    ]
  }
}