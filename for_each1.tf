data "google_project" "project" {}


variable "service_accounts" {
  default = {
      "gke-sa" = {
          description = "GKE service account"
          roles       = [
            "logging.logWriter",
            "monitoring.metricWriter", 
            "monitoring.viewer", 
            "stackdriver.resourceMetadata.writer",
            "storage.objectViewer"
          ]
      }
      "kfp-sa" = {
        description = "KFP service account" 
        roles       = [
          "storage.admin", 
          "bigquery.admin", 
          "automl.admin", 
          "automl.predictor",
          "ml.admin",
          "dataflow.admin"
        ]
      }
    }
}


# Create a list of service account email to role tokens
locals {
  email_to_role = flatten([ 
    for account_name, account_properties in var.service_accounts: [
        for role in account_properties.roles: 
         "${account_name}@${data.google_project.project.project_id}.iam.gserviceaccount.com~roles/${role}"  
      ]
    ]) 
}

# Create service accounts
resource "google_service_account" "service_accounts" {
    for_each = var.service_accounts
    account_id = each.key 
    display_name = each.value.description
}

# Create role bindings
resource "google_project_iam_member" "role_binding" {
  for_each = toset(local.email_to_role)
  role   = split("~", each.value)[1] 
  member =  "serviceAccount:${split("~", each.value)[0]}"

  depends_on = [google_service_account.service_accounts]
}
