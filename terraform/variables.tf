variable "DOMAIN_NAME" {
  description = "Fuji App domain name."
  type    = string
}

variable "SERVICE_DB_NAME" {
    description = "The name of the service database."
    type        = string
}

variable "SERVICE_DB_LOGIN" {
  description = "The login username for the service database."
  type        = string
  sensitive = true
}

variable "SERVICE_DB_PASSWORD" {
  description = "The password for the service database."
  type        = string
  sensitive = true
}

variable "JWT_SECRET" {
    description = "The secret key used for JWT authentication."
    type        = string
    sensitive = true
}

variable "GOOGLE_CLIENT_ID" {
    description = "The Google Client ID for OAuth authentication."
    type        = string
    sensitive = true
}

variable "OPENAI_API_KEY" {
    description = "The API key for accessing OpenAI services."
    type        = string
    sensitive = true
}
