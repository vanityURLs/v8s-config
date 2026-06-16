variable "cloudflare_account_id" {
  description = "Cloudflare account ID that owns the zone and Zero Trust team."
  type        = string
  default     = "48aa42c6cec6d260e6f97abf3d8cdc6b"

  validation {
    condition     = can(regex("^[a-f0-9]{32}$", var.cloudflare_account_id))
    error_message = "cloudflare_account_id must be a 32-character Cloudflare account ID."
  }
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for the short-link domain."
  type        = string
  default     = "60fc561443676fe33f3c195b766a3418"

  validation {
    condition     = can(regex("^[a-f0-9]{32}$", var.cloudflare_zone_id))
    error_message = "cloudflare_zone_id must be a 32-character Cloudflare zone ID."
  }
}

variable "apex_hostname" {
  description = "Short-link apex hostname, such as v8s.link."
  type        = string
  default     = "v8s.link"

  validation {
    condition     = var.apex_hostname == lower(var.apex_hostname) && can(regex("^[a-z0-9.-]+$", var.apex_hostname))
    error_message = "apex_hostname must be a lowercase hostname."
  }
}

variable "worker_name" {
  description = "Worker or application label used for the Access application name."
  type        = string
  default     = "v8s-link"

  validation {
    condition     = length(var.worker_name) > 0
    error_message = "worker_name must not be empty."
  }
}

variable "maintainer_emails" {
  description = "Email addresses allowed to open protected vanityURLs paths."
  type        = list(string)

  validation {
    condition     = length(var.maintainer_emails) > 0 && alltrue([for email in var.maintainer_emails : can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", email))])
    error_message = "maintainer_emails must contain at least one valid email address."
  }
}

variable "enable_ai_crawler_block_rule" {
  description = "Whether to create the optional static user-agent AI crawler fallback rule. Prefer Cloudflare AI Crawl Control for default crawler blocking."
  type        = bool
  default     = false
}
