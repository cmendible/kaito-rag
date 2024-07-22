output "public_key" {
  description = "The public key generated for the SSH key pair."
  value     = azapi_resource_action.ssh_public_key_gen.output.publicKey
  sensitive = true
}
