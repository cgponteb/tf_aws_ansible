# Create ACM certificate and requests validation via DNS(Route53)
resource "aws_acm_certificate" "jenkins_lb_https" {
  provider          = aws.region_master
  domain_name       = join(".", ["jenkins", data.aws_route53_zone.dns.name])
  validation_method = "DNS"

  tags = {
    Name = "Jenkins-ACM"
  }
}

# Validate ACM issued certificate via Route53
resource "aws_acm_certificate_validation" "cert" {
  provider                = aws.region_master
  certificate_arn         = aws_acm_certificate.jenkins_lb_https.arn
  for_each                = aws_route53_record.cert_validation
  validation_record_fqdns = [aws_route53_record.cert_validation[each.key].fqdn]
}