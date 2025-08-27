# AWS Multi-Region Disaster Recovery (Seoul ↔ Osaka)

## 프로젝트 개요
서울 리전을 **Primary**, 오사카 리전을 **DR(Disaster Recovery)** 리전으로 설정하여  
장애 발생 시 자동으로 대처 가능한 멀티 리전 아키텍처를 **Terraform 기반 IaC**로 구축한 프로젝트입니다.  

실제 장애 시나리오를 가정하여 RTO와 RPO를 측정하고 이를 **Test Report**에 기록했으며,  
그 결과를 바탕으로 **Runbook**을 제작하여 재해 발생 시 관리자가 따라야 할 대응 절차를 문서화했습니다.  

---

## 아키텍처 개요
- **네트워크**: Primary/DR 리전 각각 VPC, Subnet, Route Table 구성 (NAT Gateway 미사용).  

- **스토리지**: Primary/DR 리전별 S3 버킷을 생성하고 **Multi-Region Access Point(MRAP)** 을 구성.  
  Cross-Region Replication(CRR)로 데이터를 동기화하며, CloudFront의 Origin으로 활용.  

- **콘텐츠 전송**: **CloudFront Distribution**을 MRAP과 연동해 정적 콘텐츠를 글로벌 캐싱 및 전송.  

- **로드 밸런서/트래픽 전환**: 서울·오사카 리전에 ALB를 이중 배치하고,  
  **Global Accelerator 헬스체크** 기반 Active–Passive Failover을 구성해 정상 시에는 Primary가 트래픽을 처리하고,  
  장애 발생 시 DR 리전으로 자동 전환.  

- **컴퓨팅**: 리전별 **EC2 Auto Scaling Group + Launch Template**으로 애플리케이션 서버 운영.  
  트래픽 변화 및 장애 발생 상황에서도 무중단 복구 시나리오 검증.  

- **데이터베이스**: **RDS MySQL**을 Writer(Seoul) – Reader(Osaka) 구조로 운영.  
  장애 시 Reader를 Writer로 승격하여 서비스 연속성 유지.  

- **IAM & 보안**: EC2 Auto Scaling Group이 S3, CloudWatch, SSM에 접근할 수 있도록 **IAM Role & Instance Profile**을 구성.  
  최소 권한 정책(Least Privilege)을 적용해 보안을 강화하고, SSM Session Manager를 통해 안전하게 운영.  

---

## Repository 구조
terraform_dr_stack_FINAL/
├── main.tf
├── providers.tf
├── variables.tf
├── outputs.tf
└── modules/
├── network/
├── compute_primary/
├── compute_dr/
├── s3_mrap_attach/
├── cloudfront_mrap_api/
├── iam/
└── ssm/

