output "endpoint" {
  description = "The Kaito inference endpoint for the deployed model."
  value       = "http://${kubernetes_ingress_v1.kaito_ai_model_inference_endpoint_ingress.status.0.load_balancer.0.ingress.0.ip}/chat"
  sensitive   = true
}
