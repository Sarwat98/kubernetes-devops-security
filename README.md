# Kubernetes DevOps & Security – DevSecOps Project

This repository contains my final implementation for the **"DevSecOps - Kubernetes DevOps & Security"** course, with additional security scenarios and improvements I applied beyond the original content.

## 📌 Project Overview
The goal of this project is to integrate **security into every stage of the DevOps pipeline** while working with Kubernetes.  
I implemented a complete CI/CD workflow that scans, tests, and securely deploys an application to a Kubernetes cluster, then monitors it for vulnerabilities.

---

## 🚀 Features & Implementation Steps

### 1️⃣ Application Build & Deployment
- Built and tested application locally.
- Created Docker images and pushed them to a registry.
- Securely deployed to a Kubernetes cluster.

### 2️⃣ Secrets Management
- Integrated **HashiCorp Vault** for secret management.
- Injected secrets into Kubernetes pods securely.

### 3️⃣ Vulnerability Scanning & Fixing
- **Dependency-Check**: Found vulnerabilities in application dependencies.
- **SonarQube (SAST)**: Detected insecure code patterns.
- **Trivy / Grype**: Scanned Docker images for vulnerabilities.
- **Kube-score / Kubesec**: Analyzed Kubernetes manifests.
- **Fixes Applied**:
  - Updated vulnerable dependencies.
  - Secured Dockerfiles.
  - Hardened Kubernetes manifests.
  - Re-scanned to confirm **0 critical vulnerabilities**.
  - All unit & integration tests passed after fixes.

### 4️⃣ Security Testing
- **Unit Tests** – verified application functions.
- **Mutation Testing** – ensured test coverage quality.
- **SAST** – scanned code for security issues.
- **DAST (OWASP ZAP)** – scanned running app for vulnerabilities.
- **Integration Tests** – validated app behavior post-deployment.

### 5️⃣ Monitoring & Alerts
- Configured **Prometheus & Grafana** for performance & health metrics.
- Integrated **Falco** for Kubernetes runtime security monitoring.
- Set up **Slack notifications** for pipeline events and cluster alerts.

### 6️⃣ Additional Security Scenarios (Custom Additions)
- **Privileged Access Pod** – tested Kubernetes misconfigurations allowing elevated privileges.
- **Exposed Redis Port** – simulated a Redis misconfiguration accessible to attackers.
- Applied mitigation steps and re-verified security posture.

---

## 📂 Repository Structure

---

