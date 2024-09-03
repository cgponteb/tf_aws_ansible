output "jenkins_master_public_ip" {
  value = aws_instance.jenkins_master.public_ip
}

output "jenkins_workers_public_ips" {
  value = {
    for instance in aws_instance.jenkins_worker_oregon :
    instance.id => instance.public_ip
  }
}

output "lb_dns_name" {
  value = aws_lb.application_lb.dns_name
}

output "url" {
  value = aws_route53_record.jenkins.fqdn
}